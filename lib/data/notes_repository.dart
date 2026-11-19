import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

class NotesRepository {
  NotesRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  /// 최근 수정한 메모가 위에 오도록 정렬한 목록.
  Stream<List<Note>> watchAll() {
    return (_db.select(
      _db.notes,
    )..orderBy([(n) => OrderingTerm.desc(n.updatedAt)])).watch();
  }

  Future<Note?> getById(String id) {
    return (_db.select(
      _db.notes,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  Future<Note> create() async {
    final now = _clock();
    final note = Note(
      id: _uuid.v4(),
      content: '',
      privateMode: false,
      hiddenRanges: '[]',
      createdAt: now,
      updatedAt: now,
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

  Future<void> delete(String id) {
    return (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();
  }
}
