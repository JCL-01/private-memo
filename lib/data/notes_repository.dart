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

  Future<void> updateContent(String id, String content) {
    return (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(content: Value(content), updatedAt: Value(_clock())),
    );
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();
  }
}
