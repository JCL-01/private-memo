import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/data/database.dart';
import 'package:private_memo/data/note.dart';
import 'package:private_memo/data/folders_repository.dart';
import 'package:private_memo/data/notes_repository.dart';
import 'package:private_memo/editor/hidden_ranges.dart';

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

    final list = await repo.watchFolder(SystemFolders.notes).first;
    expect(list.map((n) => n.id), [a.id, b.id]);
  });

  test('영구 삭제하면 목록에서 사라진다', () async {
    final note = await repo.create();
    await repo.delete(note.id);
    expect(await repo.watchFolder(SystemFolders.notes).first, isEmpty);
  });

  test('제목과 미리보기는 비어 있지 않은 첫째·둘째 줄이다', () async {
    final note = await repo.create();
    await repo.updateContent(note.id, '\n  장보기 \n\n우유, 계란\n빵');
    final loaded = (await repo.getById(note.id))!;
    expect(loaded.title, '장보기');
    expect(loaded.preview, '우유, 계란');
  });

  test('가린 범위를 저장하고, 목록 제목 줄 기준으로 계산한다', () async {
    final note = await repo.create();
    // '  비밀 제목' 의 '비밀' → 본문 [2,4)
    await repo.updateContent(
      note.id,
      '  비밀 제목\n둘째',
      hiddenRanges: encodeRanges(const [HiddenRange(2, 4)]),
    );
    final loaded = (await repo.getById(note.id))!;
    expect(loaded.hidden, const [HiddenRange(2, 4)]);
    expect(loaded.titleLine!.text, '비밀 제목');
    expect(loaded.titleLine!.hiddenIn(loaded.hidden), const [
      HiddenRange(0, 2),
    ]);
    expect(loaded.previewLine!.hiddenIn(loaded.hidden), isEmpty);
  });

  group('폴더·최근 삭제된 항목 (F1F)', () {
    late FoldersRepository folders;
    setUp(() => folders = FoldersRepository(db, clock: () => now));

    test('기본 폴더 3개가 있다', () async {
      final list = await folders.watchAll().first;
      expect(list.map((f) => f.name), ['메모', '빠른 메모', '최근 삭제된 항목']);
    });

    test('삭제하면 최근 삭제된 항목으로, 복구하면 원래 폴더로', () async {
      final note = await repo.create(folderId: SystemFolders.quick);
      await repo.moveToTrash(note.id);
      expect(await repo.watchFolder(SystemFolders.trash).first, hasLength(1));
      await repo.restore(note.id);
      final restored = (await repo.getById(note.id))!;
      expect(restored.folderId, SystemFolders.quick);
      expect(restored.deletedAt, isNull);
    });

    test('30일이 지나면 영구 삭제된다', () async {
      final a = await repo.create();
      final b = await repo.create();
      await repo.moveToTrash(a.id);
      now = now.add(const Duration(days: 10));
      await repo.moveToTrash(b.id);
      now = now.add(const Duration(days: 21)); // a는 31일, b는 21일
      expect(await repo.purgeExpired(), 1);
      expect(await repo.getById(a.id), isNull);
      expect(await repo.getById(b.id), isNotNull);
    });

    test('폴더를 지우면 메모는 최근 삭제된 항목으로, 복구하면 메모 폴더로', () async {
      final folder = await folders.create('회의');
      final note = await repo.create(folderId: folder.id);
      await folders.delete(folder.id);
      expect((await repo.getById(note.id))!.folderId, SystemFolders.trash);
      await repo.restore(note.id);
      expect((await repo.getById(note.id))!.folderId, SystemFolders.notes);
    });

    test('같은 이름의 폴더는 만들 수 없고, 기본 폴더는 지울 수 없다', () async {
      await folders.create('회의');
      expect(await folders.validateName('회의'), isNotNull);
      expect(await folders.validateName('  '), isNotNull);
      await folders.delete(SystemFolders.notes);
      expect(await folders.getById(SystemFolders.notes), isNotNull);
    });

    test('폴더 이동', () async {
      final folder = await folders.create('회의');
      final note = await repo.create();
      await repo.moveTo(note.id, folder.id);
      expect((await repo.getById(note.id))!.folderId, folder.id);
    });
  });
}
