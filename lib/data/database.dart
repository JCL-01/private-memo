import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// 기본 폴더 id. (F1F-2)
abstract final class SystemFolders {
  /// `메모`: 기본 저장 폴더.
  static const notes = 'notes';

  /// `빠른 메모`: 정리 기능이 있는 폴더. (F8-2)
  static const quick = 'quick';

  /// `최근 삭제된 항목`.
  static const trash = 'trash';

  static const all = {notes, quick, trash};

  static const names = {notes: '메모', quick: '빠른 메모', trash: '최근 삭제된 항목'};
}

/// 메모 테이블.
///
/// [hiddenRanges]는 프라이빗 드래그로 가린 범위를 JSON 배열로 저장한다.
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  BoolColumn get privateMode => boolean().withDefault(const Constant(false))();
  TextColumn get hiddenRanges => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// 메모가 담긴 폴더. (F1F-1)
  TextColumn get folderId =>
      text().withDefault(const Constant(SystemFolders.notes))();

  /// `최근 삭제된 항목`으로 옮긴 시각. 30일이 지나면 영구 삭제한다. (F1F-5)
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// 삭제 전 폴더. 복구할 때 돌아갈 곳. (F1F-6)
  TextColumn get previousFolderId => text().nullable()();

  /// 정리 기능의 원본·정리본 박스(JSON 배열). 본문(content) 위에 놓인다. (F8-2)
  TextColumn get blocks => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 폴더 테이블. 기본 폴더 3개와 사용자가 만든 폴더. (F1F)
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 기본 폴더인지(이름 변경·삭제 불가).
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Notes, Folders])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'private_memo'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // 1 → 2: 폴더 추가. 기존 메모는 모두 `메모` 폴더로.
        await m.createTable(folders);
        await m.addColumn(notes, notes.folderId);
        await m.addColumn(notes, notes.deletedAt);
        await m.addColumn(notes, notes.previousFolderId);
      }
      if (from < 3) {
        // 2 → 3: 정리 기능의 박스.
        await m.addColumn(notes, notes.blocks);
      }
    },
    beforeOpen: (details) async {
      // 기본 폴더가 없으면 만든다.
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      for (final entry in SystemFolders.names.entries) {
        await into(folders).insert(
          FoldersCompanion.insert(
            id: entry.key,
            name: entry.value,
            isSystem: const Value(true),
            createdAt: epoch,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    },
  );
}
