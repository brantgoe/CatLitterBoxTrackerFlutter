// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RoomsTable extends Rooms with TableInfo<$RoomsTable, BoxRoom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: _uuid,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  @override
  List<GeneratedColumn> get $columns => [id, syncId, name, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoxRoom> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoxRoom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoxRoom(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class BoxRoom extends DataClass implements Insertable<BoxRoom> {
  final int id;
  final String syncId;
  final String name;
  final int updatedAt;
  const BoxRoom({
    required this.id,
    required this.syncId,
    required this.name,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_id'] = Variable<String>(syncId);
    map['name'] = Variable<String>(name);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      id: Value(id),
      syncId: Value(syncId),
      name: Value(name),
      updatedAt: Value(updatedAt),
    );
  }

  factory BoxRoom.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoxRoom(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      name: serializer.fromJson<String>(json['name']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncId': serializer.toJson<String>(syncId),
      'name': serializer.toJson<String>(name),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  BoxRoom copyWith({int? id, String? syncId, String? name, int? updatedAt}) =>
      BoxRoom(
        id: id ?? this.id,
        syncId: syncId ?? this.syncId,
        name: name ?? this.name,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BoxRoom copyWithCompanion(RoomsCompanion data) {
    return BoxRoom(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      name: data.name.present ? data.name.value : this.name,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoxRoom(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, syncId, name, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoxRoom &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.name == this.name &&
          other.updatedAt == this.updatedAt);
}

class RoomsCompanion extends UpdateCompanion<BoxRoom> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<String> name;
  final Value<int> updatedAt;
  const RoomsCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.name = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RoomsCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    required String name,
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<BoxRoom> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<String>? name,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (name != null) 'name': name,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RoomsCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<String>? name,
    Value<int>? updatedAt,
  }) {
    return RoomsCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LitterBoxesTable extends LitterBoxes
    with TableInfo<$LitterBoxesTable, LitterBox> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LitterBoxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: _uuid,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MANUAL_SCOOP'),
  );
  static const VerificationMeta _warnThresholdHoursMeta =
      const VerificationMeta('warnThresholdHours');
  @override
  late final GeneratedColumn<int> warnThresholdHours = GeneratedColumn<int>(
    'warn_threshold_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(24),
  );
  static const VerificationMeta _overdueThresholdHoursMeta =
      const VerificationMeta('overdueThresholdHours');
  @override
  late final GeneratedColumn<int> overdueThresholdHours = GeneratedColumn<int>(
    'overdue_threshold_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(48),
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<int> roomId = GeneratedColumn<int>(
    'room_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rooms (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncId,
    name,
    position,
    type,
    warnThresholdHours,
    overdueThresholdHours,
    brand,
    model,
    roomId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'litter_boxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LitterBox> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('warn_threshold_hours')) {
      context.handle(
        _warnThresholdHoursMeta,
        warnThresholdHours.isAcceptableOrUnknown(
          data['warn_threshold_hours']!,
          _warnThresholdHoursMeta,
        ),
      );
    }
    if (data.containsKey('overdue_threshold_hours')) {
      context.handle(
        _overdueThresholdHoursMeta,
        overdueThresholdHours.isAcceptableOrUnknown(
          data['overdue_threshold_hours']!,
          _overdueThresholdHoursMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LitterBox map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LitterBox(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      warnThresholdHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warn_threshold_hours'],
      )!,
      overdueThresholdHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overdue_threshold_hours'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}room_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LitterBoxesTable createAlias(String alias) {
    return $LitterBoxesTable(attachedDatabase, alias);
  }
}

class LitterBox extends DataClass implements Insertable<LitterBox> {
  final int id;
  final String syncId;
  final String name;
  final int position;
  final String type;
  final int warnThresholdHours;
  final int overdueThresholdHours;
  final String brand;
  final String model;
  final int? roomId;
  final int updatedAt;
  const LitterBox({
    required this.id,
    required this.syncId,
    required this.name,
    required this.position,
    required this.type,
    required this.warnThresholdHours,
    required this.overdueThresholdHours,
    required this.brand,
    required this.model,
    this.roomId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_id'] = Variable<String>(syncId);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['type'] = Variable<String>(type);
    map['warn_threshold_hours'] = Variable<int>(warnThresholdHours);
    map['overdue_threshold_hours'] = Variable<int>(overdueThresholdHours);
    map['brand'] = Variable<String>(brand);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<int>(roomId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LitterBoxesCompanion toCompanion(bool nullToAbsent) {
    return LitterBoxesCompanion(
      id: Value(id),
      syncId: Value(syncId),
      name: Value(name),
      position: Value(position),
      type: Value(type),
      warnThresholdHours: Value(warnThresholdHours),
      overdueThresholdHours: Value(overdueThresholdHours),
      brand: Value(brand),
      model: Value(model),
      roomId: roomId == null && nullToAbsent
          ? const Value.absent()
          : Value(roomId),
      updatedAt: Value(updatedAt),
    );
  }

  factory LitterBox.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LitterBox(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      type: serializer.fromJson<String>(json['type']),
      warnThresholdHours: serializer.fromJson<int>(json['warnThresholdHours']),
      overdueThresholdHours: serializer.fromJson<int>(
        json['overdueThresholdHours'],
      ),
      brand: serializer.fromJson<String>(json['brand']),
      model: serializer.fromJson<String>(json['model']),
      roomId: serializer.fromJson<int?>(json['roomId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncId': serializer.toJson<String>(syncId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'type': serializer.toJson<String>(type),
      'warnThresholdHours': serializer.toJson<int>(warnThresholdHours),
      'overdueThresholdHours': serializer.toJson<int>(overdueThresholdHours),
      'brand': serializer.toJson<String>(brand),
      'model': serializer.toJson<String>(model),
      'roomId': serializer.toJson<int?>(roomId),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LitterBox copyWith({
    int? id,
    String? syncId,
    String? name,
    int? position,
    String? type,
    int? warnThresholdHours,
    int? overdueThresholdHours,
    String? brand,
    String? model,
    Value<int?> roomId = const Value.absent(),
    int? updatedAt,
  }) => LitterBox(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    name: name ?? this.name,
    position: position ?? this.position,
    type: type ?? this.type,
    warnThresholdHours: warnThresholdHours ?? this.warnThresholdHours,
    overdueThresholdHours: overdueThresholdHours ?? this.overdueThresholdHours,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    roomId: roomId.present ? roomId.value : this.roomId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LitterBox copyWithCompanion(LitterBoxesCompanion data) {
    return LitterBox(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      type: data.type.present ? data.type.value : this.type,
      warnThresholdHours: data.warnThresholdHours.present
          ? data.warnThresholdHours.value
          : this.warnThresholdHours,
      overdueThresholdHours: data.overdueThresholdHours.present
          ? data.overdueThresholdHours.value
          : this.overdueThresholdHours,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LitterBox(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('type: $type, ')
          ..write('warnThresholdHours: $warnThresholdHours, ')
          ..write('overdueThresholdHours: $overdueThresholdHours, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('roomId: $roomId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncId,
    name,
    position,
    type,
    warnThresholdHours,
    overdueThresholdHours,
    brand,
    model,
    roomId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LitterBox &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.name == this.name &&
          other.position == this.position &&
          other.type == this.type &&
          other.warnThresholdHours == this.warnThresholdHours &&
          other.overdueThresholdHours == this.overdueThresholdHours &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.roomId == this.roomId &&
          other.updatedAt == this.updatedAt);
}

class LitterBoxesCompanion extends UpdateCompanion<LitterBox> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<String> name;
  final Value<int> position;
  final Value<String> type;
  final Value<int> warnThresholdHours;
  final Value<int> overdueThresholdHours;
  final Value<String> brand;
  final Value<String> model;
  final Value<int?> roomId;
  final Value<int> updatedAt;
  const LitterBoxesCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.type = const Value.absent(),
    this.warnThresholdHours = const Value.absent(),
    this.overdueThresholdHours = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.roomId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LitterBoxesCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    required String name,
    this.position = const Value.absent(),
    this.type = const Value.absent(),
    this.warnThresholdHours = const Value.absent(),
    this.overdueThresholdHours = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.roomId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<LitterBox> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<String>? name,
    Expression<int>? position,
    Expression<String>? type,
    Expression<int>? warnThresholdHours,
    Expression<int>? overdueThresholdHours,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<int>? roomId,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (type != null) 'type': type,
      if (warnThresholdHours != null)
        'warn_threshold_hours': warnThresholdHours,
      if (overdueThresholdHours != null)
        'overdue_threshold_hours': overdueThresholdHours,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (roomId != null) 'room_id': roomId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LitterBoxesCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<String>? name,
    Value<int>? position,
    Value<String>? type,
    Value<int>? warnThresholdHours,
    Value<int>? overdueThresholdHours,
    Value<String>? brand,
    Value<String>? model,
    Value<int?>? roomId,
    Value<int>? updatedAt,
  }) {
    return LitterBoxesCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      name: name ?? this.name,
      position: position ?? this.position,
      type: type ?? this.type,
      warnThresholdHours: warnThresholdHours ?? this.warnThresholdHours,
      overdueThresholdHours:
          overdueThresholdHours ?? this.overdueThresholdHours,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      roomId: roomId ?? this.roomId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (warnThresholdHours.present) {
      map['warn_threshold_hours'] = Variable<int>(warnThresholdHours.value);
    }
    if (overdueThresholdHours.present) {
      map['overdue_threshold_hours'] = Variable<int>(
        overdueThresholdHours.value,
      );
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<int>(roomId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LitterBoxesCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('type: $type, ')
          ..write('warnThresholdHours: $warnThresholdHours, ')
          ..write('overdueThresholdHours: $overdueThresholdHours, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('roomId: $roomId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CleaningEventsTable extends CleaningEvents
    with TableInfo<$CleaningEventsTable, CleaningEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CleaningEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: _uuid,
  );
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<int> boxId = GeneratedColumn<int>(
    'box_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES litter_boxes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueToSmellMeta = const VerificationMeta(
    'dueToSmell',
  );
  @override
  late final GeneratedColumn<bool> dueToSmell = GeneratedColumn<bool>(
    'due_to_smell',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("due_to_smell" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncId,
    boxId,
    timestamp,
    dueToSmell,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cleaning_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CleaningEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('box_id')) {
      context.handle(
        _boxIdMeta,
        boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('due_to_smell')) {
      context.handle(
        _dueToSmellMeta,
        dueToSmell.isAcceptableOrUnknown(
          data['due_to_smell']!,
          _dueToSmellMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CleaningEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CleaningEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      )!,
      boxId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      dueToSmell: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}due_to_smell'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CleaningEventsTable createAlias(String alias) {
    return $CleaningEventsTable(attachedDatabase, alias);
  }
}

class CleaningEvent extends DataClass implements Insertable<CleaningEvent> {
  final int id;
  final String syncId;
  final int boxId;
  final int timestamp;
  final bool? dueToSmell;
  final int updatedAt;
  const CleaningEvent({
    required this.id,
    required this.syncId,
    required this.boxId,
    required this.timestamp,
    this.dueToSmell,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_id'] = Variable<String>(syncId);
    map['box_id'] = Variable<int>(boxId);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || dueToSmell != null) {
      map['due_to_smell'] = Variable<bool>(dueToSmell);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CleaningEventsCompanion toCompanion(bool nullToAbsent) {
    return CleaningEventsCompanion(
      id: Value(id),
      syncId: Value(syncId),
      boxId: Value(boxId),
      timestamp: Value(timestamp),
      dueToSmell: dueToSmell == null && nullToAbsent
          ? const Value.absent()
          : Value(dueToSmell),
      updatedAt: Value(updatedAt),
    );
  }

  factory CleaningEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CleaningEvent(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      boxId: serializer.fromJson<int>(json['boxId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      dueToSmell: serializer.fromJson<bool?>(json['dueToSmell']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncId': serializer.toJson<String>(syncId),
      'boxId': serializer.toJson<int>(boxId),
      'timestamp': serializer.toJson<int>(timestamp),
      'dueToSmell': serializer.toJson<bool?>(dueToSmell),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CleaningEvent copyWith({
    int? id,
    String? syncId,
    int? boxId,
    int? timestamp,
    Value<bool?> dueToSmell = const Value.absent(),
    int? updatedAt,
  }) => CleaningEvent(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    boxId: boxId ?? this.boxId,
    timestamp: timestamp ?? this.timestamp,
    dueToSmell: dueToSmell.present ? dueToSmell.value : this.dueToSmell,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CleaningEvent copyWithCompanion(CleaningEventsCompanion data) {
    return CleaningEvent(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      dueToSmell: data.dueToSmell.present
          ? data.dueToSmell.value
          : this.dueToSmell,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CleaningEvent(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('boxId: $boxId, ')
          ..write('timestamp: $timestamp, ')
          ..write('dueToSmell: $dueToSmell, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, syncId, boxId, timestamp, dueToSmell, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CleaningEvent &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.boxId == this.boxId &&
          other.timestamp == this.timestamp &&
          other.dueToSmell == this.dueToSmell &&
          other.updatedAt == this.updatedAt);
}

class CleaningEventsCompanion extends UpdateCompanion<CleaningEvent> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<int> boxId;
  final Value<int> timestamp;
  final Value<bool?> dueToSmell;
  final Value<int> updatedAt;
  const CleaningEventsCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.boxId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.dueToSmell = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CleaningEventsCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    required int boxId,
    required int timestamp,
    this.dueToSmell = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : boxId = Value(boxId),
       timestamp = Value(timestamp);
  static Insertable<CleaningEvent> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<int>? boxId,
    Expression<int>? timestamp,
    Expression<bool>? dueToSmell,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (boxId != null) 'box_id': boxId,
      if (timestamp != null) 'timestamp': timestamp,
      if (dueToSmell != null) 'due_to_smell': dueToSmell,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CleaningEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<int>? boxId,
    Value<int>? timestamp,
    Value<bool?>? dueToSmell,
    Value<int>? updatedAt,
  }) {
    return CleaningEventsCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      boxId: boxId ?? this.boxId,
      timestamp: timestamp ?? this.timestamp,
      dueToSmell: dueToSmell ?? this.dueToSmell,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<int>(boxId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (dueToSmell.present) {
      map['due_to_smell'] = Variable<bool>(dueToSmell.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CleaningEventsCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('boxId: $boxId, ')
          ..write('timestamp: $timestamp, ')
          ..write('dueToSmell: $dueToSmell, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MaintenanceTasksTable extends MaintenanceTasks
    with TableInfo<$MaintenanceTasksTable, MaintenanceTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenanceTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: _uuid,
  );
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<int> boxId = GeneratedColumn<int>(
    'box_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES litter_boxes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalCleaningsMeta = const VerificationMeta(
    'intervalCleanings',
  );
  @override
  late final GeneratedColumn<int> intervalCleanings = GeneratedColumn<int>(
    'interval_cleanings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorTimestampMeta = const VerificationMeta(
    'anchorTimestamp',
  );
  @override
  late final GeneratedColumn<int> anchorTimestamp = GeneratedColumn<int>(
    'anchor_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _offsetCleaningsMeta = const VerificationMeta(
    'offsetCleanings',
  );
  @override
  late final GeneratedColumn<int> offsetCleanings = GeneratedColumn<int>(
    'offset_cleanings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncId,
    boxId,
    name,
    intervalCleanings,
    anchorTimestamp,
    enabled,
    offsetCleanings,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenance_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('box_id')) {
      context.handle(
        _boxIdMeta,
        boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('interval_cleanings')) {
      context.handle(
        _intervalCleaningsMeta,
        intervalCleanings.isAcceptableOrUnknown(
          data['interval_cleanings']!,
          _intervalCleaningsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalCleaningsMeta);
    }
    if (data.containsKey('anchor_timestamp')) {
      context.handle(
        _anchorTimestampMeta,
        anchorTimestamp.isAcceptableOrUnknown(
          data['anchor_timestamp']!,
          _anchorTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_anchorTimestampMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('offset_cleanings')) {
      context.handle(
        _offsetCleaningsMeta,
        offsetCleanings.isAcceptableOrUnknown(
          data['offset_cleanings']!,
          _offsetCleaningsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaintenanceTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      )!,
      boxId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      intervalCleanings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_cleanings'],
      )!,
      anchorTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anchor_timestamp'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      offsetCleanings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_cleanings'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MaintenanceTasksTable createAlias(String alias) {
    return $MaintenanceTasksTable(attachedDatabase, alias);
  }
}

class MaintenanceTask extends DataClass implements Insertable<MaintenanceTask> {
  final int id;
  final String syncId;
  final int boxId;
  final String name;
  final int intervalCleanings;
  final int anchorTimestamp;
  final bool enabled;
  final int offsetCleanings;
  final int updatedAt;
  const MaintenanceTask({
    required this.id,
    required this.syncId,
    required this.boxId,
    required this.name,
    required this.intervalCleanings,
    required this.anchorTimestamp,
    required this.enabled,
    required this.offsetCleanings,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_id'] = Variable<String>(syncId);
    map['box_id'] = Variable<int>(boxId);
    map['name'] = Variable<String>(name);
    map['interval_cleanings'] = Variable<int>(intervalCleanings);
    map['anchor_timestamp'] = Variable<int>(anchorTimestamp);
    map['enabled'] = Variable<bool>(enabled);
    map['offset_cleanings'] = Variable<int>(offsetCleanings);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  MaintenanceTasksCompanion toCompanion(bool nullToAbsent) {
    return MaintenanceTasksCompanion(
      id: Value(id),
      syncId: Value(syncId),
      boxId: Value(boxId),
      name: Value(name),
      intervalCleanings: Value(intervalCleanings),
      anchorTimestamp: Value(anchorTimestamp),
      enabled: Value(enabled),
      offsetCleanings: Value(offsetCleanings),
      updatedAt: Value(updatedAt),
    );
  }

  factory MaintenanceTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceTask(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      boxId: serializer.fromJson<int>(json['boxId']),
      name: serializer.fromJson<String>(json['name']),
      intervalCleanings: serializer.fromJson<int>(json['intervalCleanings']),
      anchorTimestamp: serializer.fromJson<int>(json['anchorTimestamp']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      offsetCleanings: serializer.fromJson<int>(json['offsetCleanings']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncId': serializer.toJson<String>(syncId),
      'boxId': serializer.toJson<int>(boxId),
      'name': serializer.toJson<String>(name),
      'intervalCleanings': serializer.toJson<int>(intervalCleanings),
      'anchorTimestamp': serializer.toJson<int>(anchorTimestamp),
      'enabled': serializer.toJson<bool>(enabled),
      'offsetCleanings': serializer.toJson<int>(offsetCleanings),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  MaintenanceTask copyWith({
    int? id,
    String? syncId,
    int? boxId,
    String? name,
    int? intervalCleanings,
    int? anchorTimestamp,
    bool? enabled,
    int? offsetCleanings,
    int? updatedAt,
  }) => MaintenanceTask(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    boxId: boxId ?? this.boxId,
    name: name ?? this.name,
    intervalCleanings: intervalCleanings ?? this.intervalCleanings,
    anchorTimestamp: anchorTimestamp ?? this.anchorTimestamp,
    enabled: enabled ?? this.enabled,
    offsetCleanings: offsetCleanings ?? this.offsetCleanings,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MaintenanceTask copyWithCompanion(MaintenanceTasksCompanion data) {
    return MaintenanceTask(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
      name: data.name.present ? data.name.value : this.name,
      intervalCleanings: data.intervalCleanings.present
          ? data.intervalCleanings.value
          : this.intervalCleanings,
      anchorTimestamp: data.anchorTimestamp.present
          ? data.anchorTimestamp.value
          : this.anchorTimestamp,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      offsetCleanings: data.offsetCleanings.present
          ? data.offsetCleanings.value
          : this.offsetCleanings,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceTask(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('boxId: $boxId, ')
          ..write('name: $name, ')
          ..write('intervalCleanings: $intervalCleanings, ')
          ..write('anchorTimestamp: $anchorTimestamp, ')
          ..write('enabled: $enabled, ')
          ..write('offsetCleanings: $offsetCleanings, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncId,
    boxId,
    name,
    intervalCleanings,
    anchorTimestamp,
    enabled,
    offsetCleanings,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceTask &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.boxId == this.boxId &&
          other.name == this.name &&
          other.intervalCleanings == this.intervalCleanings &&
          other.anchorTimestamp == this.anchorTimestamp &&
          other.enabled == this.enabled &&
          other.offsetCleanings == this.offsetCleanings &&
          other.updatedAt == this.updatedAt);
}

class MaintenanceTasksCompanion extends UpdateCompanion<MaintenanceTask> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<int> boxId;
  final Value<String> name;
  final Value<int> intervalCleanings;
  final Value<int> anchorTimestamp;
  final Value<bool> enabled;
  final Value<int> offsetCleanings;
  final Value<int> updatedAt;
  const MaintenanceTasksCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.boxId = const Value.absent(),
    this.name = const Value.absent(),
    this.intervalCleanings = const Value.absent(),
    this.anchorTimestamp = const Value.absent(),
    this.enabled = const Value.absent(),
    this.offsetCleanings = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MaintenanceTasksCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    required int boxId,
    required String name,
    required int intervalCleanings,
    required int anchorTimestamp,
    this.enabled = const Value.absent(),
    this.offsetCleanings = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : boxId = Value(boxId),
       name = Value(name),
       intervalCleanings = Value(intervalCleanings),
       anchorTimestamp = Value(anchorTimestamp);
  static Insertable<MaintenanceTask> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<int>? boxId,
    Expression<String>? name,
    Expression<int>? intervalCleanings,
    Expression<int>? anchorTimestamp,
    Expression<bool>? enabled,
    Expression<int>? offsetCleanings,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (boxId != null) 'box_id': boxId,
      if (name != null) 'name': name,
      if (intervalCleanings != null) 'interval_cleanings': intervalCleanings,
      if (anchorTimestamp != null) 'anchor_timestamp': anchorTimestamp,
      if (enabled != null) 'enabled': enabled,
      if (offsetCleanings != null) 'offset_cleanings': offsetCleanings,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MaintenanceTasksCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<int>? boxId,
    Value<String>? name,
    Value<int>? intervalCleanings,
    Value<int>? anchorTimestamp,
    Value<bool>? enabled,
    Value<int>? offsetCleanings,
    Value<int>? updatedAt,
  }) {
    return MaintenanceTasksCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      boxId: boxId ?? this.boxId,
      name: name ?? this.name,
      intervalCleanings: intervalCleanings ?? this.intervalCleanings,
      anchorTimestamp: anchorTimestamp ?? this.anchorTimestamp,
      enabled: enabled ?? this.enabled,
      offsetCleanings: offsetCleanings ?? this.offsetCleanings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<int>(boxId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (intervalCleanings.present) {
      map['interval_cleanings'] = Variable<int>(intervalCleanings.value);
    }
    if (anchorTimestamp.present) {
      map['anchor_timestamp'] = Variable<int>(anchorTimestamp.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (offsetCleanings.present) {
      map['offset_cleanings'] = Variable<int>(offsetCleanings.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceTasksCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('boxId: $boxId, ')
          ..write('name: $name, ')
          ..write('intervalCleanings: $intervalCleanings, ')
          ..write('anchorTimestamp: $anchorTimestamp, ')
          ..write('enabled: $enabled, ')
          ..write('offsetCleanings: $offsetCleanings, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RoomsTable rooms = $RoomsTable(this);
  late final $LitterBoxesTable litterBoxes = $LitterBoxesTable(this);
  late final $CleaningEventsTable cleaningEvents = $CleaningEventsTable(this);
  late final $MaintenanceTasksTable maintenanceTasks = $MaintenanceTasksTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    rooms,
    litterBoxes,
    cleaningEvents,
    maintenanceTasks,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rooms',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('litter_boxes', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'litter_boxes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cleaning_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'litter_boxes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('maintenance_tasks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$RoomsTableCreateCompanionBuilder =
    RoomsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      required String name,
      Value<int> updatedAt,
    });
typedef $$RoomsTableUpdateCompanionBuilder =
    RoomsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<String> name,
      Value<int> updatedAt,
    });

final class $$RoomsTableReferences
    extends BaseReferences<_$AppDatabase, $RoomsTable, BoxRoom> {
  $$RoomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LitterBoxesTable, List<LitterBox>>
  _litterBoxesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.litterBoxes,
    aliasName: $_aliasNameGenerator(db.rooms.id, db.litterBoxes.roomId),
  );

  $$LitterBoxesTableProcessedTableManager get litterBoxesRefs {
    final manager = $$LitterBoxesTableTableManager(
      $_db,
      $_db.litterBoxes,
    ).filter((f) => f.roomId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_litterBoxesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoomsTableFilterComposer extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> litterBoxesRefs(
    Expression<bool> Function($$LitterBoxesTableFilterComposer f) f,
  ) {
    final $$LitterBoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.litterBoxes,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LitterBoxesTableFilterComposer(
            $db: $db,
            $table: $db.litterBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> litterBoxesRefs<T extends Object>(
    Expression<T> Function($$LitterBoxesTableAnnotationComposer a) f,
  ) {
    final $$LitterBoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.litterBoxes,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LitterBoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.litterBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoomsTable,
          BoxRoom,
          $$RoomsTableFilterComposer,
          $$RoomsTableOrderingComposer,
          $$RoomsTableAnnotationComposer,
          $$RoomsTableCreateCompanionBuilder,
          $$RoomsTableUpdateCompanionBuilder,
          (BoxRoom, $$RoomsTableReferences),
          BoxRoom,
          PrefetchHooks Function({bool litterBoxesRefs})
        > {
  $$RoomsTableTableManager(_$AppDatabase db, $RoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => RoomsCompanion(
                id: id,
                syncId: syncId,
                name: name,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                required String name,
                Value<int> updatedAt = const Value.absent(),
              }) => RoomsCompanion.insert(
                id: id,
                syncId: syncId,
                name: name,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RoomsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({litterBoxesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (litterBoxesRefs) db.litterBoxes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (litterBoxesRefs)
                    await $_getPrefetchedData<BoxRoom, $RoomsTable, LitterBox>(
                      currentTable: table,
                      referencedTable: $$RoomsTableReferences
                          ._litterBoxesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RoomsTableReferences(db, table, p0).litterBoxesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.roomId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoomsTable,
      BoxRoom,
      $$RoomsTableFilterComposer,
      $$RoomsTableOrderingComposer,
      $$RoomsTableAnnotationComposer,
      $$RoomsTableCreateCompanionBuilder,
      $$RoomsTableUpdateCompanionBuilder,
      (BoxRoom, $$RoomsTableReferences),
      BoxRoom,
      PrefetchHooks Function({bool litterBoxesRefs})
    >;
typedef $$LitterBoxesTableCreateCompanionBuilder =
    LitterBoxesCompanion Function({
      Value<int> id,
      Value<String> syncId,
      required String name,
      Value<int> position,
      Value<String> type,
      Value<int> warnThresholdHours,
      Value<int> overdueThresholdHours,
      Value<String> brand,
      Value<String> model,
      Value<int?> roomId,
      Value<int> updatedAt,
    });
typedef $$LitterBoxesTableUpdateCompanionBuilder =
    LitterBoxesCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<String> name,
      Value<int> position,
      Value<String> type,
      Value<int> warnThresholdHours,
      Value<int> overdueThresholdHours,
      Value<String> brand,
      Value<String> model,
      Value<int?> roomId,
      Value<int> updatedAt,
    });

final class $$LitterBoxesTableReferences
    extends BaseReferences<_$AppDatabase, $LitterBoxesTable, LitterBox> {
  $$LitterBoxesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoomsTable _roomIdTable(_$AppDatabase db) => db.rooms.createAlias(
    $_aliasNameGenerator(db.litterBoxes.roomId, db.rooms.id),
  );

  $$RoomsTableProcessedTableManager? get roomId {
    final $_column = $_itemColumn<int>('room_id');
    if ($_column == null) return null;
    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CleaningEventsTable, List<CleaningEvent>>
  _cleaningEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cleaningEvents,
    aliasName: $_aliasNameGenerator(db.litterBoxes.id, db.cleaningEvents.boxId),
  );

  $$CleaningEventsTableProcessedTableManager get cleaningEventsRefs {
    final manager = $$CleaningEventsTableTableManager(
      $_db,
      $_db.cleaningEvents,
    ).filter((f) => f.boxId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cleaningEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MaintenanceTasksTable, List<MaintenanceTask>>
  _maintenanceTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.maintenanceTasks,
    aliasName: $_aliasNameGenerator(
      db.litterBoxes.id,
      db.maintenanceTasks.boxId,
    ),
  );

  $$MaintenanceTasksTableProcessedTableManager get maintenanceTasksRefs {
    final manager = $$MaintenanceTasksTableTableManager(
      $_db,
      $_db.maintenanceTasks,
    ).filter((f) => f.boxId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _maintenanceTasksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LitterBoxesTableFilterComposer
    extends Composer<_$AppDatabase, $LitterBoxesTable> {
  $$LitterBoxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warnThresholdHours => $composableBuilder(
    column: $table.warnThresholdHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overdueThresholdHours => $composableBuilder(
    column: $table.overdueThresholdHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cleaningEventsRefs(
    Expression<bool> Function($$CleaningEventsTableFilterComposer f) f,
  ) {
    final $$CleaningEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cleaningEvents,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CleaningEventsTableFilterComposer(
            $db: $db,
            $table: $db.cleaningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> maintenanceTasksRefs(
    Expression<bool> Function($$MaintenanceTasksTableFilterComposer f) f,
  ) {
    final $$MaintenanceTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.maintenanceTasks,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceTasksTableFilterComposer(
            $db: $db,
            $table: $db.maintenanceTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LitterBoxesTableOrderingComposer
    extends Composer<_$AppDatabase, $LitterBoxesTable> {
  $$LitterBoxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warnThresholdHours => $composableBuilder(
    column: $table.warnThresholdHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overdueThresholdHours => $composableBuilder(
    column: $table.overdueThresholdHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableOrderingComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LitterBoxesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LitterBoxesTable> {
  $$LitterBoxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get warnThresholdHours => $composableBuilder(
    column: $table.warnThresholdHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overdueThresholdHours => $composableBuilder(
    column: $table.overdueThresholdHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cleaningEventsRefs<T extends Object>(
    Expression<T> Function($$CleaningEventsTableAnnotationComposer a) f,
  ) {
    final $$CleaningEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cleaningEvents,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CleaningEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.cleaningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> maintenanceTasksRefs<T extends Object>(
    Expression<T> Function($$MaintenanceTasksTableAnnotationComposer a) f,
  ) {
    final $$MaintenanceTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.maintenanceTasks,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.maintenanceTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LitterBoxesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LitterBoxesTable,
          LitterBox,
          $$LitterBoxesTableFilterComposer,
          $$LitterBoxesTableOrderingComposer,
          $$LitterBoxesTableAnnotationComposer,
          $$LitterBoxesTableCreateCompanionBuilder,
          $$LitterBoxesTableUpdateCompanionBuilder,
          (LitterBox, $$LitterBoxesTableReferences),
          LitterBox,
          PrefetchHooks Function({
            bool roomId,
            bool cleaningEventsRefs,
            bool maintenanceTasksRefs,
          })
        > {
  $$LitterBoxesTableTableManager(_$AppDatabase db, $LitterBoxesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LitterBoxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LitterBoxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LitterBoxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> warnThresholdHours = const Value.absent(),
                Value<int> overdueThresholdHours = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int?> roomId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => LitterBoxesCompanion(
                id: id,
                syncId: syncId,
                name: name,
                position: position,
                type: type,
                warnThresholdHours: warnThresholdHours,
                overdueThresholdHours: overdueThresholdHours,
                brand: brand,
                model: model,
                roomId: roomId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                required String name,
                Value<int> position = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> warnThresholdHours = const Value.absent(),
                Value<int> overdueThresholdHours = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int?> roomId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => LitterBoxesCompanion.insert(
                id: id,
                syncId: syncId,
                name: name,
                position: position,
                type: type,
                warnThresholdHours: warnThresholdHours,
                overdueThresholdHours: overdueThresholdHours,
                brand: brand,
                model: model,
                roomId: roomId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LitterBoxesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                roomId = false,
                cleaningEventsRefs = false,
                maintenanceTasksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cleaningEventsRefs) db.cleaningEvents,
                    if (maintenanceTasksRefs) db.maintenanceTasks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (roomId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.roomId,
                                    referencedTable:
                                        $$LitterBoxesTableReferences
                                            ._roomIdTable(db),
                                    referencedColumn:
                                        $$LitterBoxesTableReferences
                                            ._roomIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cleaningEventsRefs)
                        await $_getPrefetchedData<
                          LitterBox,
                          $LitterBoxesTable,
                          CleaningEvent
                        >(
                          currentTable: table,
                          referencedTable: $$LitterBoxesTableReferences
                              ._cleaningEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LitterBoxesTableReferences(
                                db,
                                table,
                                p0,
                              ).cleaningEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boxId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (maintenanceTasksRefs)
                        await $_getPrefetchedData<
                          LitterBox,
                          $LitterBoxesTable,
                          MaintenanceTask
                        >(
                          currentTable: table,
                          referencedTable: $$LitterBoxesTableReferences
                              ._maintenanceTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LitterBoxesTableReferences(
                                db,
                                table,
                                p0,
                              ).maintenanceTasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boxId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LitterBoxesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LitterBoxesTable,
      LitterBox,
      $$LitterBoxesTableFilterComposer,
      $$LitterBoxesTableOrderingComposer,
      $$LitterBoxesTableAnnotationComposer,
      $$LitterBoxesTableCreateCompanionBuilder,
      $$LitterBoxesTableUpdateCompanionBuilder,
      (LitterBox, $$LitterBoxesTableReferences),
      LitterBox,
      PrefetchHooks Function({
        bool roomId,
        bool cleaningEventsRefs,
        bool maintenanceTasksRefs,
      })
    >;
typedef $$CleaningEventsTableCreateCompanionBuilder =
    CleaningEventsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      required int boxId,
      required int timestamp,
      Value<bool?> dueToSmell,
      Value<int> updatedAt,
    });
typedef $$CleaningEventsTableUpdateCompanionBuilder =
    CleaningEventsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int> boxId,
      Value<int> timestamp,
      Value<bool?> dueToSmell,
      Value<int> updatedAt,
    });

final class $$CleaningEventsTableReferences
    extends BaseReferences<_$AppDatabase, $CleaningEventsTable, CleaningEvent> {
  $$CleaningEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LitterBoxesTable _boxIdTable(_$AppDatabase db) =>
      db.litterBoxes.createAlias(
        $_aliasNameGenerator(db.cleaningEvents.boxId, db.litterBoxes.id),
      );

  $$LitterBoxesTableProcessedTableManager get boxId {
    final $_column = $_itemColumn<int>('box_id')!;

    final manager = $$LitterBoxesTableTableManager(
      $_db,
      $_db.litterBoxes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CleaningEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CleaningEventsTable> {
  $$CleaningEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dueToSmell => $composableBuilder(
    column: $table.dueToSmell,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LitterBoxesTableFilterComposer get boxId {
    final $$LitterBoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.litterBoxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LitterBoxesTableFilterComposer(
            $db: $db,
            $table: $db.litterBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CleaningEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CleaningEventsTable> {
  $$CleaningEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dueToSmell => $composableBuilder(
    column: $table.dueToSmell,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LitterBoxesTableOrderingComposer get boxId {
    final $$LitterBoxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.litterBoxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LitterBoxesTableOrderingComposer(
            $db: $db,
            $table: $db.litterBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CleaningEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CleaningEventsTable> {
  $$CleaningEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get dueToSmell => $composableBuilder(
    column: $table.dueToSmell,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LitterBoxesTableAnnotationComposer get boxId {
    final $$LitterBoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.litterBoxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LitterBoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.litterBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CleaningEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CleaningEventsTable,
          CleaningEvent,
          $$CleaningEventsTableFilterComposer,
          $$CleaningEventsTableOrderingComposer,
          $$CleaningEventsTableAnnotationComposer,
          $$CleaningEventsTableCreateCompanionBuilder,
          $$CleaningEventsTableUpdateCompanionBuilder,
          (CleaningEvent, $$CleaningEventsTableReferences),
          CleaningEvent,
          PrefetchHooks Function({bool boxId})
        > {
  $$CleaningEventsTableTableManager(
    _$AppDatabase db,
    $CleaningEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CleaningEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CleaningEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CleaningEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int> boxId = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<bool?> dueToSmell = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => CleaningEventsCompanion(
                id: id,
                syncId: syncId,
                boxId: boxId,
                timestamp: timestamp,
                dueToSmell: dueToSmell,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                required int boxId,
                required int timestamp,
                Value<bool?> dueToSmell = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => CleaningEventsCompanion.insert(
                id: id,
                syncId: syncId,
                boxId: boxId,
                timestamp: timestamp,
                dueToSmell: dueToSmell,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CleaningEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boxId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boxId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boxId,
                                referencedTable: $$CleaningEventsTableReferences
                                    ._boxIdTable(db),
                                referencedColumn:
                                    $$CleaningEventsTableReferences
                                        ._boxIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CleaningEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CleaningEventsTable,
      CleaningEvent,
      $$CleaningEventsTableFilterComposer,
      $$CleaningEventsTableOrderingComposer,
      $$CleaningEventsTableAnnotationComposer,
      $$CleaningEventsTableCreateCompanionBuilder,
      $$CleaningEventsTableUpdateCompanionBuilder,
      (CleaningEvent, $$CleaningEventsTableReferences),
      CleaningEvent,
      PrefetchHooks Function({bool boxId})
    >;
typedef $$MaintenanceTasksTableCreateCompanionBuilder =
    MaintenanceTasksCompanion Function({
      Value<int> id,
      Value<String> syncId,
      required int boxId,
      required String name,
      required int intervalCleanings,
      required int anchorTimestamp,
      Value<bool> enabled,
      Value<int> offsetCleanings,
      Value<int> updatedAt,
    });
typedef $$MaintenanceTasksTableUpdateCompanionBuilder =
    MaintenanceTasksCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int> boxId,
      Value<String> name,
      Value<int> intervalCleanings,
      Value<int> anchorTimestamp,
      Value<bool> enabled,
      Value<int> offsetCleanings,
      Value<int> updatedAt,
    });

final class $$MaintenanceTasksTableReferences
    extends
        BaseReferences<_$AppDatabase, $MaintenanceTasksTable, MaintenanceTask> {
  $$MaintenanceTasksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LitterBoxesTable _boxIdTable(_$AppDatabase db) =>
      db.litterBoxes.createAlias(
        $_aliasNameGenerator(db.maintenanceTasks.boxId, db.litterBoxes.id),
      );

  $$LitterBoxesTableProcessedTableManager get boxId {
    final $_column = $_itemColumn<int>('box_id')!;

    final manager = $$LitterBoxesTableTableManager(
      $_db,
      $_db.litterBoxes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MaintenanceTasksTableFilterComposer
    extends Composer<_$AppDatabase, $MaintenanceTasksTable> {
  $$MaintenanceTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalCleanings => $composableBuilder(
    column: $table.intervalCleanings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anchorTimestamp => $composableBuilder(
    column: $table.anchorTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetCleanings => $composableBuilder(
    column: $table.offsetCleanings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LitterBoxesTableFilterComposer get boxId {
    final $$LitterBoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.litterBoxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LitterBoxesTableFilterComposer(
            $db: $db,
            $table: $db.litterBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaintenanceTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $MaintenanceTasksTable> {
  $$MaintenanceTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalCleanings => $composableBuilder(
    column: $table.intervalCleanings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anchorTimestamp => $composableBuilder(
    column: $table.anchorTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetCleanings => $composableBuilder(
    column: $table.offsetCleanings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LitterBoxesTableOrderingComposer get boxId {
    final $$LitterBoxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.litterBoxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LitterBoxesTableOrderingComposer(
            $db: $db,
            $table: $db.litterBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaintenanceTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaintenanceTasksTable> {
  $$MaintenanceTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get intervalCleanings => $composableBuilder(
    column: $table.intervalCleanings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get anchorTimestamp => $composableBuilder(
    column: $table.anchorTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get offsetCleanings => $composableBuilder(
    column: $table.offsetCleanings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LitterBoxesTableAnnotationComposer get boxId {
    final $$LitterBoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.litterBoxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LitterBoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.litterBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaintenanceTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaintenanceTasksTable,
          MaintenanceTask,
          $$MaintenanceTasksTableFilterComposer,
          $$MaintenanceTasksTableOrderingComposer,
          $$MaintenanceTasksTableAnnotationComposer,
          $$MaintenanceTasksTableCreateCompanionBuilder,
          $$MaintenanceTasksTableUpdateCompanionBuilder,
          (MaintenanceTask, $$MaintenanceTasksTableReferences),
          MaintenanceTask,
          PrefetchHooks Function({bool boxId})
        > {
  $$MaintenanceTasksTableTableManager(
    _$AppDatabase db,
    $MaintenanceTasksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaintenanceTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaintenanceTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaintenanceTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int> boxId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> intervalCleanings = const Value.absent(),
                Value<int> anchorTimestamp = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> offsetCleanings = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => MaintenanceTasksCompanion(
                id: id,
                syncId: syncId,
                boxId: boxId,
                name: name,
                intervalCleanings: intervalCleanings,
                anchorTimestamp: anchorTimestamp,
                enabled: enabled,
                offsetCleanings: offsetCleanings,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                required int boxId,
                required String name,
                required int intervalCleanings,
                required int anchorTimestamp,
                Value<bool> enabled = const Value.absent(),
                Value<int> offsetCleanings = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => MaintenanceTasksCompanion.insert(
                id: id,
                syncId: syncId,
                boxId: boxId,
                name: name,
                intervalCleanings: intervalCleanings,
                anchorTimestamp: anchorTimestamp,
                enabled: enabled,
                offsetCleanings: offsetCleanings,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MaintenanceTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boxId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boxId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boxId,
                                referencedTable:
                                    $$MaintenanceTasksTableReferences
                                        ._boxIdTable(db),
                                referencedColumn:
                                    $$MaintenanceTasksTableReferences
                                        ._boxIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MaintenanceTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaintenanceTasksTable,
      MaintenanceTask,
      $$MaintenanceTasksTableFilterComposer,
      $$MaintenanceTasksTableOrderingComposer,
      $$MaintenanceTasksTableAnnotationComposer,
      $$MaintenanceTasksTableCreateCompanionBuilder,
      $$MaintenanceTasksTableUpdateCompanionBuilder,
      (MaintenanceTask, $$MaintenanceTasksTableReferences),
      MaintenanceTask,
      PrefetchHooks Function({bool boxId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db, _db.rooms);
  $$LitterBoxesTableTableManager get litterBoxes =>
      $$LitterBoxesTableTableManager(_db, _db.litterBoxes);
  $$CleaningEventsTableTableManager get cleaningEvents =>
      $$CleaningEventsTableTableManager(_db, _db.cleaningEvents);
  $$MaintenanceTasksTableTableManager get maintenanceTasks =>
      $$MaintenanceTasksTableTableManager(_db, _db.maintenanceTasks);
}
