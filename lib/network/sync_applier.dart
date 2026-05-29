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
}

/// Applies inbound sync messages to a local database with last-write-wins on
/// each entity's `updatedAt`. All cross-device references are by `syncId`;
/// foreign keys are translated to the receiver's local integer ids.
class SyncApplier {
  SyncApplier(this.db);

  final AppDatabase db;

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

  // --- upserts ----------------------------------------------------------

  Future<bool> applyRoom(WireRoom r) async {
    final existing = await db.roomBySyncId(r.syncId);
    if (existing != null && existing.updatedAt >= r.updatedAt) return false;
    await db.syncUpsertRoom(
        WireConverter.toRoomCompanion(r, localId: existing?.id));
    return true;
  }

  Future<bool> applyBox(WireBox b) async {
    final existing = await db.boxBySyncId(b.syncId);
    if (existing != null && existing.updatedAt >= b.updatedAt) return false;
    int? localRoomId;
    if (b.roomSyncId != null) {
      final room = await db.roomBySyncId(b.roomSyncId!);
      localRoomId = room?.id;
    }
    await db.syncUpsertBox(WireConverter.toBoxCompanion(
      b,
      localId: existing?.id,
      localRoomId: localRoomId,
    ));
    return true;
  }

  Future<bool> applyEvent(WireEvent e) async {
    final existing = await db.eventBySyncId(e.syncId);
    if (existing != null && existing.updatedAt >= e.updatedAt) return false;
    final box = await db.boxBySyncId(e.boxSyncId);
    if (box == null) return false; // orphan event; parent box not synced yet.
    await db.syncUpsertEvent(WireConverter.toEventCompanion(
      e,
      localId: existing?.id,
      localBoxId: box.id,
    ));
    return true;
  }

  Future<bool> applyTask(WireTask t) async {
    final existing = await db.taskBySyncId(t.syncId);
    if (existing != null && existing.updatedAt >= t.updatedAt) return false;
    final box = await db.boxBySyncId(t.boxSyncId);
    if (box == null) return false;
    await db.syncUpsertTask(WireConverter.toTaskCompanion(
      t,
      localId: existing?.id,
      localBoxId: box.id,
    ));
    return true;
  }

  /// Generic upsert from a JSON message.
  Future<bool> applyUpsert(EntityKind kind, Map<String, dynamic> data) async {
    return switch (kind) {
      EntityKind.room => applyRoom(WireCodec.roomFromJson(data)),
      EntityKind.box => applyBox(WireCodec.boxFromJson(data)),
      EntityKind.event => applyEvent(WireCodec.eventFromJson(data)),
      EntityKind.task => applyTask(WireCodec.taskFromJson(data)),
    };
  }

  // --- deletes ----------------------------------------------------------

  Future<void> applyDelete(EntityKind kind, String syncId) async {
    switch (kind) {
      case EntityKind.room:
        final r = await db.roomBySyncId(syncId);
        if (r != null) await db.syncDeleteRoom(r.id);
      case EntityKind.box:
        final b = await db.boxBySyncId(syncId);
        if (b != null) await db.syncDeleteBox(b.id);
      case EntityKind.event:
        final e = await db.eventBySyncId(syncId);
        if (e != null) await db.syncDeleteEvent(e.id);
      case EntityKind.task:
        final t = await db.taskBySyncId(syncId);
        if (t != null) await db.syncDeleteTask(t.id);
    }
  }

  // --- snapshot ---------------------------------------------------------

  /// Replace local state with the snapshot. Used on initial client connect.
  Future<void> applySnapshot(Map<String, dynamic> snapshot) async {
    await db.transaction(() async {
      // Wipe all rows in dependency order (children first).
      await db.delete(db.cleaningEvents).go();
      await db.delete(db.maintenanceTasks).go();
      await db.delete(db.litterBoxes).go();
      await db.delete(db.rooms).go();

      // Insert rooms first so child FKs resolve.
      for (final j in (snapshot['rooms'] as List).cast<Map<String, dynamic>>()) {
        await applyRoom(WireCodec.roomFromJson(j));
      }
      for (final j in (snapshot['boxes'] as List).cast<Map<String, dynamic>>()) {
        await applyBox(WireCodec.boxFromJson(j));
      }
      for (final j in (snapshot['events'] as List).cast<Map<String, dynamic>>()) {
        await applyEvent(WireCodec.eventFromJson(j));
      }
      for (final j in (snapshot['tasks'] as List).cast<Map<String, dynamic>>()) {
        await applyTask(WireCodec.taskFromJson(j));
      }
    });
  }
}
