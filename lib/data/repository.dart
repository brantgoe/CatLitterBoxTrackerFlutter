import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/sync_protocol.dart';
import 'database.dart';

enum MaintenanceSortMode { upNext, byTask }

/// A drained outbox row, ready to be broadcast on the wire.
class OutboxEvent {
  const OutboxEvent({
    required this.rowId,
    required this.op,
    required this.kind,
    required this.syncId,
    required this.payload,
  });

  final int rowId;
  final OutboxOp op;
  final EntityKind kind;
  final String syncId;
  final Map<String, dynamic>? payload;

  static OutboxEvent fromRow(OutboxRow r) {
    return OutboxEvent(
      rowId: r.id,
      op: r.op == 'delete' ? OutboxOp.delete : OutboxOp.upsert,
      kind: EntityKindCodec.parse(r.entityKind),
      syncId: r.syncId,
      payload: r.payload == null
          ? null
          : jsonDecode(r.payload!) as Map<String, dynamic>,
    );
  }
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

  /// Wakes up subscribers (the sync engine) when there might be new outbox
  /// rows to drain. Carries no payload — consumers query the outbox table.
  final _outboxWakeup = StreamController<void>.broadcast();
  Stream<void> get outboxWakeup => _outboxWakeup.stream;

  /// Drain all currently-pending outbox rows in insertion order.
  Future<List<OutboxEvent>> drainOutbox({int limit = 200}) async {
    final rows = await db.pendingOutboxRows(limit: limit);
    return rows.map(OutboxEvent.fromRow).toList();
  }

  Future<void> ackOutbox(int rowId) => db.deleteOutboxRow(rowId);

  Future<int> pendingOutboxCount() => db.countOutboxRows();

  void _signal() => _outboxWakeup.add(null);

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

  // --- outbox helpers (run inside the active transaction) ----------------

  Future<void> _enqueueUpsert(EntityKind kind, Map<String, dynamic> json) async {
    await db.insertOutboxRow(SyncOutboxCompanion.insert(
      entityKind: kind.wire,
      op: 'upsert',
      syncId: json['syncId'] as String,
      payload: Value(jsonEncode(json)),
    ));
  }

  Future<void> _enqueueDelete(EntityKind kind, String syncId) async {
    await db.insertOutboxRow(SyncOutboxCompanion.insert(
      entityKind: kind.wire,
      op: 'delete',
      syncId: syncId,
      payload: const Value(null),
    ));
  }

  Future<Map<String, dynamic>?> _roomPayload(int id) async {
    final r = await db.roomById(id);
    if (r == null) return null;
    return WireCodec.roomToJson(WireConverter.fromRoom(r));
  }

  Future<Map<String, dynamic>?> _boxPayload(int id) async {
    final b = await db.boxById(id);
    if (b == null) return null;
    String? roomSyncId;
    if (b.roomId != null) {
      final r = await db.roomById(b.roomId!);
      roomSyncId = r?.syncId;
    }
    return WireCodec.boxToJson(WireConverter.fromBox(b, roomSyncId: roomSyncId));
  }

  Future<Map<String, dynamic>?> _eventPayload(int id) async {
    final e = await db.eventById(id);
    if (e == null) return null;
    final b = await db.boxById(e.boxId);
    if (b == null) return null;
    return WireCodec.eventToJson(
        WireConverter.fromEvent(e, boxSyncId: b.syncId));
  }

  Future<Map<String, dynamic>?> _taskPayload(int id) async {
    final t = await db.taskById(id);
    if (t == null) return null;
    final b = await db.boxById(t.boxId);
    if (b == null) return null;
    return WireCodec.taskToJson(
        WireConverter.fromTask(t, boxSyncId: b.syncId));
  }

  // --- mutations: each one writes to its entity table AND the outbox table
  //     inside a single drift transaction.

