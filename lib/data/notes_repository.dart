import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

class NotesRepository {
  NotesRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  /// 삭제 후 영구 삭제까지 기간. (F1F-5)
  static const trashRetention = Duration(days: 30);

  /// [folderId] 폴더의 메모. 최근 수정한 메모가 위에 온다.
  /// `최근 삭제된 항목`은 최근에 삭제한 메모가 위에 온다.
  Stream<List<Note>> watchFolder(String folderId) {
    return (_db.select(_db.notes)
          ..where((n) => n.folderId.equals(folderId))
          ..orderBy([
            folderId == SystemFolders.trash
                ? (n) => OrderingTerm.desc(n.deletedAt)
                : (n) => OrderingTerm.desc(n.updatedAt),
          ]))
        .watch();
  }

  /// 폴더별 메모 개수.
  Stream<Map<String, int>> watchCounts() {
    final count = _db.notes.id.count();
    final query = _db.selectOnly(_db.notes)
      ..addColumns([_db.notes.folderId, count])
      ..groupBy([_db.notes.folderId]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.read(_db.notes.folderId)!: row.read(count) ?? 0,
      },
    );
  }

  Future<Note?> getById(String id) {
    return (_db.select(
      _db.notes,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  /// [folderId] 폴더에 새 메모를 만든다.
  Future<Note> create({String folderId = SystemFolders.notes}) async {
    final now = _clock();
    final note = Note(
      id: _uuid.v4(),
      content: '',
      privateMode: false,
      hiddenRanges: '[]',
      createdAt: now,
      updatedAt: now,
      folderId: folderId == SystemFolders.trash
          ? SystemFolders.notes
          : folderId,
    );
    await _db.into(_db.notes).insert(note);
    return note;
  }

  /// 본문과 가린 범위(JSON)를 저장한다. [hiddenRanges]를 생략하면 본문만 바꾼다.
  Future<void> updateContent(
    String id,
    String content, {
    String? hiddenRanges,
  }) {
    return (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        content: Value(content),
        hiddenRanges: hiddenRanges == null
            ? const Value.absent()
            : Value(hiddenRanges),
        updatedAt: Value(_clock()),
      ),
    );
  }

  /// 프라이빗 모드 켜짐 여부를 저장한다. 수정 시각은 바꾸지 않는다. (F2-8)
  Future<void> setPrivateMode(String id, bool on) {
    return (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(privateMode: Value(on)),
    );
  }

  /// 메모를 `최근 삭제된 항목`으로 옮긴다. (F1F-5)
  Future<void> moveToTrash(String id) async {
    final note = await getById(id);
    if (note == null || note.folderId == SystemFolders.trash) return;
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        folderId: const Value(SystemFolders.trash),
        previousFolderId: Value(note.folderId),
        deletedAt: Value(_clock()),
      ),
    );
  }

  /// `최근 삭제된 항목`의 메모를 원래 폴더로 되돌린다.
  /// 원래 폴더가 없어졌으면 `메모` 폴더로. (F1F-6)
  Future<void> restore(String id) async {
    final note = await getById(id);
    if (note == null || note.folderId != SystemFolders.trash) return;
    var target = note.previousFolderId ?? SystemFolders.notes;
    final exists = await (_db.select(
      _db.folders,
    )..where((f) => f.id.equals(target))).getSingleOrNull();
    if (exists == null || target == SystemFolders.trash) {
      target = SystemFolders.notes;
    }
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        folderId: Value(target),
        previousFolderId: const Value(null),
        deletedAt: const Value(null),
      ),
    );
  }

  /// 메모를 다른 폴더로 옮긴다. (F1F-4)
  Future<void> moveTo(String id, String folderId) async {
    if (folderId == SystemFolders.trash) return moveToTrash(id);
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(folderId: Value(folderId)),
    );
  }

  /// 삭제한 지 30일이 지난 메모를 영구 삭제한다. 앱을 켤 때 부른다. (F1F-5)
  Future<int> purgeExpired() {
    final limit = _clock().subtract(trashRetention);
    return (_db.delete(_db.notes)..where(
          (n) =>
              n.folderId.equals(SystemFolders.trash) &
              n.deletedAt.isSmallerThanValue(limit),
        ))
        .go();
  }

  /// 메모를 바로 영구 삭제한다(빈 새 메모 정리, 최근 삭제된 항목에서 영구 삭제).
  Future<void> delete(String id) {
    return (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();
  }
}
