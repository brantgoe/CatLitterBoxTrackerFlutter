import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/database.dart';
import '../data/repository.dart';
import 'sync_applier.dart';
import 'sync_protocol.dart';

enum ClientState { disconnected, connecting, connected, error }

class SyncClient {
  SyncClient({
    required this.db,
    required this.repository,
    required this.deviceId,
    required this.host,
    required this.port,
    required this.accessToken,
  }) : _applier = SyncApplier(db);

  final AppDatabase db;
  final Repository repository;
  final String deviceId;
  final String host;
  final int port;
  final String accessToken;

  final SyncApplier _applier;
  WebSocketChannel? _channel;
  StreamSubscription<void>? _outboxSub;
  Timer? _reconnectTimer;
  bool _draining = false;
  int _reconnectAttempts = 0;
  bool _stopped = false;

  final ValueNotifier<ClientState> state = ValueNotifier(ClientState.disconnected);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  /// Fires with the snapshot summary every time the master replaces local state.
  /// Consumers (e.g. UI) can subscribe to surface a "data replaced" toast.
  final ValueNotifier<SyncOverview?> lastSnapshot = ValueNotifier(null);

  Future<void> start() async {
    _stopped = false;
    await _connect();
  }

  Future<void> stop() async {
    _stopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _outboxSub?.cancel();
    _outboxSub = null;
    await _channel?.sink.close();
    _channel = null;
    state.value = ClientState.disconnected;
  }

  Future<void> _connect() async {
    if (_stopped) return;
    state.value = ClientState.connecting;
    errorMessage.value = null;
    try {
      final uri = Uri.parse('ws://$host:$port/ws');
      final socket = await WebSocket.connect(uri.toString())
          .timeout(const Duration(seconds: 5));
      _channel = IOWebSocketChannel(socket);

      _channel!.sink.add(jsonEncode(SyncMessages.hello(
        deviceId: deviceId,
        accessToken: accessToken.isEmpty ? null : accessToken,
      )));

      _outboxSub = repository.outboxWakeup.listen((_) => _drainOutbox());
      // Pick up any rows queued before this connection started.
      unawaited(_drainOutbox());

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (Object e) {
          errorMessage.value = e.toString();
          _onDisconnected();
        },
        cancelOnError: true,
      );

      state.value = ClientState.connected;
      _reconnectAttempts = 0;
    } catch (e) {
      errorMessage.value = e.toString();
      state.value = ClientState.error;
      _scheduleReconnect();
    }
  }

  void _onDisconnected() {
    state.value = ClientState.disconnected;
    _outboxSub?.cancel();
    _outboxSub = null;
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _reconnectAttempts++;
    final delaySec = (1 << _reconnectAttempts.clamp(0, 5)).clamp(1, 30);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySec), _connect);
  }

  Future<void> _onMessage(dynamic message) async {
    try {
      final m = jsonDecode(message as String) as Map<String, dynamic>;
      final type = m['type'] as String?;
      switch (type) {
        case MsgType.welcome:
          // Nothing to do for now; could capture serverTime for clock skew.
          break;
        case MsgType.reject:
          errorMessage.value =
              'Master rejected: ${m['reason'] ?? 'unknown'}';
          await stop(); // do not auto-reconnect on auth failure
          break;
        case MsgType.snapshot:
          await _applier.applySnapshot(m);
          lastSnapshot.value = SyncOverview(
            rooms: (m['rooms'] as List).length,
            boxes: (m['boxes'] as List).length,
            events: (m['events'] as List).length,
            tasks: (m['tasks'] as List).length,
          );
          break;
        case MsgType.upsert:
          final kind = EntityKindCodec.parse(m['entity'] as String);
          final data = m['data'] as Map<String, dynamic>;
          await _applier.applyUpsert(kind, data);
          break;
        case MsgType.delete:
          final kind = EntityKindCodec.parse(m['entity'] as String);
          final syncId = m['syncId'] as String;
          await _applier.applyDelete(kind, syncId);
          break;
        case MsgType.ping:
          _channel?.sink.add(jsonEncode({'type': MsgType.pong}));
          break;
      }
    } catch (e, st) {
      debugPrint('[SyncClient] message error: $e\n$st');
    }
  }

  Future<void> _drainOutbox() async {
    if (_draining) return;
    final channel = _channel;
    if (channel == null) return;
    _draining = true;
    try {
      while (true) {
        if (_channel == null) break;
        final batch = await repository.drainOutbox(limit: 64);
        if (batch.isEmpty) break;
        for (final ev in batch) {
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
          try {
            channel.sink.add(jsonEncode(msg));
            await repository.ackOutbox(ev.rowId);
          } catch (e) {
            debugPrint('[SyncClient] send error: $e');
            // Leave the row in the outbox; will retry on next reconnect.
            return;
          }
        }
      }
    } finally {
      _draining = false;
    }
  }
}
