// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _privateModeMeta = const VerificationMeta(
    'privateMode',
  );
  @override
  late final GeneratedColumn<bool> privateMode = GeneratedColumn<bool>(
    'private_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("private_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hiddenRangesMeta = const VerificationMeta(
    'hiddenRanges',
  );
  @override
  late final GeneratedColumn<String> hiddenRanges = GeneratedColumn<String>(
    'hidden_ranges',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SystemFolders.notes),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previousFolderIdMeta = const VerificationMeta(
    'previousFolderId',
  );
  @override
  late final GeneratedColumn<String> previousFolderId = GeneratedColumn<String>(
    'previous_folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blocksMeta = const VerificationMeta('blocks');
  @override
  late final GeneratedColumn<String> blocks = GeneratedColumn<String>(
    'blocks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    privateMode,
    hiddenRanges,
    createdAt,
    updatedAt,
    folderId,
    deletedAt,
    previousFolderId,
    blocks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('private_mode')) {
      context.handle(
        _privateModeMeta,
        privateMode.isAcceptableOrUnknown(
          data['private_mode']!,
          _privateModeMeta,
        ),
      );
    }
    if (data.containsKey('hidden_ranges')) {
      context.handle(
        _hiddenRangesMeta,
        hiddenRanges.isAcceptableOrUnknown(
          data['hidden_ranges']!,
          _hiddenRangesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('previous_folder_id')) {
      context.handle(
        _previousFolderIdMeta,
        previousFolderId.isAcceptableOrUnknown(
          data['previous_folder_id']!,
          _previousFolderIdMeta,
        ),
      );
    }
    if (data.containsKey('blocks')) {
      context.handle(
        _blocksMeta,
        blocks.isAcceptableOrUnknown(data['blocks']!, _blocksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      privateMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}private_mode'],
      )!,
      hiddenRanges: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hidden_ranges'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      previousFolderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_folder_id'],
      ),
      blocks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocks'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String content;
  final bool privateMode;
  final String hiddenRanges;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 메모가 담긴 폴더. (F1F-1)
  final String folderId;

  /// `최근 삭제된 항목`으로 옮긴 시각. 30일이 지나면 영구 삭제한다. (F1F-5)
  final DateTime? deletedAt;

  /// 삭제 전 폴더. 복구할 때 돌아갈 곳. (F1F-6)
  final String? previousFolderId;

  /// 정리 기능의 원본·정리본 박스(JSON 배열). 본문(content) 위에 놓인다. (F8-2)
  final String blocks;
  const Note({
    required this.id,
    required this.content,
    required this.privateMode,
    required this.hiddenRanges,
    required this.createdAt,
    required this.updatedAt,
    required this.folderId,
    this.deletedAt,
    this.previousFolderId,
    required this.blocks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    map['private_mode'] = Variable<bool>(privateMode);
    map['hidden_ranges'] = Variable<String>(hiddenRanges);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['folder_id'] = Variable<String>(folderId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || previousFolderId != null) {
      map['previous_folder_id'] = Variable<String>(previousFolderId);
    }
    map['blocks'] = Variable<String>(blocks);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      content: Value(content),
      privateMode: Value(privateMode),
      hiddenRanges: Value(hiddenRanges),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      folderId: Value(folderId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      previousFolderId: previousFolderId == null && nullToAbsent
          ? const Value.absent()
          : Value(previousFolderId),
      blocks: Value(blocks),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      privateMode: serializer.fromJson<bool>(json['privateMode']),
      hiddenRanges: serializer.fromJson<String>(json['hiddenRanges']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      folderId: serializer.fromJson<String>(json['folderId']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      previousFolderId: serializer.fromJson<String?>(json['previousFolderId']),
      blocks: serializer.fromJson<String>(json['blocks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'privateMode': serializer.toJson<bool>(privateMode),
      'hiddenRanges': serializer.toJson<String>(hiddenRanges),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'folderId': serializer.toJson<String>(folderId),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'previousFolderId': serializer.toJson<String?>(previousFolderId),
      'blocks': serializer.toJson<String>(blocks),
    };
  }

  Note copyWith({
    String? id,
    String? content,
    bool? privateMode,
    String? hiddenRanges,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? folderId,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> previousFolderId = const Value.absent(),
    String? blocks,
  }) => Note(
    id: id ?? this.id,
    content: content ?? this.content,
    privateMode: privateMode ?? this.privateMode,
    hiddenRanges: hiddenRanges ?? this.hiddenRanges,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    folderId: folderId ?? this.folderId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    previousFolderId: previousFolderId.present
        ? previousFolderId.value
        : this.previousFolderId,
    blocks: blocks ?? this.blocks,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      privateMode: data.privateMode.present
          ? data.privateMode.value
          : this.privateMode,
      hiddenRanges: data.hiddenRanges.present
          ? data.hiddenRanges.value
          : this.hiddenRanges,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      previousFolderId: data.previousFolderId.present
          ? data.previousFolderId.value
          : this.previousFolderId,
      blocks: data.blocks.present ? data.blocks.value : this.blocks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('privateMode: $privateMode, ')
          ..write('hiddenRanges: $hiddenRanges, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('folderId: $folderId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('previousFolderId: $previousFolderId, ')
          ..write('blocks: $blocks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    content,
    privateMode,
    hiddenRanges,
    createdAt,
    updatedAt,
    folderId,
    deletedAt,
    previousFolderId,
    blocks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.content == this.content &&
          other.privateMode == this.privateMode &&
          other.hiddenRanges == this.hiddenRanges &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.folderId == this.folderId &&
          other.deletedAt == this.deletedAt &&
          other.previousFolderId == this.previousFolderId &&
          other.blocks == this.blocks);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String> content;
  final Value<bool> privateMode;
  final Value<String> hiddenRanges;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> folderId;
  final Value<DateTime?> deletedAt;
  final Value<String?> previousFolderId;
  final Value<String> blocks;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.privateMode = const Value.absent(),
    this.hiddenRanges = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.folderId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.previousFolderId = const Value.absent(),
    this.blocks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    this.content = const Value.absent(),
    this.privateMode = const Value.absent(),
    this.hiddenRanges = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.folderId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.previousFolderId = const Value.absent(),
    this.blocks = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<bool>? privateMode,
    Expression<String>? hiddenRanges,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? folderId,
    Expression<DateTime>? deletedAt,
    Expression<String>? previousFolderId,
    Expression<String>? blocks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (privateMode != null) 'private_mode': privateMode,
      if (hiddenRanges != null) 'hidden_ranges': hiddenRanges,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (folderId != null) 'folder_id': folderId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (previousFolderId != null) 'previous_folder_id': previousFolderId,
      if (blocks != null) 'blocks': blocks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? content,
    Value<bool>? privateMode,
    Value<String>? hiddenRanges,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? folderId,
    Value<DateTime?>? deletedAt,
    Value<String?>? previousFolderId,
    Value<String>? blocks,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      privateMode: privateMode ?? this.privateMode,
      hiddenRanges: hiddenRanges ?? this.hiddenRanges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: folderId ?? this.folderId,
      deletedAt: deletedAt ?? this.deletedAt,
      previousFolderId: previousFolderId ?? this.previousFolderId,
      blocks: blocks ?? this.blocks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (privateMode.present) {
      map['private_mode'] = Variable<bool>(privateMode.value);
    }
    if (hiddenRanges.present) {
      map['hidden_ranges'] = Variable<String>(hiddenRanges.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (previousFolderId.present) {
      map['previous_folder_id'] = Variable<String>(previousFolderId.value);
    }
    if (blocks.present) {
      map['blocks'] = Variable<String>(blocks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('privateMode: $privateMode, ')
          ..write('hiddenRanges: $hiddenRanges, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('folderId: $folderId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('previousFolderId: $previousFolderId, ')
          ..write('blocks: $blocks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, isSystem, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String id;
  final String name;

  /// 기본 폴더인지(이름 변경·삭제 불가).
  final bool isSystem;
  final DateTime createdAt;
  const Folder({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_system'] = Variable<bool>(isSystem);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      isSystem: Value(isSystem),
      createdAt: Value(createdAt),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isSystem': serializer.toJson<bool>(isSystem),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Folder copyWith({
    String? id,
    String? name,
    bool? isSystem,
    DateTime? createdAt,
  }) => Folder(
    id: id ?? this.id,
    name: name ?? this.name,
    isSystem: isSystem ?? this.isSystem,
    createdAt: createdAt ?? this.createdAt,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isSystem, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.name == this.name &&
          other.isSystem == this.isSystem &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isSystem;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    required String name,
    this.isSystem = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Folder> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isSystem,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isSystem != null) 'is_system': isSystem,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isSystem,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [notes, folders];
}

typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  required String id,
  Value<String> content,
  Value<bool> privateMode,
  Value<String> hiddenRanges,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> folderId,
  Value<DateTime?> deletedAt,
  Value<String?> previousFolderId,
  Value<String> blocks,
  Value<int> rowid,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<String> id,
  Value<String> content,
  Value<bool> privateMode,
  Value<String> hiddenRanges,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> folderId,
  Value<DateTime?> deletedAt,
  Value<String?> previousFolderId,
  Value<String> blocks,
  Value<int> rowid,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get privateMode => $composableBuilder(
    column: $table.privateMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hiddenRanges => $composableBuilder(
    column: $table.hiddenRanges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousFolderId => $composableBuilder(
    column: $table.previousFolderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blocks => $composableBuilder(
    column: $table.blocks,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get privateMode => $composableBuilder(
    column: $table.privateMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hiddenRanges => $composableBuilder(
    column: $table.hiddenRanges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousFolderId => $composableBuilder(
    column: $table.previousFolderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blocks => $composableBuilder(
    column: $table.blocks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get privateMode => $composableBuilder(
    column: $table.privateMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hiddenRanges => $composableBuilder(
    column: $table.hiddenRanges,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get previousFolderId => $composableBuilder(
    column: $table.previousFolderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get blocks =>
      $composableBuilder(column: $table.blocks, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> privateMode = const Value.absent(),
                Value<String> hiddenRanges = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> previousFolderId = const Value.absent(),
                Value<String> blocks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                content: content,
                privateMode: privateMode,
                hiddenRanges: hiddenRanges,
                createdAt: createdAt,
                updatedAt: updatedAt,
                folderId: folderId,
                deletedAt: deletedAt,
                previousFolderId: previousFolderId,
                blocks: blocks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> content = const Value.absent(),
                Value<bool> privateMode = const Value.absent(),
                Value<String> hiddenRanges = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> folderId = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> previousFolderId = const Value.absent(),
                Value<String> blocks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                content: content,
                privateMode: privateMode,
                hiddenRanges: hiddenRanges,
                createdAt: createdAt,
                updatedAt: updatedAt,
                folderId: folderId,
                deletedAt: deletedAt,
                previousFolderId: previousFolderId,
                blocks: blocks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, Note>(table),
                  BaseReferences<_$AppDatabase, $NotesTable, Note>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  required String id,
  required String name,
  Value<bool> isSystem,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<bool> isSystem,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, BaseReferences<_$AppDatabase, $FoldersTable, Folder>),
          Folder,
          PrefetchHooks Function()
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                name: name,
                isSystem: isSystem,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> isSystem = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                name: name,
                isSystem: isSystem,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoldersTable, Folder>(table),
                  BaseReferences<_$AppDatabase, $FoldersTable, Folder>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, BaseReferences<_$AppDatabase, $FoldersTable, Folder>),
      Folder,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
}
