import 'package:drift/drift.dart' show Value;

import '../data/database.dart';

/// Wire-format entity kind.
enum EntityKind { room, box, event, task }

extension EntityKindCodec on EntityKind {
  String get wire => name;
  static EntityKind parse(String s) =>
      EntityKind.values.firstWhere((k) => k.name == s);
}

/// Serializes/deserializes drift rows to JSON-ready maps.
class EntityCodec {
  static Map<String, dynamic> roomToJson(BoxRoom r) => {
        'id': r.id,
        'name': r.name,
        'updatedAt': r.updatedAt,
      };

  static BoxRoom roomFromJson(Map<String, dynamic> j) => BoxRoom(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        updatedAt: (j['updatedAt'] as num).toInt(),
      );

  static RoomsCompanion roomCompanion(Map<String, dynamic> j) =>
      RoomsCompanion(
        id: Value((j['id'] as num).toInt()),
        name: Value(j['name'] as String),
        updatedAt: Value((j['updatedAt'] as num).toInt()),
      );

  static Map<String, dynamic> boxToJson(LitterBox b) => {
        'id': b.id,
        'name': b.name,
        'position': b.position,
        'type': b.type,
        'warnThresholdHours': b.warnThresholdHours,
        'overdueThresholdHours': b.overdueThresholdHours,
        'brand': b.brand,
        'model': b.model,
        'roomId': b.roomId,
        'updatedAt': b.updatedAt,
      };

  static LitterBox boxFromJson(Map<String, dynamic> j) => LitterBox(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        position: (j['position'] as num).toInt(),
        type: j['type'] as String,
        warnThresholdHours: (j['warnThresholdHours'] as num).toInt(),
        overdueThresholdHours: (j['overdueThresholdHours'] as num).toInt(),
        brand: j['brand'] as String,
        model: j['model'] as String,
        roomId: (j['roomId'] as num?)?.toInt(),
        updatedAt: (j['updatedAt'] as num).toInt(),
      );

  static LitterBoxesCompanion boxCompanion(Map<String, dynamic> j) =>
      LitterBoxesCompanion(
        id: Value((j['id'] as num).toInt()),
        name: Value(j['name'] as String),
        position: Value((j['position'] as num).toInt()),
        type: Value(j['type'] as String),
        warnThresholdHours:
            Value((j['warnThresholdHours'] as num).toInt()),
        overdueThresholdHours:
            Value((j['overdueThresholdHours'] as num).toInt()),
        brand: Value(j['brand'] as String),
        model: Value(j['model'] as String),
        roomId: Value((j['roomId'] as num?)?.toInt()),
        updatedAt: Value((j['updatedAt'] as num).toInt()),
      );

  static Map<String, dynamic> eventToJson(CleaningEvent e) => {
        'id': e.id,
        'boxId': e.boxId,
        'timestamp': e.timestamp,
        'dueToSmell': e.dueToSmell,
        'updatedAt': e.updatedAt,
      };

  static CleaningEvent eventFromJson(Map<String, dynamic> j) => CleaningEvent(
        id: (j['id'] as num).toInt(),
        boxId: (j['boxId'] as num).toInt(),
        timestamp: (j['timestamp'] as num).toInt(),
        dueToSmell: j['dueToSmell'] as bool?,
        updatedAt: (j['updatedAt'] as num).toInt(),
      );

  static CleaningEventsCompanion eventCompanion(Map<String, dynamic> j) =>
      CleaningEventsCompanion(
        id: Value((j['id'] as num).toInt()),
        boxId: Value((j['boxId'] as num).toInt()),
        timestamp: Value((j['timestamp'] as num).toInt()),
        dueToSmell: Value(j['dueToSmell'] as bool?),
        updatedAt: Value((j['updatedAt'] as num).toInt()),
      );

  static Map<String, dynamic> taskToJson(MaintenanceTask t) => {
        'id': t.id,
        'boxId': t.boxId,
        'name': t.name,
        'intervalCleanings': t.intervalCleanings,
        'anchorTimestamp': t.anchorTimestamp,
        'enabled': t.enabled,
        'offsetCleanings': t.offsetCleanings,
        'updatedAt': t.updatedAt,
      };

