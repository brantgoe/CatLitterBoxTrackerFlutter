// Re-exports from the shared protocol package plus drift-row → wire
// conversions. The wire format itself lives in the shared package so the
// companion app (and any future client) sees an identical definition.

export 'package:cat_litter_protocol/cat_litter_protocol.dart';

import 'package:cat_litter_protocol/cat_litter_protocol.dart';
import 'package:drift/drift.dart' show Value;

import '../data/database.dart';

class WireConverter {
  /// Drift row → wire entity.
  static WireRoom fromRoom(BoxRoom r) => WireRoom(
        syncId: r.syncId,
        name: r.name,
        catCount: r.catCount,
        updatedAt: r.updatedAt,
      );

  /// box: local roomId int → roomSyncId requires a lookup.
  static WireBox fromBox(LitterBox b, {required String? roomSyncId}) =>
      WireBox(
        syncId: b.syncId,
        roomSyncId: roomSyncId,
        name: b.name,
        position: b.position,
        type: b.type,
        warnThresholdHours: b.warnThresholdHours,
        overdueThresholdHours: b.overdueThresholdHours,
        brand: b.brand,
        model: b.model,
        updatedAt: b.updatedAt,
      );

  static WireEvent fromEvent(CleaningEvent e, {required String boxSyncId}) =>
      WireEvent(
        syncId: e.syncId,
        boxSyncId: boxSyncId,
        timestamp: e.timestamp,
        dueToSmell: e.dueToSmell,
        updatedAt: e.updatedAt,
      );

  static WireTask fromTask(MaintenanceTask t, {required String boxSyncId}) =>
      WireTask(
        syncId: t.syncId,
        boxSyncId: boxSyncId,
        name: t.name,
        intervalCleanings: t.intervalCleanings,
        anchorTimestamp: t.anchorTimestamp,
        enabled: t.enabled,
        offsetCleanings: t.offsetCleanings,
        updatedAt: t.updatedAt,
      );

  /// Wire entity → drift companion (insert-or-update).
  /// `localRoomId` is the result of looking up `roomSyncId` locally; null is
  /// acceptable (orphan box).
  static RoomsCompanion toRoomCompanion(WireRoom r, {int? localId}) =>
      RoomsCompanion(
        id: localId == null ? const Value.absent() : Value(localId),
        syncId: Value(r.syncId),
        name: Value(r.name),
        catCount: Value(r.catCount),
        updatedAt: Value(r.updatedAt),
      );

  static LitterBoxesCompanion toBoxCompanion(
    WireBox b, {
    int? localId,
    required int? localRoomId,
  }) =>
      LitterBoxesCompanion(
        id: localId == null ? const Value.absent() : Value(localId),
        syncId: Value(b.syncId),
        name: Value(b.name),
        position: Value(b.position),
        type: Value(b.type),
        warnThresholdHours: Value(b.warnThresholdHours),
        overdueThresholdHours: Value(b.overdueThresholdHours),
        brand: Value(b.brand),
        model: Value(b.model),
        roomId: Value(localRoomId),
        updatedAt: Value(b.updatedAt),
      );

  static CleaningEventsCompanion toEventCompanion(
    WireEvent e, {
    int? localId,
    required int localBoxId,
  }) =>
      CleaningEventsCompanion(
        id: localId == null ? const Value.absent() : Value(localId),
        syncId: Value(e.syncId),
        boxId: Value(localBoxId),
        timestamp: Value(e.timestamp),
        dueToSmell: Value(e.dueToSmell),
        updatedAt: Value(e.updatedAt),
      );

  static MaintenanceTasksCompanion toTaskCompanion(
    WireTask t, {
    int? localId,
    required int localBoxId,
  }) =>
      MaintenanceTasksCompanion(
        id: localId == null ? const Value.absent() : Value(localId),
        syncId: Value(t.syncId),
        boxId: Value(localBoxId),
        name: Value(t.name),
        intervalCleanings: Value(t.intervalCleanings),
        anchorTimestamp: Value(t.anchorTimestamp),
        enabled: Value(t.enabled),
        offsetCleanings: Value(t.offsetCleanings),
        updatedAt: Value(t.updatedAt),
      );
}
