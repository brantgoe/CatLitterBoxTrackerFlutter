import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:network_info_plus/network_info_plus.dart';

import '../data/database.dart';
import '../data/repository.dart';
import 'master_foreground_service.dart';
import 'mdns.dart';
import 'network_preferences.dart';
import 'sync_applier.dart';
import 'sync_client.dart';
import 'sync_server.dart';

enum SyncStatus { off, starting, running, error }

class SyncEngineStatus {
  const SyncEngineStatus({
    required this.role,
    required this.status,
    this.detail,
    this.clientState,
    this.connectedClientCount,
  });

  final DeviceRole role;
  final SyncStatus status;
  final String? detail;
  final ClientState? clientState;
  final int? connectedClientCount;

  SyncEngineStatus copyWith({
    DeviceRole? role,
    SyncStatus? status,
    Object? detail = _sentinel,
    Object? clientState = _sentinel,
    Object? connectedClientCount = _sentinel,
  }) {
    return SyncEngineStatus(
      role: role ?? this.role,
      status: status ?? this.status,
      detail: identical(detail, _sentinel) ? this.detail : detail as String?,
      clientState: identical(clientState, _sentinel)
          ? this.clientState
          : clientState as ClientState?,
      connectedClientCount: identical(connectedClientCount, _sentinel)
          ? this.connectedClientCount
          : connectedClientCount as int?,
    );
  }
}

const _sentinel = Object();

class SyncEngine {
  SyncEngine({
    required this.db,
    required this.repository,
    required this.prefs,
  });

  final AppDatabase db;
  final Repository repository;
  final NetworkPreferences prefs;

  SyncServer? _server;
  SyncClient? _client;

  /// Last snapshot summary applied while in client mode. Null until a client
  /// connection successfully receives a snapshot.
  ValueListenable<SyncOverview?> get lastClientSnapshot =>
      _lastSnapshotProxy;
  final ValueNotifier<SyncOverview?> _lastSnapshotProxy =
      ValueNotifier(null);

  Future<SyncOverview> snapshotLocalOverview() =>
      SyncApplier(db).localOverview();

  final ValueNotifier<SyncEngineStatus> status =
      ValueNotifier(const SyncEngineStatus(
    role: DeviceRole.standalone,
    status: SyncStatus.off,
  ));

  VoidCallback? _prefsListener;

  Future<void> start() async {
    _prefsListener = _onPrefsChanged;
    prefs.listenable.addListener(_prefsListener!);
    await _applyConfig();
  }

  Future<void> stop() async {
    if (_prefsListener != null) {
      prefs.listenable.removeListener(_prefsListener!);
      _prefsListener = null;
    }
    await _teardown();
  }

  void _onPrefsChanged() {
    _applyConfig();
  }

  Future<void> _applyConfig() async {
    final cfg = prefs.value;
    await _teardown();
    switch (cfg.role) {
      case DeviceRole.standalone:
        status.value = SyncEngineStatus(
          role: cfg.role,
          status: SyncStatus.off,
        );
      case DeviceRole.master:
        await _startMaster(cfg);
      case DeviceRole.client:
        await _startClient(cfg);
    }
  }

  Future<void> _startMaster(NetworkConfig cfg) async {
    status.value = SyncEngineStatus(role: cfg.role, status: SyncStatus.starting);
    // Auto-generate an access token the first time we become master so the
    // master is never accidentally unauthenticated.
    if (cfg.accessToken.isEmpty) {
      final token = NetworkPreferences.generateToken();
      await prefs.update(cfg.copyWith(accessToken: token));
      return; // _onPrefsChanged will re-fire _applyConfig with the new token.
    }
    try {
      final server = SyncServer(
        db: db,
        repository: repository,
        deviceId: cfg.deviceId,
        port: cfg.masterPort,
        accessToken: cfg.accessToken,
      );
      await server.start();
      _server = server;

      // Resolve the LAN IP for the persistent notification text.
      String hostText = ':${cfg.masterPort}';
      try {
        final ip = await NetworkInfo().getWifiIP();
        if (ip != null && ip.isNotEmpty) hostText = '$ip:${cfg.masterPort}';
      } catch (_) {}

      await MasterForegroundService.instance.start(
        hostAndPort: hostText,
        clients: 0,
      );
      // Advertise the master over mDNS so clients/companion can auto-find it.
      // Fire-and-forget — registration failure shouldn't kill the server.
      unawaited(MdnsAdvertiser.instance.start(
        port: cfg.masterPort,
        deviceId: cfg.deviceId,
      ));

      server.connectedClients.addListener(() {
        final count = server.connectedClients.value;
        status.value = status.value.copyWith(connectedClientCount: count);
        // Keep the persistent notification's client count in sync.
        MasterForegroundService.instance.updateClientCount(
          hostAndPort: hostText,
          clients: count,
        );
      });
      status.value = SyncEngineStatus(
        role: cfg.role,
        status: SyncStatus.running,
        detail: 'Listening on $hostText',
        connectedClientCount: 0,
      );
    } catch (e) {
      status.value = SyncEngineStatus(
        role: cfg.role,
        status: SyncStatus.error,
        detail: e.toString(),
      );
    }
  }

  Future<void> _startClient(NetworkConfig cfg) async {
    if (cfg.masterHost.isEmpty) {
      status.value = SyncEngineStatus(
        role: cfg.role,
        status: SyncStatus.error,
        detail: 'No master host configured',
      );
      return;
    }
    status.value = SyncEngineStatus(role: cfg.role, status: SyncStatus.starting);
    try {
      final client = SyncClient(
        db: db,
        repository: repository,
        deviceId: cfg.deviceId,
        host: cfg.masterHost,
        port: cfg.masterPort,
        accessToken: cfg.accessToken,
      );
      client.state.addListener(() {
        status.value = status.value.copyWith(
          clientState: client.state.value,
          status: client.state.value == ClientState.connected
              ? SyncStatus.running
              : client.state.value == ClientState.error
                  ? SyncStatus.error
                  : SyncStatus.starting,
          detail: client.errorMessage.value,
        );
      });
      client.lastSnapshot.addListener(() {
        _lastSnapshotProxy.value = client.lastSnapshot.value;
      });
      await client.start();
      _client = client;
      status.value = SyncEngineStatus(
        role: cfg.role,
        status: SyncStatus.running,
        detail: 'Connecting to ${cfg.masterHost}:${cfg.masterPort}',
        clientState: client.state.value,
      );
    } catch (e) {
      status.value = SyncEngineStatus(
        role: cfg.role,
        status: SyncStatus.error,
        detail: e.toString(),
      );
    }
  }

  Future<void> _teardown() async {
    if (_server != null) {
      await MasterForegroundService.instance.stop();
      await MdnsAdvertiser.instance.stop();
    }
    await _server?.stop();
    _server = null;
    await _client?.stop();
    _client = null;
    _lastSnapshotProxy.value = null;
  }
}