  static MaintenanceTask taskFromJson(Map<String, dynamic> j) =>
      MaintenanceTask(
        id: (j['id'] as num).toInt(),
        boxId: (j['boxId'] as num).toInt(),
        name: j['name'] as String,
        intervalCleanings: (j['intervalCleanings'] as num).toInt(),
        anchorTimestamp: (j['anchorTimestamp'] as num).toInt(),
        enabled: j['enabled'] as bool,
        offsetCleanings: (j['offsetCleanings'] as num).toInt(),
        updatedAt: (j['updatedAt'] as num).toInt(),
      );

  static MaintenanceTasksCompanion taskCompanion(Map<String, dynamic> j) =>
      MaintenanceTasksCompanion(
        id: Value((j['id'] as num).toInt()),
        boxId: Value((j['boxId'] as num).toInt()),
        name: Value(j['name'] as String),
        intervalCleanings: Value((j['intervalCleanings'] as num).toInt()),
        anchorTimestamp: Value((j['anchorTimestamp'] as num).toInt()),
        enabled: Value(j['enabled'] as bool),
        offsetCleanings: Value((j['offsetCleanings'] as num).toInt()),
        updatedAt: Value((j['updatedAt'] as num).toInt()),
      );
}

/// Wire protocol version. Bump on incompatible changes.
const int protocolVersion = 1;

/// Message types exchanged over the WebSocket.
class MsgType {
  // Client -> Master
  static const hello = 'hello';
  // Master -> Client
  static const welcome = 'welcome';
  // Master -> Client (full state)
  static const snapshot = 'snapshot';
  // Either direction: entity was created/updated.
  static const upsert = 'upsert';
  // Either direction: entity was deleted.
  static const delete = 'delete';
  // Heartbeat.
  static const ping = 'ping';
  static const pong = 'pong';
}

/// Helpers to construct message payloads.
class SyncMessages {
  static Map<String, dynamic> hello({
    required String deviceId,
    int? ownedRoomId,
  }) =>
      {
        'type': MsgType.hello,
        'protocol': protocolVersion,
        'deviceId': deviceId,
        'ownedRoomId': ownedRoomId,
      };

  static Map<String, dynamic> welcome({
    required int serverTime,
    required String masterDeviceId,
  }) =>
      {
        'type': MsgType.welcome,
        'protocol': protocolVersion,
        'serverTime': serverTime,
        'masterDeviceId': masterDeviceId,
      };

  static Map<String, dynamic> snapshot({
    required List<BoxRoom> rooms,
    required List<LitterBox> boxes,
    required List<CleaningEvent> events,
    required List<MaintenanceTask> tasks,
  }) =>
      {
        'type': MsgType.snapshot,
        'rooms': rooms.map(EntityCodec.roomToJson).toList(),
        'boxes': boxes.map(EntityCodec.boxToJson).toList(),
        'events': events.map(EntityCodec.eventToJson).toList(),
        'tasks': tasks.map(EntityCodec.taskToJson).toList(),
      };

  static Map<String, dynamic> upsertRoom(BoxRoom r, String originDeviceId) =>
      {
        'type': MsgType.upsert,
        'entity': EntityKind.room.wire,
        'originDeviceId': originDeviceId,
        'data': EntityCodec.roomToJson(r),
      };

  static Map<String, dynamic> upsertBox(LitterBox b, String originDeviceId) =>
      {
        'type': MsgType.upsert,
        'entity': EntityKind.box.wire,
        'originDeviceId': originDeviceId,
        'data': EntityCodec.boxToJson(b),
      };

  static Map<String, dynamic> upsertEvent(
          CleaningEvent e, String originDeviceId) =>
      {
        'type': MsgType.upsert,
        'entity': EntityKind.event.wire,
        'originDeviceId': originDeviceId,
        'data': EntityCodec.eventToJson(e),
      };

  static Map<String, dynamic> upsertTask(
          MaintenanceTask t, String originDeviceId) =>
      {
        'type': MsgType.upsert,
        'entity': EntityKind.task.wire,
        'originDeviceId': originDeviceId,
        'data': EntityCodec.taskToJson(t),
      };

  static Map<String, dynamic> delete({
    required EntityKind kind,
    required int id,
    required String originDeviceId,
  }) =>
      {
        'type': MsgType.delete,
        'entity': kind.wire,
        'originDeviceId': originDeviceId,
        'id': id,
      };
}
