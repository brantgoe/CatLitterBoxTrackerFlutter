import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/database.dart';
import '../data/repository.dart';
import 'sync_applier.dart';
import 'sync_protocol.dart';

enum ClientState { disconnected, connecting, connected, error }

/// Result of a single connection attempt. The engine uses these to surface
/// "first time you've connected to this host — saved its fingerprint" or
/// "the host's cert changed — refusing to connect" to the UI.
enum PinDecision {
  /// No saved pin. Accepted whatever cert the host presented and saved its
  /// fingerprint as the new pin.
  trustOnFirstUse,

  /// Saved pin matched the live cert. Normal happy-path connection.
  matched,

  /// Saved pin did NOT match the live cert. Connection was rejected.
  /// The user must either Forget Pin (and verify out-of-band) or restore the
  /// original host.
  mismatch,
}

class SyncClient {
  SyncClient({
    required this.db,
    required this.repository,
    required this.deviceId,
    required this.host,
    required this.port,
    required this.accessToken,
    required this.pinnedFingerprint,
    required this.onPinDecision,
  }) : _applier = SyncApplier(db);

  final AppDatabase db;
  final Repository repository;
  final String deviceId;
  final String host;
  final int port;
  final String accessToken;

  /// Saved pin to compare against. Empty means "no pin yet — TOFU".
  final String pinnedFingerprint;

  /// Called when a connection completes its TLS handshake. The engine uses
  /// the (decision, newFingerprint) tuple to persist the pin or alert the
  /// user about a mismatch.
  final void Function(PinDecision decision, String fingerprint) onPinDecision;

  final SyncApplier _applier;
  WebSocketChannel? _channel;
  StreamSubscription<void>? _outboxSub;
  Timer? _reconnectTimer;
  bool _draining = false;

  /// (master_clock − local_clock) at the moment the welcome arrived.
  /// Outgoing upsert payloads have their `updatedAt` shifted by this amount
  /// so LWW comparisons on the master use the master's notion of "now".
  int _clockSkewMs = 0;
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
      String? seenFp;
      var pinMismatch = false;
      final httpClient = HttpClient(context: SecurityContext(withTrustedRoots: false))
        ..badCertificateCallback = (cert, _, _) {
          final fp = sha256
              .convert(cert.der)
              .bytes
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
          seenFp = fp;
          if (pinnedFingerprint.isEmpty) {
            return true; // TOFU — caller will persist
          }
          if (fp == pinnedFingerprint) return true;
          pinMismatch = true;
          return false;
        };

      final uri = Uri.parse('wss://$host:$port/ws');
      _channel = IOWebSocketChannel.connect(
        uri,
        customClient: httpClient,
        connectTimeout: const Duration(seconds: 6),
      );
      // Force the handshake to actually run so badCertificateCallback fires
      // and we get a real error if the pin doesn't match.
      await _channel!.ready;

      if (pinMismatch) {
        onPinDecision(PinDecision.mismatch, seenFp ?? '');
        errorMessage.value =
            "Host's TLS certificate changed since the last time you "
            "connected. Refusing to connect. If this is expected, tap "
            "Forget pin in network settings and reconnect.";
        await _channel?.sink.close();
        _channel = null;
        state.value = ClientState.error;
        return;
      }
      if (seenFp != null) {
        onPinDecision(
          pinnedFingerprint.isEmpty
              ? PinDecision.trustOnFirstUse
              : PinDecision.matched,
          seenFp!,
        );
      }

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
          final serverTime = (m['serverTime'] as num?)?.toInt();
          if (serverTime != null) {
            _clockSkewMs =
                serverTime - DateTime.now().millisecondsSinceEpoch;
          }
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
            // Shift updatedAt into master time so LWW on the receiving side
            // compares apples to apples regardless of the two devices'
            // wall-clock drift.
            final data = Map<String, dynamic>.from(ev.payload!);
            if (data['updatedAt'] is num) {
              data['updatedAt'] =
                  (data['updatedAt'] as num).toInt() + _clockSkewMs;
            }
            msg = {
              'type': MsgType.upsert,
              'entity': ev.kind.wire,
              'originDeviceId': deviceId,
              'data': data,
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