  Future<int> logCleaning(
    int boxId, {
    int? timestamp,
    bool? dueToSmell,
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final id = await db.transaction(() async {
      final id = await db.insertEvent(
        CleaningEventsCompanion.insert(
          boxId: boxId,
          timestamp: ts,
          dueToSmell: Value(dueToSmell),
        ),
      );
      final payload = await _eventPayload(id);
      if (payload != null) await _enqueueUpsert(EntityKind.event, payload);
      return id;
    });
    _signal();
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
    await db.transaction(() async {
      await db.updateEvent(existing.copyWith(dueToSmell: Value(dueToSmell)));
      final payload = await _eventPayload(eventId);
      if (payload != null) await _enqueueUpsert(EntityKind.event, payload);
    });
    _signal();
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
    final id = await db.transaction(() async {
      final id = await db.insertEvent(CleaningEventsCompanion.insert(
        boxId: event.boxId,
        timestamp: event.timestamp,
        dueToSmell: Value(event.dueToSmell),
      ));
      final payload = await _eventPayload(id);
      if (payload != null) await _enqueueUpsert(EntityKind.event, payload);
      return id;
    });
    _signal();
    return id;
  }

  Future<void> deleteCleaning(CleaningEvent event) async {
    await db.transaction(() async {
      await db.deleteEvent(event);
      await _enqueueDelete(EntityKind.event, event.syncId);
    });
    _signal();
  }

  Future<void> deleteCleaningsByIds(List<int> ids) async {
    final syncIds = <String>[];
    for (final id in ids) {
      final e = await db.eventById(id);
      if (e != null) syncIds.add(e.syncId);
    }
    await db.transaction(() async {
      await db.deleteEventsByIds(ids);
      for (final syncId in syncIds) {
        await _enqueueDelete(EntityKind.event, syncId);
      }
    });
    _signal();
  }

  Future<void> updateBox(LitterBox box) async {
    await db.transaction(() async {
      await db.updateBox(box);
      final payload = await _boxPayload(box.id);
      if (payload != null) await _enqueueUpsert(EntityKind.box, payload);
    });
    _signal();
  }

  Future<int> insertBox(LitterBoxesCompanion box) async {
    final id = await db.transaction(() async {
      final id = await db.insertBox(box);
      final payload = await _boxPayload(id);
      if (payload != null) await _enqueueUpsert(EntityKind.box, payload);
      return id;
    });
    _signal();
    return id;
  }

  Future<void> deleteBox(LitterBox box) async {
    await db.transaction(() async {
      await db.deleteBox(box);
      await _enqueueDelete(EntityKind.box, box.syncId);
    });
    _signal();
  }

  Future<BoxRoom> ensureRoomExists() async {
    final first = await db.firstRoomOrNull();
    if (first != null) return first;
    final id = await db.transaction(() async {
      final id = await db.insertRoom('Main');
      final payload = await _roomPayload(id);
      if (payload != null) await _enqueueUpsert(EntityKind.room, payload);
      return id;
    });
    _signal();
    return (await db.roomById(id))!;
  }

  Future<LitterBox> ensureBoxExists() async {
    final first = await db.firstBoxOrNull();
    if (first != null) return first;
    final room = await ensureRoomExists();
    final id = await db.transaction(() async {
      final id = await db.insertBox(LitterBoxesCompanion.insert(
        name: 'Litter Box',
        roomId: Value(room.id),
      ));
      final payload = await _boxPayload(id);
      if (payload != null) await _enqueueUpsert(EntityKind.box, payload);
      return id;
    });
    _signal();
    return (await db.boxById(id))!;
  }

  Future<void> updateRoom(BoxRoom room) async {
    await db.transaction(() async {
      await db.updateRoomEntity(room);
      final payload = await _roomPayload(room.id);
      if (payload != null) await _enqueueUpsert(EntityKind.room, payload);
    });
    _signal();
  }

  Future<int> insertRoom(String name) async {
    final id = await db.transaction(() async {
      final id = await db.insertRoom(name);
      final payload = await _roomPayload(id);
      if (payload != null) await _enqueueUpsert(EntityKind.room, payload);
      return id;
    });
    _signal();
    return id;
  }

  Future<void> deleteRoom(BoxRoom room) async {
    await db.transaction(() async {
      await db.deleteRoomEntity(room);
      await _enqueueDelete(EntityKind.room, room.syncId);
    });
    if (_activeRoomId.value == room.id) setActiveRoomId(null);
    _signal();
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
    final id = await db.transaction(() async {
      final id = await db
          .insertTask(task.copyWith(offsetCleanings: Value(stagger)));
      final payload = await _taskPayload(id);
      if (payload != null) await _enqueueUpsert(EntityKind.task, payload);
      return id;
    });
    _signal();
    return id;
  }

  Future<void> updateMaintenanceTask(MaintenanceTask task) async {
    await db.transaction(() async {
      await db.updateTask(task);
      final payload = await _taskPayload(task.id);
      if (payload != null) await _enqueueUpsert(EntityKind.task, payload);
    });
    _signal();
  }

  Future<void> deleteMaintenanceTask(MaintenanceTask task) async {
    await db.transaction(() async {
      await db.deleteTask(task);
      await _enqueueDelete(EntityKind.task, task.syncId);
    });
    _signal();
  }

  Future<void> markMaintenanceComplete(int taskId, {int? now}) async {
    final task = await db.taskById(taskId);
    if (task == null) return;
    await db.transaction(() async {
      await db.updateTask(task.copyWith(
        anchorTimestamp: now ?? DateTime.now().millisecondsSinceEpoch,
        offsetCleanings: 0,
      ));
      final payload = await _taskPayload(taskId);
      if (payload != null) await _enqueueUpsert(EntityKind.task, payload);
    });
    _signal();
  }

  Future<void> setLastCleaningTimestamp(int boxId, int timestamp) async {
    final existing = await db.mostRecent(boxId);
    if (existing == null) {
      await db.transaction(() async {
        final id = await db.insertEvent(CleaningEventsCompanion.insert(
          boxId: boxId,
          timestamp: timestamp,
        ));
        final payload = await _eventPayload(id);
        if (payload != null) await _enqueueUpsert(EntityKind.event, payload);
      });
      _signal();
      return;
    }
    final delta = timestamp - existing.timestamp;
    if (delta != 0) {
      final box = await db.boxById(boxId);
      if (box == null) return;
      await db.transaction(() async {
        await db.shiftTimestamps(boxId, delta);
        final events = await db.observeEventsForBox(boxId).first;
        for (final e in events) {
          final payload = WireCodec.eventToJson(
              WireConverter.fromEvent(e, boxSyncId: box.syncId));
          await _enqueueUpsert(EntityKind.event, payload);
        }
      });
      _signal();
    }
  }

  Future<int> cleaningsSinceAnchor(int boxId, int anchor) =>
      db.countSinceOnce(boxId, anchor);

  Future<void> forceMaintenanceDueNow(int taskId) async {
    final task = await db.taskById(taskId);
    if (task == null) return;
    final count = await cleaningsSinceAnchor(task.boxId, task.anchorTimestamp);
    await db.transaction(() async {
      await db.updateTask(task.copyWith(
        intervalCleanings: count.clamp(0, 999999),
      ));
      final payload = await _taskPayload(taskId);
      if (payload != null) await _enqueueUpsert(EntityKind.task, payload);
    });
    _signal();
  }

  /// Wipe the entire local database. Used when joining a network as a
  /// client; the master's snapshot replaces local state. Also clears the
  /// outbox so a stale change doesn't get sent to the master post-snapshot.
  Future<void> wipeAll() async {
    await db.transaction(() async {
      await db.delete(db.cleaningEvents).go();
      await db.delete(db.maintenanceTasks).go();
      await db.delete(db.litterBoxes).go();
      await db.delete(db.rooms).go();
      await db.delete(db.syncOutbox).go();
    });
    setActiveRoomId(null);
  }
}
