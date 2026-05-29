import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/database.dart';
import '../data/repository.dart';
import 'sync_applier.dart';
import 'sync_protocol.dart';

class _ConnectedClient {
  _ConnectedClient(this.deviceId, this.channel);
  final String deviceId;
  final WebSocketChannel channel;
}

class SyncServer {
  SyncServer({
    required this.db,
    required this.repository,
    required this.deviceId,
    required this.port,
    required this.accessToken,
  }) : _applier = SyncApplier(db);

  final AppDatabase db;
  final Repository repository;
  final String deviceId;
  final int port;
  final String accessToken;

  final SyncApplier _applier;
  HttpServer? _httpServer;
  final List<_ConnectedClient> _clients = [];
  StreamSubscription<OutboxEvent>? _outboxSub;

  final ValueNotifier<int> connectedClients = ValueNotifier(0);

  Future<void> start() async {
    if (_httpServer != null) return;
    final router = Router()
      ..get('/health', _health)
      ..get('/ws', webSocketHandler(_onWebSocket));

    final handler = const Pipeline()
        .addMiddleware(logRequests(logger: _silentLogger))
        .addHandler(router.call);

    _httpServer = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      port,
    );

    _outboxSub = repository.outbox.listen(_broadcastOutbox);
  }

  static void _silentLogger(String _, bool _) {}

  Future<void> stop() async {
    await _outboxSub?.cancel();
    _outboxSub = null;
    for (final c in List.of(_clients)) {
      await c.channel.sink.close();
    }
    _clients.clear();
    connectedClients.value = 0;
    await _httpServer?.close(force: true);
    _httpServer = null;
  }

  Response _health(Request request) {
    return Response.ok(jsonEncode({
      'service': 'cat_litter_box_tracker',
      'role': 'master',
      'deviceId': deviceId,
      'clients': _clients.length,
      'protocol': protocolVersion,
    }), headers: {'content-type': 'application/json'});
  }

  Future<void> _onWebSocket(WebSocketChannel channel, String? _) async {
    String? clientDeviceId;
    final client = _ConnectedClient('pending', channel);
    _clients.add(client);
    connectedClients.value = _clients.length;

    channel.stream.listen(
      (message) async {
        try {
          final m = jsonDecode(message as String) as Map<String, dynamic>;
          final type = m['type'] as String?;
          if (type == MsgType.hello) {
            clientDeviceId = m['deviceId'] as String? ?? 'unknown';
            // Verify access token. Empty server-side token disables auth
            // (kept for legacy installs that pre-dated the feature).
            if (accessToken.isNotEmpty) {
              final claimed = m['accessToken'] as String? ?? '';
              if (claimed != accessToken) {
                channel.sink.add(jsonEncode(
                    SyncMessages.reject(reason: 'invalid_access_token')));
                await channel.sink.close();
                _clients.removeWhere((c) => identical(c.channel, channel));
                connectedClients.value = _clients.length;
                return;
              }
            }
            // Re-key the client.
            _clients.remove(client);
            final identified = _ConnectedClient(clientDeviceId!, channel);
            _clients.add(identified);
            channel.sink.add(jsonEncode(SyncMessages.welcome(
              serverTime: DateTime.now().millisecondsSinceEpoch,
              masterDeviceId: deviceId,
            )));
            await _sendSnapshotTo(channel);
          } else if (type == MsgType.upsert) {
            final kind = EntityKindCodec.parse(m['entity'] as String);
            final data = m['data'] as Map<String, dynamic>;
            final changed = await _applier.applyUpsert(kind, data);
            if (changed) {
              // Broadcast to all clients except origin.
              final origin = m['originDeviceId'] as String?;
              _broadcastRaw(jsonEncode(m), exceptDeviceId: origin);
            }
          } else if (type == MsgType.delete) {
            final kind = EntityKindCodec.parse(m['entity'] as String);
            final syncId = m['syncId'] as String;
            await _applier.applyDelete(kind, syncId);
            final origin = m['originDeviceId'] as String?;
            _broadcastRaw(jsonEncode(m), exceptDeviceId: origin);
          } else if (type == MsgType.ping) {
            channel.sink.add(jsonEncode({'type': MsgType.pong}));
          }
        } catch (e, st) {
          debugPrint('[SyncServer] message error: $e\n$st');
        }
      },
      onDone: () {
        _clients.removeWhere((c) => identical(c.channel, channel));
        connectedClients.value = _clients.length;
      },
      onError: (Object e) {
        debugPrint('[SyncServer] ws error: $e');
        _clients.removeWhere((c) => identical(c.channel, channel));
        connectedClients.value = _clients.length;
      },
      cancelOnError: true,
    );
  }

  Future<void> _sendSnapshotTo(WebSocketChannel channel) async {
    final rooms = await db.allRoomsOnce();
    final boxes = await db.allBoxesOnce();
    final events = await db.allEventsOnce();
    final tasks = await db.allTasksOnce();
    final roomSyncById = {for (final r in rooms) r.id: r.syncId};
    final boxSyncById = {for (final b in boxes) b.id: b.syncId};
    final msg = SyncMessages.snapshot(
      rooms: rooms.map(WireConverter.fromRoom).toList(),
      boxes: boxes
          .map((b) => WireConverter.fromBox(b,
              roomSyncId: b.roomId == null ? null : roomSyncById[b.roomId]))
          .toList(),
      events: events
          .map((e) => WireConverter.fromEvent(e,
              boxSyncId: boxSyncById[e.boxId] ?? ''))
          .where((e) => e.boxSyncId.isNotEmpty)
          .toList(),
      tasks: tasks
          .map((t) => WireConverter.fromTask(t,
              boxSyncId: boxSyncById[t.boxId] ?? ''))
          .where((t) => t.boxSyncId.isNotEmpty)
          .toList(),
    );
    channel.sink.add(jsonEncode(msg));
  }

  void _broadcastOutbox(OutboxEvent ev) {
    Map<String, dynamic> msg;
    if (ev.op == OutboxOp.upsert) {
      msg = {
        'type': MsgType.upsert,
        'entity': ev.kind.wire,
        'originDeviceId': deviceId,
        'data': ev.payload!,
      };
    } else {
      msg = SyncMessages.delete(
        kind: ev.kind,
        syncId: ev.syncId,
        originDeviceId: deviceId,
      );
    }
    _broadcastRaw(jsonEncode(msg));
  }

  void _broadcastRaw(String encoded, {String? exceptDeviceId}) {
    for (final c in List.of(_clients)) {
      if (exceptDeviceId != null && c.deviceId == exceptDeviceId) continue;
      try {
        c.channel.sink.add(encoded);
      } catch (_) {
        // Ignore; closed channels are cleaned up via onDone/onError.
      }
    }
  }
}
