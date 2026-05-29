import 'package:cat_litter_box_tracker/data/database.dart';
import 'package:cat_litter_box_tracker/network/sync_applier.dart';
import 'package:cat_litter_box_tracker/network/sync_protocol.dart';
import 'package:cat_litter_protocol/cat_litter_protocol.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build an isolated AppDatabase backed by an in-memory sqlite for one test.
/// onCreate seeds an "Unnamed Room" + "Litter Box"; the helper wipes those
/// rows so each test starts from a deterministic empty state.
Future<AppDatabase> _memDb() async {
  final db = AppDatabase.withExecutor(NativeDatabase.memory());
  await db.allRoomsOnce();
  await db.transaction(() async {
    await db.delete(db.cleaningEvents).go();
    await db.delete(db.maintenanceTasks).go();
    await db.delete(db.litterBoxes).go();
    await db.delete(db.rooms).go();
  });
  return db;
}

void main() {
  group('SyncApplier', () {
    test('snapshot replaces local state', () async {
      final db = await _memDb();
      addTearDown(db.close);
      final applier = SyncApplier(db);

      const room = WireRoom(syncId: 'r-1', name: 'Den', updatedAt: 1);
      const box = WireBox(
        syncId: 'b-1',
        roomSyncId: 'r-1',
        name: 'Front',
        position: 0,
        type: 'AUTOMATIC',
        warnThresholdHours: 12,
        overdueThresholdHours: 36,
        brand: '',
        model: '',
        updatedAt: 1,
      );
      await applier.applySnapshot({
        'rooms': [WireCodec.roomToJson(room)],
        'boxes': [WireCodec.boxToJson(box)],
        'events': const <Map<String, dynamic>>[],
        'tasks': const <Map<String, dynamic>>[],
      });
      final rooms = await db.allRoomsOnce();
      final boxes = await db.allBoxesOnce();
      expect(rooms.length, 1);
      expect(rooms.first.name, 'Den');
      expect(rooms.first.syncId, 'r-1');
      expect(boxes.length, 1);
      expect(boxes.first.roomId, rooms.first.id);
    });

    test('LWW rejects older update', () async {
      final db = await _memDb();
      addTearDown(db.close);
      final applier = SyncApplier(db);

      const newer = WireRoom(syncId: 'r-1', name: 'Newer', updatedAt: 10);
      const older = WireRoom(syncId: 'r-1', name: 'Older', updatedAt: 5);

      await applier.applyRoom(newer);
      final changed = await applier.applyRoom(older);
      expect(changed, isFalse);
      final fromDb = await db.roomBySyncId('r-1');
      expect(fromDb!.name, 'Newer');
    });

    test('FK resolution: box references room by syncId', () async {
      final db = await _memDb();
      addTearDown(db.close);
      final applier = SyncApplier(db);

      const room = WireRoom(syncId: 'room-x', name: 'X', updatedAt: 1);
      const box = WireBox(
        syncId: 'box-x',
        roomSyncId: 'room-x',
        name: 'XBox',
        position: 0,
        type: 'MANUAL_SCOOP',
        warnThresholdHours: 24,
        overdueThresholdHours: 48,
        brand: '',
        model: '',
        updatedAt: 1,
      );
      await applier.applyRoom(room);
      await applier.applyBox(box);

      final roomRow = await db.roomBySyncId('room-x');
      final boxRow = await db.boxBySyncId('box-x');
      expect(roomRow, isNotNull);
      expect(boxRow, isNotNull);
      expect(boxRow!.roomId, roomRow!.id);
    });

    test('event without parent box is silently dropped', () async {
      final db = await _memDb();
      addTearDown(db.close);
      final applier = SyncApplier(db);

      const orphan = WireEvent(
        syncId: 'e-1',
        boxSyncId: 'missing-box',
        timestamp: 100,
        dueToSmell: null,
        updatedAt: 1,
      );
      final ok = await applier.applyEvent(orphan);
      expect(ok, isFalse);
      final got = await db.eventBySyncId('e-1');
      expect(got, isNull);
    });

    test('applyDelete removes the entity by syncId', () async {
      final db = await _memDb();
      addTearDown(db.close);
      final applier = SyncApplier(db);

      const room = WireRoom(syncId: 'r-del', name: 'Doomed', updatedAt: 1);
      await applier.applyRoom(room);
      expect(await db.roomBySyncId('r-del'), isNotNull);
      await applier.applyDelete(EntityKind.room, 'r-del');
      expect(await db.roomBySyncId('r-del'), isNull);
    });

    test('localOverview counts each entity', () async {
      final db = await _memDb();
      addTearDown(db.close);
      final applier = SyncApplier(db);

      await applier.applyRoom(
          const WireRoom(syncId: 'r1', name: 'R1', updatedAt: 1));
      await applier.applyBox(const WireBox(
        syncId: 'b1',
        roomSyncId: 'r1',
        name: 'B1',
        position: 0,
        type: 'MANUAL_SCOOP',
        warnThresholdHours: 24,
        overdueThresholdHours: 48,
        brand: '',
        model: '',
        updatedAt: 1,
      ));
      final overview = await applier.localOverview();
      expect(overview.rooms, 1);
      expect(overview.boxes, 1);
      expect(overview.events, 0);
      expect(overview.tasks, 0);
    });
  });
}
