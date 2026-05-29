import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/sync_protocol.dart';
import 'database.dart';

enum MaintenanceSortMode { upNext, byTask }

/// An outbox event emitted whenever the local repository mutates the DB.
/// The sync engine subscribes to these and forwards over the wire.
class OutboxEvent {
  OutboxEvent.upsert(this.kind, this.payload)
      : op = OutboxOp.upsert,
        id = null;
  OutboxEvent.delete(this.kind, this.id)
      : op = OutboxOp.delete,
        payload = null;

  final OutboxOp op;
  final EntityKind kind;
  final Map<String, dynamic>? payload;
  final int? id;
}

enum OutboxOp { upsert, delete }

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

  final _outboxController = StreamController<OutboxEvent>.broadcast();
  Stream<OutboxEvent> get outbox => _outboxController.stream;

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
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final id = await db.insertEvent(
      CleaningEventsCompanion.insert(
        boxId: boxId,
        timestamp: ts,
        dueToSmell: Value(dueToSmell),
      ),
    );
    await _emitUpsertEvent(id);
    return id;
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
    await _emitUpsertEvent(eventId);
  }

  Future<void> updateCleaningSmellForRoom(
    List<int> eventIds,
    bool? dueToSmell,
  ) async {
    for (final id in eventIds) {
      await setCleaningSmell(id, dueToSmell);
    }
  }

  Future<int> reinsertCleaning(CleaningEvent event) async {
    final id = await db.insertEvent(CleaningEventsCompanion.insert(
      boxId: event.boxId,
      timestamp: event.timestamp,
      dueToSmell: Value(event.dueToSmell),
    ));
    await _emitUpsertEvent(id);
    return id;
  }

  Future<void> deleteCleaning(CleaningEvent event) async {
    await db.deleteEvent(event);
    _outboxController.add(OutboxEvent.delete(EntityKind.event, event.id));
  }

  Future<void> deleteCleaningsByIds(List<int> ids) async {
    await db.deleteEventsByIds(ids);
    for (final id in ids) {
      _outboxController.add(OutboxEvent.delete(EntityKind.event, id));
    }
  }

  Future<void> updateBox(LitterBox box) async {
    await db.updateBox(box);
    await _emitUpsertBox(box.id);
  }

  Future<int> insertBox(LitterBoxesCompanion box) async {
    final id = await db.insertBox(box);
    await _emitUpsertBox(id);
    return id;
  }

  Future<void> deleteBox(LitterBox box) async {
    await db.deleteBox(box);
    _outboxController.add(OutboxEvent.delete(EntityKind.box, box.id));
  }

  Future<BoxRoom> ensureRoomExists() async {
    final first = await db.firstRoomOrNull();
    if (first != null) return first;
    final id = await db.insertRoom('Main');
    await _emitUpsertRoom(id);
    return (await db.roomById(id))!;
  }

  Future<LitterBox> ensureBoxExists() async {
    final first = await db.firstBoxOrNull();
    if (first != null) return first;
    final room = await ensureRoomExists();
    final id = await db.insertBox(LitterBoxesCompanion.insert(
      name: 'Litter Box',
      roomId: Value(room.id),
    ));
    await _emitUpsertBox(id);
    return (await db.boxById(id))!;
  }

  Future<void> updateRoom(BoxRoom room) async {
    await db.updateRoomEntity(room);
    await _emitUpsertRoom(room.id);
  }

  Future<int> insertRoom(String name) async {
    final id = await db.insertRoom(name);
    await _emitUpsertRoom(id);
    return id;
  }

  Future<void> deleteRoom(BoxRoom room) async {
    await db.deleteRoomEntity(room);
    _outboxController.add(OutboxEvent.delete(EntityKind.room, room.id));
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
    final id =
        await db.insertTask(task.copyWith(offsetCleanings: Value(stagger)));
    await _emitUpsertTask(id);
    return id;
  }

  Future<void> updateMaintenanceTask(MaintenanceTask task) async {
    await db.updateTask(task);
    await _emitUpsertTask(task.id);
  }

  Future<void> deleteMaintenanceTask(MaintenanceTask task) async {
    await db.deleteTask(task);
    _outboxController.add(OutboxEvent.delete(EntityKind.task, task.id));
  }

  Future<void> markMaintenanceComplete(int taskId, {int? now}) async {
    final task = await db.taskById(taskId);
    if (task == null) return;
    await db.updateTask(task.copyWith(
      anchorTimestamp: now ?? DateTime.now().millisecondsSinceEpoch,
      offsetCleanings: 0,
    ));
    await _emitUpsertTask(taskId);
  }

  Future<void> setLastCleaningTimestamp(int boxId, int timestamp) async {
    final existing = await db.mostRecent(boxId);
    if (existing == null) {
      final id = await db.insertEvent(CleaningEventsCompanion.insert(
        boxId: boxId,
        timestamp: timestamp,
      ));
      await _emitUpsertEvent(id);
      return;
    }
    final delta = timestamp - existing.timestamp;
    if (delta != 0) {
      await db.shiftTimestamps(boxId, delta);
      // Re-emit all events for the box since timestamps changed.
      final events = await db.observeEventsForBox(boxId).first;
      for (final e in events) {
        _outboxController.add(
          OutboxEvent.upsert(EntityKind.event, EntityCodec.eventToJson(e)),
        );
      }
    }
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
    await _emitUpsertTask(taskId);
  }

  Future<void> _emitUpsertRoom(int id) async {
    final r = await db.roomById(id);
    if (r != null) {
      _outboxController.add(
          OutboxEvent.upsert(EntityKind.room, EntityCodec.roomToJson(r)));
    }
  }

  Future<void> _emitUpsertBox(int id) async {
    final b = await db.boxById(id);
    if (b != null) {
      _outboxController.add(
          OutboxEvent.upsert(EntityKind.box, EntityCodec.boxToJson(b)));
    }
  }

  Future<void> _emitUpsertEvent(int id) async {
    final e = await db.eventById(id);
    if (e != null) {
      _outboxController.add(
          OutboxEvent.upsert(EntityKind.event, EntityCodec.eventToJson(e)));
    }
  }

  Future<void> _emitUpsertTask(int id) async {
    final t = await db.taskById(id);
    if (t != null) {
      _outboxController.add(
          OutboxEvent.upsert(EntityKind.task, EntityCodec.taskToJson(t)));
    }
  }

  /// Wipe the entire local database. Used when joining a network as a
  /// client; the master's snapshot replaces local state.
  Future<void> wipeAll() async {
    await db.transaction(() async {
      await db.delete(db.cleaningEvents).go();
      await db.delete(db.maintenanceTasks).go();
      await db.delete(db.litterBoxes).go();
      await db.delete(db.rooms).go();
    });
    setActiveRoomId(null);
  }
}
