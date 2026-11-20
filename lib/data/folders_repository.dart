import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

/// 폴더 만들기·이름 바꾸기·지우기. (F1F)
class FoldersRepository {
  FoldersRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  /// 기본 폴더(메모, 빠른 메모, 최근 삭제된 항목) 다음에 사용자 폴더를 만든 순서대로.
  Stream<List<Folder>> watchAll() {
    return (_db.select(_db.folders)..orderBy([
          (f) => OrderingTerm.asc(f.createdAt),
          (f) => OrderingTerm.asc(f.name),
        ]))
        .watch()
        .map((list) {
          const order = [
            SystemFolders.notes,
            SystemFolders.quick,
            SystemFolders.trash,
          ];
          final system = list.where((f) => f.isSystem).toList()
            ..sort(
              (a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)),
            );
          return [...system, ...list.where((f) => !f.isSystem)];
        });
  }

  Future<Folder?> getById(String id) => (_db.select(
    _db.folders,
  )..where((f) => f.id.equals(id))).getSingleOrNull();

  /// 이름이 비어 있거나 이미 있는 이름이면 그대로 쓸 수 없다.
  Future<String?> validateName(String name, {String? exceptId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '폴더 이름을 입력하세요.';
    final same = await (_db.select(
      _db.folders,
    )..where((f) => f.name.equals(trimmed))).get();
    if (same.any((f) => f.id != exceptId)) return '같은 이름의 폴더가 있습니다.';
    return null;
  }

  Future<Folder> create(String name) async {
    final folder = Folder(
      id: _uuid.v4(),
      name: name.trim(),
      isSystem: false,
      createdAt: _clock(),
    );
    await _db.into(_db.folders).insert(folder);
    return folder;
  }

  Future<void> rename(String id, String name) async {
    if (SystemFolders.all.contains(id)) return;
    await (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(
      FoldersCompanion(name: Value(name.trim())),
    );
  }

  /// 폴더를 지운다. 안의 메모는 `최근 삭제된 항목`으로 옮긴다. (F1F-3)
  Future<void> delete(String id) async {
    if (SystemFolders.all.contains(id)) return;
    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((n) => n.folderId.equals(id))).write(
        NotesCompanion(
          folderId: const Value(SystemFolders.trash),
          previousFolderId: Value(id),
          deletedAt: Value(_clock()),
        ),
      );
      await (_db.delete(_db.folders)..where((f) => f.id.equals(id))).go();
    });
  }
}
