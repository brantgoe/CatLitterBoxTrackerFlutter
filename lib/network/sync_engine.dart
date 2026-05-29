import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/repository.dart';
import 'network_preferences.dart';
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
    try {
      final server = SyncServer(
        db: db,
        repository: repository,
        deviceId: cfg.deviceId,
        port: cfg.masterPort,
      );
      await server.start();
      _server = server;
      server.connectedClients.addListener(() {
        status.value = status.value.copyWith(
          connectedClientCount: server.connectedClients.value,
        );
      });
      status.value = SyncEngineStatus(
        role: cfg.role,
        status: SyncStatus.running,
        detail: 'Listening on :${cfg.masterPort}',
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
    await _server?.stop();
    _server = null;
    await _client?.stop();
    _client = null;
  }
}
