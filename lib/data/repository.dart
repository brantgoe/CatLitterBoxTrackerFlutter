import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';

enum MaintenanceSortMode { upNext, byTask }

class Repository {
  Repository(this.db, this._prefs) {
    final stored = _prefs.getInt(_kActiveRoomId);
    if (stored != null && stored > 0) _activeRoomId.value = stored;
    final sort = _prefs.getString(_kMaintenanceSort);
    if (sort != null) {
      _sortMode.value = MaintenanceSortMode.values.firstWhere(
        (m) => m.name == sort,
        orElse: () => MaintenanceSortMode.upNext,
      );
    }
  }

  static const _kActiveRoomId = 'active_room_id';
  static const _kMaintenanceSort = 'maintenance_sort_mode';

  final AppDatabase db;
  final SharedPreferences _prefs;

  final ValueNotifier<int?> _activeRoomId = ValueNotifier<int?>(null);
  ValueListenable<int?> get activeRoomId => _activeRoomId;

  final ValueNotifier<MaintenanceSortMode> _sortMode =
      ValueNotifier<MaintenanceSortMode>(MaintenanceSortMode.upNext);
  ValueListenable<MaintenanceSortMode> get sortMode => _sortMode;

  void setActiveRoomId(int? id) {
    if (id == null) {
      _prefs.remove(_kActiveRoomId);
    } else {
      _prefs.setInt(_kActiveRoomId, id);
    }
    _activeRoomId.value = id;
  }

  void setSortMode(MaintenanceSortMode mode) {
    _prefs.setString(_kMaintenanceSort, mode.name);
    _sortMode.value = mode;
  }

  Stream<List<BoxRoom>> observeRooms() => db.observeRooms();

  Stream<BoxRoom?> observeActiveRoom() {
    return Rx.combineLatest2<List<BoxRoom>, int?, BoxRoom?>(
      db.observeRooms(),
      _activeIdStream(),
      (rooms, activeId) {
        if (rooms.isEmpty) return null;
        return rooms.firstWhere(
          (r) => r.id == activeId,
          orElse: () => rooms.first,
        );
      },
    ).distinct();
  }

  Stream<int?> _activeIdStream() {
    final controller = BehaviorSubject<int?>.seeded(_activeRoomId.value);
    void listener() => controller.add(_activeRoomId.value);
    _activeRoomId.addListener(listener);
    controller.onCancel = () => _activeRoomId.removeListener(listener);
    return controller.stream;
  }

  Stream<List<LitterBox>> observeBoxesInRoom(int roomId) =>
      db.observeBoxesInRoom(roomId);

  Stream<List<LitterBox>> observeAllBoxes() => db.observeAllBoxes();

  Stream<CleaningEvent?> observeMostRecent(int boxId) =>
      db.observeMostRecent(boxId);

  Stream<List<CleaningEvent>> observeEventsForBox(int boxId) =>
      db.observeEventsForBox(boxId);

  Stream<int> observeCleaningsSince(int boxId, int since) =>
      db.observeCountSince(boxId, since);

  Stream<List<MaintenanceTask>> observeMaintenanceTasks(int boxId) =>
      db.observeTasksForBox(boxId);

  Future<int> logCleaning(
    int boxId, {
    int? timestamp,
    bool? dueToSmell,
  }) {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    return db.insertEvent(
      CleaningEventsCompanion.insert(
        boxId: boxId,
        timestamp: ts,
        dueToSmell: Value(dueToSmell),
      ),
    );
  }

  Future<List<int>> logCleaningInRoom(
    int roomId, {
    int? timestamp,
    bool? dueToSmell,
  }) async {
    final boxes = await db.boxesInRoom(roomId);
    final ids = <int>[];
    for (final b in boxes) {
      ids.add(await logCleaning(b.id, timestamp: timestamp, dueToSmell: dueToSmell));
    }
    return ids;
  }

  Future<void> setCleaningSmell(int eventId, bool? dueToSmell) async {
    final existing = await db.eventById(eventId);
    if (existing == null) return;
    await db.updateEvent(existing.copyWith(dueToSmell: Value(dueToSmell)));
  }

