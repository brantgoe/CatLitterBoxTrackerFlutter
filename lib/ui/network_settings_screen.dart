import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../network/network_preferences.dart';
import '../network/sync_applier.dart';
import '../network/sync_client.dart';
import '../network/sync_engine.dart';
import '../state/providers.dart';
import 'theme.dart';

class NetworkSettingsScreen extends ConsumerStatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  ConsumerState<NetworkSettingsScreen> createState() =>
      _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends ConsumerState<NetworkSettingsScreen> {
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  String? _wifiIp;
  SyncOverview? _lastShownSnapshot;
  VoidCallback? _snapshotListener;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(networkConfigProvider);
    _hostCtrl = TextEditingController(text: cfg.masterHost);
    _portCtrl = TextEditingController(text: cfg.masterPort.toString());
    _loadWifiIp();
    _attachSnapshotListener();
  }

  void _attachSnapshotListener() {
    final engine = ref.read(syncEngineProvider);
    _snapshotListener = () {
      final s = engine.lastClientSnapshot.value;
      if (s == null || identical(s, _lastShownSnapshot)) return;
      _lastShownSnapshot = s;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Local data replaced with master snapshot: '
            '${s.rooms} room(s), ${s.boxes} box(es), '
            '${s.events} cleaning(s), ${s.tasks} task(s).',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    };
    engine.lastClientSnapshot.addListener(_snapshotListener!);
  }

  Future<void> _loadWifiIp() async {
    try {
      final ip = await NetworkInfo().getWifiIP();
      if (mounted) setState(() => _wifiIp = ip);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_snapshotListener != null) {
      ref
          .read(syncEngineProvider)
          .lastClientSnapshot
          .removeListener(_snapshotListener!);
    }
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(networkConfigProvider);
    final status = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Networking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(status),
          const SizedBox(height: 16),
          const Text('Role',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<DeviceRole>(
            segments: const [
              ButtonSegment(value: DeviceRole.standalone, label: Text('Standalone')),
              ButtonSegment(value: DeviceRole.master, label: Text('Master')),
              ButtonSegment(value: DeviceRole.client, label: Text('Client')),
            ],
            selected: {cfg.role},
            onSelectionChanged: (s) => _changeRole(s.first),
          ),
          const SizedBox(height: 16),
          if (cfg.role == DeviceRole.master) _masterPanel(cfg, status),
          if (cfg.role == DeviceRole.client) _clientPanel(cfg, status),
          if (cfg.role == DeviceRole.standalone)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Standalone mode. This device keeps its own data and does '
                'not sync with anything else.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          const Divider(height: 32),
          Text('Device ID: ${cfg.deviceId}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _statusCard(SyncEngineStatus s) {
    final (color, label) = _statusBadge(s);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  if (s.detail != null)
                    Text(s.detail!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, String) _statusBadge(SyncEngineStatus s) {
    switch (s.status) {
      case SyncStatus.off:
        return (AppColors.textSecondary, 'Off');
      case SyncStatus.starting:
        return (AppColors.statusWarn, 'Starting…');
      case SyncStatus.running:
        if (s.role == DeviceRole.master) {
          return (
            AppColors.statusOk,
            'Master running — ${s.connectedClientCount ?? 0} client(s) connected'
          );
        }
        if (s.clientState == ClientState.connected) {
          return (AppColors.statusOk, 'Connected to master');
        }
        return (AppColors.statusWarn, 'Connecting…');
      case SyncStatus.error:
        return (AppColors.statusOverdue, 'Error');
    }
  }

  Widget _masterPanel(NetworkConfig cfg, SyncEngineStatus s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This device hosts the server. Other devices connect to it.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (_wifiIp != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tell other devices to connect to:'),
                  const SizedBox(height: 4),
                  Text(
                    '$_wifiIp : ${cfg.masterPort}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Text('Detecting Wi-Fi address…',
              style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        TextField(
          controller: _portCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Port'),
          onSubmitted: (_) => _savePortChange(),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Restart server'),
          onPressed: _restartMaster,
        ),
      ],
    );
  }

  Widget _clientPanel(NetworkConfig cfg, SyncEngineStatus s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This device joins a Master. Switching to client mode will '
          'replace local data with the Master\'s snapshot.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hostCtrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Master IP / hostname',
            hintText: 'e.g. 192.168.1.42',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _portCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Master port'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.link),
          label: const Text('Connect'),
          onPressed: _connectClient,
        ),
      ],
    );
  }

  Future<void> _changeRole(DeviceRole role) async {
    final cfg = ref.read(networkConfigProvider);
    if (role == DeviceRole.client) {
      final overview =
          await ref.read(syncEngineProvider).snapshotLocalOverview();
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Switch to client?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Once this device connects to a master, the master\'s data '
                'will replace whatever is on this tablet.',
              ),
              const SizedBox(height: 12),
              if (overview.hasAny) ...[
                const Text(
                  'This tablet currently holds:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('• ${overview.rooms} room(s)'),
                Text('• ${overview.boxes} box(es)'),
                Text('• ${overview.events} cleaning event(s)'),
                Text('• ${overview.tasks} maintenance task(s)'),
                const SizedBox(height: 8),
                const Text(
                  'All of it will be discarded if anything on the master '
                  'differs. Make sure you have the right master IP first.',
                  style: TextStyle(color: AppColors.statusWarn),
                ),
              ] else
                const Text(
                  'This tablet has no local data, so nothing will be lost.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              const SizedBox(height: 8),
              const Text(
                'If the connection fails, no data is touched.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('CONTINUE')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(networkConfigProvider.notifier).update(cfg.copyWith(role: role));
  }

  Future<void> _savePortChange() async {
    final port = int.tryParse(_portCtrl.text);
    if (port == null) return;
    final cfg = ref.read(networkConfigProvider);
    await ref.read(networkConfigProvider.notifier).update(cfg.copyWith(masterPort: port));
  }

  Future<void> _restartMaster() async {
    final port = int.tryParse(_portCtrl.text) ?? NetworkPreferences.defaultPort;
    final cfg = ref.read(networkConfigProvider);
    final notifier = ref.read(networkConfigProvider.notifier);
    // Force a restart by bouncing to standalone briefly.
    await notifier.update(cfg.copyWith(role: DeviceRole.standalone));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await notifier
        .update(cfg.copyWith(role: DeviceRole.master, masterPort: port));
  }

  Future<void> _connectClient() async {
    final cfg = ref.read(networkConfigProvider);
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text) ?? NetworkPreferences.defaultPort;
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the master IP first')),
      );
      return;
    }
    final notifier = ref.read(networkConfigProvider.notifier);
    await notifier.update(cfg.copyWith(
      role: DeviceRole.standalone,
      masterHost: host,
      masterPort: port,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await notifier.update(cfg.copyWith(
      role: DeviceRole.client,
      masterHost: host,
      masterPort: port,
    ));
  }
}
