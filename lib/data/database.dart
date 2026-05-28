import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

enum BoxTypeKind { manualScoop, automatic }

extension BoxTypeKindStorage on BoxTypeKind {
  String get storage => switch (this) {
        BoxTypeKind.manualScoop => 'MANUAL_SCOOP',
        BoxTypeKind.automatic => 'AUTOMATIC',
      };

  static BoxTypeKind fromStorage(String value) => switch (value) {
        'AUTOMATIC' => BoxTypeKind.automatic,
        _ => BoxTypeKind.manualScoop,
      };
}

@DataClassName('BoxRoom')
class Rooms extends Table {
  @override
  String get tableName => 'rooms';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DataClassName('LitterBox')
class LitterBoxes extends Table {
  @override
  String get tableName => 'litter_boxes';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get type => text().withDefault(const Constant('MANUAL_SCOOP'))();
  IntColumn get warnThresholdHours => integer().withDefault(const Constant(24))();
  IntColumn get overdueThresholdHours => integer().withDefault(const Constant(48))();
  TextColumn get brand => text().withDefault(const Constant(''))();
  TextColumn get model => text().withDefault(const Constant(''))();
  IntColumn get roomId => integer()
      .nullable()
      .references(Rooms, #id, onDelete: KeyAction.setNull)();
}

@DataClassName('CleaningEvent')
class CleaningEvents extends Table {
  @override
  String get tableName => 'cleaning_events';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get boxId =>
      integer().references(LitterBoxes, #id, onDelete: KeyAction.cascade)();
  IntColumn get timestamp => integer()();
  BoolColumn get dueToSmell => boolean().nullable()();
}

@DataClassName('MaintenanceTask')
class MaintenanceTasks extends Table {
  @override
  String get tableName => 'maintenance_tasks';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get boxId =>
      integer().references(LitterBoxes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get intervalCleanings => integer()();
  IntColumn get anchorTimestamp => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get offsetCleanings => integer().withDefault(const Constant(0))();
}

extension LitterBoxX on LitterBox {
  BoxTypeKind get typeKind => BoxTypeKindStorage.fromStorage(type);
}

@DriftDatabase(
  tables: [Rooms, LitterBoxes, CleaningEvents, MaintenanceTasks],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'litter_tracker'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          final roomId = await into(rooms).insert(
            RoomsCompanion.insert(name: 'Unnamed Room'),
          );
          await into(litterBoxes).insert(
            LitterBoxesCompanion.insert(
              name: 'Litter Box',
              roomId: Value(roomId),
            ),
          );
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  // Rooms
  Stream<List<BoxRoom>> observeRooms() =>
      (select(rooms)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Stream<BoxRoom?> observeFirstRoom() =>
      (select(rooms)..orderBy([(t) => OrderingTerm.asc(t.id)])..limit(1))
          .watchSingleOrNull();

  Future<BoxRoom?> firstRoomOrNull() =>
      (select(rooms)..orderBy([(t) => OrderingTerm.asc(t.id)])..limit(1))
          .getSingleOrNull();

  Future<BoxRoom?> roomById(int id) =>
      (select(rooms)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertRoom(String name) =>
      into(rooms).insert(RoomsCompanion.insert(name: name));

  Future<void> updateRoomEntity(BoxRoom room) =>
      update(rooms).replace(room);

  Future<void> deleteRoomEntity(BoxRoom room) =>
      (delete(rooms)..where((t) => t.id.equals(room.id))).go();

  // Boxes
  Stream<List<LitterBox>> observeAllBoxes() => (select(litterBoxes)
        ..orderBy([
          (t) => OrderingTerm.asc(t.position),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .watch();

  Stream<List<LitterBox>> observeBoxesInRoom(int roomId) =>
      (select(litterBoxes)
            ..where((t) => t.roomId.equals(roomId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.position),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  Future<List<LitterBox>> boxesInRoom(int roomId) => (select(litterBoxes)
        ..where((t) => t.roomId.equals(roomId))
        ..orderBy([
          (t) => OrderingTerm.asc(t.position),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .get();

  Future<LitterBox?> boxById(int id) =>
      (select(litterBoxes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<LitterBox?> firstBoxOrNull() => (select(litterBoxes)
        ..orderBy([
          (t) => OrderingTerm.asc(t.position),
          (t) => OrderingTerm.asc(t.id),
        ])
        ..limit(1))
      .getSingleOrNull();

  Future<int> insertBox(LitterBoxesCompanion box) =>
      into(litterBoxes).insert(box);

  Future<void> updateBox(LitterBox box) => update(litterBoxes).replace(box);

  Future<void> deleteBox(LitterBox box) =>
      (delete(litterBoxes)..where((t) => t.id.equals(box.id))).go();

  // Cleaning events
  Stream<List<CleaningEvent>> observeEventsForBox(int boxId) =>
      (select(cleaningEvents)
            ..where((t) => t.boxId.equals(boxId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .watch();

  Stream<CleaningEvent?> observeMostRecent(int boxId) =>
      (select(cleaningEvents)
            ..where((t) => t.boxId.equals(boxId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(1))
          .watchSingleOrNull();

  Future<CleaningEvent?> mostRecent(int boxId) => (select(cleaningEvents)
        ..where((t) => t.boxId.equals(boxId))
        ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
        ..limit(1))
      .getSingleOrNull();

  Stream<int> observeCountSince(int boxId, int since) {
    final q = selectOnly(cleaningEvents)
      ..addColumns([cleaningEvents.id.count()])
      ..where(cleaningEvents.boxId.equals(boxId) &
          cleaningEvents.timestamp.isBiggerThanValue(since));
    return q
        .map((row) => row.read<int>(cleaningEvents.id.count()) ?? 0)
        .watchSingle();
  }

  Future<int> countSinceOnce(int boxId, int since) async {
    final q = selectOnly(cleaningEvents)
      ..addColumns([cleaningEvents.id.count()])
      ..where(cleaningEvents.boxId.equals(boxId) &
          cleaningEvents.timestamp.isBiggerThanValue(since));
    final row = await q.getSingle();
    return row.read<int>(cleaningEvents.id.count()) ?? 0;
  }

  Future<int> insertEvent(CleaningEventsCompanion event) =>
      into(cleaningEvents).insert(event);

  Future<void> updateEvent(CleaningEvent event) =>
      update(cleaningEvents).replace(event);

  Future<CleaningEvent?> eventById(int id) =>
      (select(cleaningEvents)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> deleteEvent(CleaningEvent event) =>
      (delete(cleaningEvents)..where((t) => t.id.equals(event.id))).go();

  Future<void> deleteEventsByIds(List<int> ids) =>
      (delete(cleaningEvents)..where((t) => t.id.isIn(ids))).go();

  Future<void> shiftTimestamps(int boxId, int deltaMs) async {
    await customUpdate(
      'UPDATE cleaning_events SET timestamp = timestamp + ?1 WHERE box_id = ?2',
      variables: [Variable.withInt(deltaMs), Variable.withInt(boxId)],
      updates: {cleaningEvents},
    );
  }

  // Maintenance tasks
  Stream<List<MaintenanceTask>> observeTasksForBox(int boxId) =>
      (select(maintenanceTasks)
            ..where((t) => t.boxId.equals(boxId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<List<MaintenanceTask>> tasksForBoxOnce(int boxId) =>
      (select(maintenanceTasks)
            ..where((t) => t.boxId.equals(boxId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<MaintenanceTask?> taskById(int id) =>
      (select(maintenanceTasks)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertTask(MaintenanceTasksCompanion task) =>
      into(maintenanceTasks).insert(task);

  Future<void> updateTask(MaintenanceTask task) =>
      update(maintenanceTasks).replace(task);

  Future<void> deleteTask(MaintenanceTask task) =>
      (delete(maintenanceTasks)..where((t) => t.id.equals(task.id))).go();
}
