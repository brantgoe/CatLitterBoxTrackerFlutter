import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// A no-op handler. The foreground service's only purpose here is to keep the
/// app process alive so the HTTP+WebSocket server running in the main isolate
/// is not killed when the tablet is backgrounded. We don't run any background
/// work in this isolate — server, repository, and outbox all stay in the
/// main isolate.
@pragma('vm:entry-point')
void masterForegroundEntry() {
  FlutterForegroundTask.setTaskHandler(_NoopHandler());
}

class _NoopHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

class MasterForegroundService {
  MasterForegroundService._();
  static final MasterForegroundService instance = MasterForegroundService._();

  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'master_server',
        channelName: 'Litter Box master server',
        channelDescription:
            'Keeps the master server running so other devices can sync.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }

  Future<void> start({required String hostAndPort, required int clients}) async {
    await _ensureInit();
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Master server running',
        notificationText: '$hostAndPort • $clients client(s)',
      );
      return;
    }
    final result = await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.dataSync],
      serviceId: 4421,
      notificationTitle: 'Master server running',
      notificationText: '$hostAndPort • $clients client(s)',
      callback: masterForegroundEntry,
    );
    if (result is ServiceRequestFailure) {
      debugPrint(
          '[MasterForegroundService] start failed: ${result.error}');
    }
  }

  Future<void> stop() async {
    await _ensureInit();
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> updateClientCount({
    required String hostAndPort,
    required int clients,
  }) async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Master server running',
      notificationText: '$hostAndPort • $clients client(s)',
    );
  }
}
