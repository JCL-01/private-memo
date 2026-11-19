import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/data/database.dart';
import 'package:private_memo/data/note.dart';
import 'package:private_memo/data/notes_repository.dart';

void main() {
  late AppDatabase db;
  late NotesRepository repo;
  var now = DateTime(2026, 11, 19, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = NotesRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('생성한 메모는 비어 있고 일반 모드다', () async {
    final note = await repo.create();
    final loaded = await repo.getById(note.id);
    expect(loaded!.content, '');
    expect(loaded.privateMode, isFalse);
    expect(loaded.hiddenRanges, '[]');
  });

  test('목록은 최근 수정 순으로 정렬된다', () async {
    final a = await repo.create();
    now = now.add(const Duration(minutes: 1));
    final b = await repo.create();
    now = now.add(const Duration(minutes: 1));
    await repo.updateContent(a.id, '나중에 수정');

    final list = await repo.watchAll().first;
    expect(list.map((n) => n.id), [a.id, b.id]);
  });

  test('삭제하면 목록에서 사라진다', () async {
    final note = await repo.create();
    await repo.delete(note.id);
    expect(await repo.watchAll().first, isEmpty);
  });

  test('제목과 미리보기는 비어 있지 않은 첫째·둘째 줄이다', () async {
    final note = await repo.create();
    await repo.updateContent(note.id, '\n  장보기 \n\n우유, 계란\n빵');
    final loaded = (await repo.getById(note.id))!;
    expect(loaded.title, '장보기');
    expect(loaded.preview, '우유, 계란');
  });
}
