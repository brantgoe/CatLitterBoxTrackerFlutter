import '../data/database.dart';
import 'sync_protocol.dart';

/// A summary of what's currently in the local DB or in a pending snapshot.
class SyncOverview {
  const SyncOverview({
    required this.rooms,
    required this.boxes,
    required this.events,
    required this.tasks,
  });

  final int rooms;
  final int boxes;
  final int events;
  final int tasks;

  bool get hasAny => rooms + boxes + events + tasks > 0;

  static const empty = SyncOverview(rooms: 0, boxes: 0, events: 0, tasks: 0);

  static SyncOverview fromSnapshot(Map<String, dynamic> snapshot) =>
      SyncOverview(
        rooms: (snapshot['rooms'] as List).length,
        boxes: (snapshot['boxes'] as List).length,
        events: (snapshot['events'] as List).length,
        tasks: (snapshot['tasks'] as List).length,
      );
}

/// Applies inbound sync messages to a local database with
/// last-write-wins on entity `updatedAt`.
class SyncApplier {
  SyncApplier(this.db);

  final AppDatabase db;

  /// Snapshot the current local DB counts without modifying anything.
  Future<SyncOverview> localOverview() async {
    final rooms = await db.allRoomsOnce();
    final boxes = await db.allBoxesOnce();
    final events = await db.allEventsOnce();
    final tasks = await db.allTasksOnce();
    return SyncOverview(
      rooms: rooms.length,
      boxes: boxes.length,
      events: events.length,
      tasks: tasks.length,
    );
  }

  /// Apply an upsert. Returns true if the local row changed.
  Future<bool> applyUpsert(EntityKind kind, Map<String, dynamic> data) async {
    final id = (data['id'] as num).toInt();
    final remoteUpdatedAt = (data['updatedAt'] as num).toInt();

    switch (kind) {
      case EntityKind.room:
        final existing = await db.roomById(id);
        if (existing != null && existing.updatedAt >= remoteUpdatedAt) {
          return false;
        }
        await db.syncUpsertRoom(EntityCodec.roomCompanion(data));
        return true;
      case EntityKind.box:
        final existing = await db.boxById(id);
        if (existing != null && existing.updatedAt >= remoteUpdatedAt) {
          return false;
        }
        await db.syncUpsertBox(EntityCodec.boxCompanion(data));
        return true;
      case EntityKind.event:
        final existing = await db.eventById(id);
        if (existing != null && existing.updatedAt >= remoteUpdatedAt) {
          return false;
        }
        await db.syncUpsertEvent(EntityCodec.eventCompanion(data));
        return true;
      case EntityKind.task:
        final existing = await db.taskById(id);
        if (existing != null && existing.updatedAt >= remoteUpdatedAt) {
          return false;
        }
        await db.syncUpsertTask(EntityCodec.taskCompanion(data));
        return true;
    }
  }

  Future<void> applyDelete(EntityKind kind, int id) async {
    switch (kind) {
      case EntityKind.room:
        await db.syncDeleteRoom(id);
      case EntityKind.box:
        await db.syncDeleteBox(id);
      case EntityKind.event:
        await db.syncDeleteEvent(id);
      case EntityKind.task:
        await db.syncDeleteTask(id);
    }
  }

  /// Replace local state with the snapshot. Used on initial client connect.
  Future<void> applySnapshot(Map<String, dynamic> snapshot) async {
    await db.transaction(() async {
      // Wipe all rows in dependency order (children first).
      await db.delete(db.cleaningEvents).go();
      await db.delete(db.maintenanceTasks).go();
      await db.delete(db.litterBoxes).go();
      await db.delete(db.rooms).go();

      for (final r in (snapshot['rooms'] as List).cast<Map<String, dynamic>>()) {
        await db.syncUpsertRoom(EntityCodec.roomCompanion(r));
      }
      for (final b in (snapshot['boxes'] as List).cast<Map<String, dynamic>>()) {
        await db.syncUpsertBox(EntityCodec.boxCompanion(b));
      }
      for (final e in (snapshot['events'] as List).cast<Map<String, dynamic>>()) {
        await db.syncUpsertEvent(EntityCodec.eventCompanion(e));
      }
      for (final t in (snapshot['tasks'] as List).cast<Map<String, dynamic>>()) {
        await db.syncUpsertTask(EntityCodec.taskCompanion(t));
      }
    });
  }
}
