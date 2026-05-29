import 'dart:async';

import 'package:cat_litter_protocol/cat_litter_protocol.dart';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

/// Advertises this device as a Cat Litter Box master on the local network so
/// clients and the companion can find it without the user typing an IP.
class MdnsAdvertiser {
  MdnsAdvertiser._();
  static final MdnsAdvertiser instance = MdnsAdvertiser._();

  Registration? _reg;

  Future<void> start({
    required int port,
    required String deviceId,
    bool tls = false,
  }) async {
    await stop();
    try {
      final service = Service(
        name: 'Cat Litter Master',
        type: '$mdnsServiceType.',
        port: port,
        txt: {
          MdnsTxt.proto: _toBytes('$protocolVersion'),
          MdnsTxt.deviceId: _toBytes(deviceId),
          MdnsTxt.tls: _toBytes(tls ? '1' : '0'),
        },
      );
      _reg = await register(service);
    } catch (e, st) {
      debugPrint('[mDNS] register failed: $e\n$st');
    }
  }

  Future<void> stop() async {
    final reg = _reg;
    _reg = null;
    if (reg == null) return;
    try {
      await unregister(reg);
    } catch (_) {}
  }
}

/// One master that has been found on the LAN.
class DiscoveredMaster {
  const DiscoveredMaster({
    required this.name,
    required this.host,
    required this.port,
    required this.deviceId,
    required this.tls,
  });

  final String name;
  final String host;
  final int port;

  /// Master's deviceId from the TXT record (may be empty if absent).
  final String deviceId;

  /// True iff the master advertised TLS support.
  final bool tls;
}

/// One-shot LAN scan. Returns whatever masters answered within [duration].
class MdnsScanner {
  /// Scan the LAN for `_catlitter._tcp` advertisements. Results are
  /// deduplicated by deviceId where available, otherwise by name.
  static Future<List<DiscoveredMaster>> scan({
    Duration duration = const Duration(seconds: 4),
  }) async {
    final found = <String, DiscoveredMaster>{};
    Discovery? discovery;
    try {
      discovery = await startDiscovery('$mdnsServiceType.');
      void onChange() {
        for (final svc in discovery!.services) {
          _addResolved(svc, found);
        }
      }
      discovery.addServiceListener((_, _) => onChange());
      // Initial scrape in case results arrived before the listener attached.
      onChange();
      await Future<void>.delayed(duration);
      // Resolve any service that hasn't surfaced host info yet.
      for (final svc in discovery.services) {
        if (svc.host == null || svc.port == null) {
          try {
            final resolved = await resolve(svc);
            _addResolved(resolved, found);
          } catch (_) {}
        }
      }
    } catch (e, st) {
      debugPrint('[mDNS] scan failed: $e\n$st');
    } finally {
      if (discovery != null) {
        try {
          await stopDiscovery(discovery);
        } catch (_) {}
      }
    }
    return found.values.toList();
  }

  static void _addResolved(
    Service svc,
    Map<String, DiscoveredMaster> sink,
  ) {
    final host = svc.host;
    final port = svc.port;
    if (host == null || port == null) return;
    final txt = svc.txt ?? const <String, Uint8List?>{};
    final deviceId = _fromBytes(txt[MdnsTxt.deviceId]);
    final tls = _fromBytes(txt[MdnsTxt.tls]) == '1';
    final key = deviceId.isNotEmpty ? deviceId : (svc.name ?? '$host:$port');
    sink[key] = DiscoveredMaster(
      name: svc.name ?? 'Cat Litter Master',
      host: host,
      port: port,
      deviceId: deviceId,
      tls: tls,
    );
  }
}

Uint8List _toBytes(String s) => Uint8List.fromList(s.codeUnits);
String _fromBytes(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) return '';
  return String.fromCharCodes(bytes);
}