  Future<void> updateCleaningSmellForRoom(
    List<int> eventIds,
    bool? dueToSmell,
  ) async {
    for (final id in eventIds) {
      await setCleaningSmell(id, dueToSmell);
    }
  }

  Future<int> reinsertCleaning(CleaningEvent event) =>
      db.insertEvent(CleaningEventsCompanion.insert(
        boxId: event.boxId,
        timestamp: event.timestamp,
        dueToSmell: Value(event.dueToSmell),
      ));

  Future<void> deleteCleaning(CleaningEvent event) => db.deleteEvent(event);

  Future<void> deleteCleaningsByIds(List<int> ids) =>
      db.deleteEventsByIds(ids);

  Future<void> updateBox(LitterBox box) => db.updateBox(box);

  Future<int> insertBox(LitterBoxesCompanion box) => db.insertBox(box);

  Future<void> deleteBox(LitterBox box) => db.deleteBox(box);

  Future<BoxRoom> ensureRoomExists() async {
    final first = await db.firstRoomOrNull();
    if (first != null) return first;
    final id = await db.insertRoom('Main');
    return BoxRoom(id: id, name: 'Main');
  }

  Future<LitterBox> ensureBoxExists() async {
    final first = await db.firstBoxOrNull();
    if (first != null) return first;
    final room = await ensureRoomExists();
    final id = await db.insertBox(LitterBoxesCompanion.insert(
      name: 'Litter Box',
      roomId: Value(room.id),
    ));
    return (await db.boxById(id))!;
  }

  Future<void> updateRoom(BoxRoom room) => db.updateRoomEntity(room);

  Future<int> insertRoom(String name) => db.insertRoom(name);

  Future<void> deleteRoom(BoxRoom room) async {
    await db.deleteRoomEntity(room);
    if (_activeRoomId.value == room.id) setActiveRoomId(null);
  }

  Future<int> addMaintenanceTask(MaintenanceTasksCompanion task) async {
    final boxId = task.boxId.value;
    final box = await db.boxById(boxId);
    final roomId = box?.roomId;
    var stagger = 0;
    if (roomId != null) {
      final siblings =
          (await db.boxesInRoom(roomId)).where((b) => b.id != boxId);
      for (final sibling in siblings) {
        final siblingTasks = await db.tasksForBoxOnce(sibling.id);
        final match = siblingTasks.where(
          (t) =>
              t.name.trim().toLowerCase() ==
              task.name.value.trim().toLowerCase(),
        );
        if (match.isNotEmpty && stagger == 0) {
          stagger = task.intervalCleanings.value ~/ 2;
        }
      }
    }
    return db.insertTask(task.copyWith(offsetCleanings: Value(stagger)));
  }

  Future<void> updateMaintenanceTask(MaintenanceTask task) =>
      db.updateTask(task);

  Future<void> deleteMaintenanceTask(MaintenanceTask task) =>
      db.deleteTask(task);

  Future<void> markMaintenanceComplete(int taskId, {int? now}) async {
    final task = await db.taskById(taskId);
    if (task == null) return;
    await db.updateTask(task.copyWith(
      anchorTimestamp: now ?? DateTime.now().millisecondsSinceEpoch,
      offsetCleanings: 0,
    ));
  }

  Future<void> setLastCleaningTimestamp(int boxId, int timestamp) async {
    final existing = await db.mostRecent(boxId);
    if (existing == null) {
      await db.insertEvent(CleaningEventsCompanion.insert(
        boxId: boxId,
        timestamp: timestamp,
      ));
      return;
    }
    final delta = timestamp - existing.timestamp;
    if (delta != 0) await db.shiftTimestamps(boxId, delta);
  }

  Future<int> cleaningsSinceAnchor(int boxId, int anchor) =>
      db.countSinceOnce(boxId, anchor);

  Future<void> forceMaintenanceDueNow(int taskId) async {
    final task = await db.taskById(taskId);
    if (task == null) return;
    final count = await cleaningsSinceAnchor(task.boxId, task.anchorTimestamp);
    await db.updateTask(task.copyWith(
      intervalCleanings: count.clamp(0, 999999),
    ));
  }
}
