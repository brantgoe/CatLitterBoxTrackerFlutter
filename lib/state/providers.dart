import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../data/repository.dart';

class MaintenanceItem {
  MaintenanceItem(this.task, this.cleaningsSinceAnchor);

  final MaintenanceTask task;
  final int cleaningsSinceAnchor;

  int get remaining =>
      task.intervalCleanings - cleaningsSinceAnchor - task.offsetCleanings;
  bool get isDueNow => remaining <= 0;
}

class BoxScreenState {
  BoxScreenState({
    required this.box,
    required this.lastCleaning,
    required this.history,
    required this.maintenance,
  });

  final LitterBox box;
  final CleaningEvent? lastCleaning;
  final List<CleaningEvent> history;
  final List<MaintenanceItem> maintenance;
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main() after loading prefs');
});

final repositoryProvider = Provider<Repository>((ref) {
  return Repository(
    ref.watch(databaseProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final roomsProvider = StreamProvider<List<BoxRoom>>((ref) {
  return ref.watch(repositoryProvider).observeRooms();
});

final activeRoomProvider = StreamProvider<BoxRoom?>((ref) {
  return ref.watch(repositoryProvider).observeActiveRoom();
});

class MaintenanceSortNotifier extends Notifier<MaintenanceSortMode> {
  @override
  MaintenanceSortMode build() {
    final repo = ref.watch(repositoryProvider);
    repo.sortMode.addListener(_sync);
    ref.onDispose(() => repo.sortMode.removeListener(_sync));
    return repo.sortMode.value;
  }

  void _sync() {
    state = ref.read(repositoryProvider).sortMode.value;
  }

  void toggle() {
    final repo = ref.read(repositoryProvider);
    final next = state == MaintenanceSortMode.upNext
        ? MaintenanceSortMode.byTask
        : MaintenanceSortMode.upNext;
    repo.setSortMode(next);
  }
}

final maintenanceSortModeProvider =
    NotifierProvider<MaintenanceSortNotifier, MaintenanceSortMode>(
        MaintenanceSortNotifier.new);

/// Box screen states for the currently active room.
final boxStatesProvider = StreamProvider<List<BoxScreenState>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final roomAsync = ref.watch(activeRoomProvider);
  final room = roomAsync.value;
  if (room == null) return Stream.value(const []);
  return repo.observeBoxesInRoom(room.id).switchMap((boxes) {
    if (boxes.isEmpty) return Stream.value(const <BoxScreenState>[]);
    final perBox = boxes.map((box) => _boxStateStream(repo, box));
    return Rx.combineLatestList(perBox);
  });
});

Stream<BoxScreenState> _boxStateStream(Repository repo, LitterBox box) {
  final last = repo.observeMostRecent(box.id);
  final history = repo.observeEventsForBox(box.id);
  final tasks = repo.observeMaintenanceTasks(box.id);
  final maintenance = tasks.switchMap<List<MaintenanceItem>>((list) {
    final enabled = list.where((t) => t.enabled).toList();
    if (enabled.isEmpty) return Stream.value(const []);
    final flows = enabled.map((t) => repo
        .observeCleaningsSince(box.id, t.anchorTimestamp)
        .map((c) => MaintenanceItem(t, c)));
    return Rx.combineLatestList(flows);
  });
  return Rx.combineLatest3<CleaningEvent?, List<CleaningEvent>,
      List<MaintenanceItem>, BoxScreenState>(
    last,
    history,
    maintenance,
    (l, h, m) => BoxScreenState(
      box: box,
      lastCleaning: l,
      history: h,
      maintenance: m,
    ),
  );
}

/// Boxes in the active room (used by Setup/Dev screens).
final boxesInActiveRoomProvider = StreamProvider<List<LitterBox>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final room = ref.watch(activeRoomProvider).value;
  if (room == null) return Stream.value(const []);
  return repo.observeBoxesInRoom(room.id);
});
