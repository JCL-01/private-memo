import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/data/database.dart';

void main() {
  test('1 → 2 버전: 기존 메모는 메모 폴더로, 기본 폴더가 생긴다', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE notes (
              id TEXT NOT NULL PRIMARY KEY,
              content TEXT NOT NULL DEFAULT '',
              private_mode INTEGER NOT NULL DEFAULT 0,
              hidden_ranges TEXT NOT NULL DEFAULT '[]',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
          ''');
          raw.execute(
            "INSERT INTO notes (id, content, created_at, updated_at) "
            "VALUES ('a', '예전 메모', 0, 0);",
          );
          raw.execute('PRAGMA user_version = 1;');
        },
      ),
    );
    final notes = await db.select(db.notes).get();
    expect(notes.single.content, '예전 메모');
    expect(notes.single.folderId, SystemFolders.notes);
    final folders = await db.select(db.folders).get();
    expect(folders.map((f) => f.id).toSet(), SystemFolders.all);
    await db.close();
  });
}
