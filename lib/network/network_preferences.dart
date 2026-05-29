import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum DeviceRole { standalone, master, client }

class NetworkConfig {
  const NetworkConfig({
    required this.role,
    required this.masterHost,
    required this.masterPort,
    required this.ownedRoomId,
    required this.deviceId,
  });

  final DeviceRole role;
  final String masterHost;
  final int masterPort;
  final int? ownedRoomId;
  final String deviceId;

  NetworkConfig copyWith({
    DeviceRole? role,
    String? masterHost,
    int? masterPort,
    Object? ownedRoomId = _sentinel,
    String? deviceId,
  }) {
    return NetworkConfig(
      role: role ?? this.role,
      masterHost: masterHost ?? this.masterHost,
      masterPort: masterPort ?? this.masterPort,
      ownedRoomId: identical(ownedRoomId, _sentinel)
          ? this.ownedRoomId
          : ownedRoomId as int?,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

const _sentinel = Object();

class NetworkPreferences {
  NetworkPreferences(this._prefs) {
    _load();
  }

  static const _kRole = 'net_role';
  static const _kMasterHost = 'net_master_host';
  static const _kMasterPort = 'net_master_port';
  static const _kOwnedRoomId = 'net_owned_room_id';
  static const _kDeviceId = 'net_device_id';
  static const defaultPort = 4421;

  final SharedPreferences _prefs;

  final ValueNotifier<NetworkConfig> _config =
      ValueNotifier(_initial());
  ValueListenable<NetworkConfig> get listenable => _config;
  NetworkConfig get value => _config.value;

  static NetworkConfig _initial() => const NetworkConfig(
        role: DeviceRole.standalone,
        masterHost: '',
        masterPort: defaultPort,
        ownedRoomId: null,
        deviceId: '',
      );

  void _load() {
    final role = DeviceRole.values.firstWhere(
      (r) => r.name == _prefs.getString(_kRole),
      orElse: () => DeviceRole.standalone,
    );
    final host = _prefs.getString(_kMasterHost) ?? '';
    final port = _prefs.getInt(_kMasterPort) ?? defaultPort;
    final ownedRoomId = _prefs.getInt(_kOwnedRoomId);
    var deviceId = _prefs.getString(_kDeviceId) ?? '';
    if (deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      _prefs.setString(_kDeviceId, deviceId);
    }
    _config.value = NetworkConfig(
      role: role,
      masterHost: host,
      masterPort: port,
      ownedRoomId: ownedRoomId,
      deviceId: deviceId,
    );
  }

  Future<void> update(NetworkConfig config) async {
    await _prefs.setString(_kRole, config.role.name);
    await _prefs.setString(_kMasterHost, config.masterHost);
    await _prefs.setInt(_kMasterPort, config.masterPort);
    if (config.ownedRoomId == null) {
      await _prefs.remove(_kOwnedRoomId);
    } else {
      await _prefs.setInt(_kOwnedRoomId, config.ownedRoomId!);
    }
    await _prefs.setString(_kDeviceId, config.deviceId);
    _config.value = config;
  }
}
