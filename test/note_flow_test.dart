import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

import 'package:material_ui/material_ui.dart';
import 'package:private_memo/app/app.dart';
import 'package:private_memo/data/database.dart';
import 'package:private_memo/data/providers.dart';

void main() {
  late AppDatabase db;

  setUp(
    () => db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    ),
  );
  tearDown(() => db.close());

  /// DB 작업(실제 비동기)과 화면 전환(가짜 시간)을 번갈아 진행시킨다.
  /// 로딩 스피너가 계속 돌기 때문에 pumpAndSettle 대신 사용한다.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const PrivateMemoApp(),
      ),
    );
    await settle(tester);
    // 첫 화면은 폴더 목록. `메모` 폴더로 들어간다.
    await tester.tap(find.byKey(const Key('folder-notes')));
    await settle(tester);
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.pageBack();
    await settle(tester);
  }

  testWidgets('새 메모를 쓰면 목록에 제목이 보인다', (tester) async {
    await pumpApp(tester);
    expect(find.text('메모 없음'), findsWidgets);

    await tester.tap(find.byKey(const Key('newNoteButton')));
    await settle(tester);
    await enterPrivateText(tester, '비밀 계획\n내일 실행');
    await goBack(tester);

    expect(find.text('비밀 계획'), findsOneWidget);
    expect(find.textContaining('내일 실행'), findsOneWidget);
    expect(find.text('1개의 메모'), findsOneWidget);
  });

  testWidgets('아무것도 쓰지 않은 새 메모는 남지 않는다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('newNoteButton')));
    await settle(tester);
    await goBack(tester);

    expect(find.text('1개의 메모'), findsNothing);
  });

  testWidgets('편집 화면의 삭제 버튼으로 메모를 지운다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('newNoteButton')));
    await settle(tester);
    await enterPrivateText(tester, '지울 메모');
    await tester.tap(find.byKey(const Key('deleteNoteButton')));
    await settle(tester);

    expect(find.text('지울 메모'), findsNothing);
  });

  testWidgets('우클릭 메뉴로 목록에서 메모를 지운다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('newNoteButton')));
    await settle(tester);
    await enterPrivateText(tester, '우클릭 삭제');
    await goBack(tester);

    await tester.tap(find.text('우클릭 삭제'), buttons: kSecondaryButton);
    await settle(tester);
    await tester.tap(find.text('삭제'));
    await settle(tester);

    expect(find.text('우클릭 삭제'), findsNothing);

    // 최근 삭제된 항목으로 갔다가 복구 (F1F-5, F1F-6)
    await goBack(tester);
    await tester.tap(find.byKey(const Key('folder-trash')));
    await settle(tester);
    expect(find.text('우클릭 삭제'), findsOneWidget);
    expect(find.textContaining('30일 후 영구 삭제'), findsOneWidget);
    await tester.tap(find.text('우클릭 삭제'), buttons: kSecondaryButton);
    await settle(tester);
    await tester.tap(find.text('복구'));
    await settle(tester);
    expect(find.text('우클릭 삭제'), findsNothing);
    await goBack(tester);
    await tester.tap(find.byKey(const Key('folder-notes')));
    await settle(tester);
    expect(find.text('우클릭 삭제'), findsOneWidget);
  });

  testWidgets('폴더를 만들고 메모를 그 폴더로 옮긴다 (F1F-3, F1F-4)', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('newNoteButton')));
    await settle(tester);
    await enterPrivateText(tester, '옮길 메모');
    await goBack(tester);
    await goBack(tester);

    await tester.tap(find.byKey(const Key('newFolderButton')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('folderNameField')), '회의');
    await tester.tap(find.byKey(const Key('folderNameSave')));
    await settle(tester);
    expect(find.text('회의'), findsOneWidget);

    await tester.tap(find.byKey(const Key('folder-notes')));
    await settle(tester);
    await tester.tap(find.text('옮길 메모'), buttons: kSecondaryButton);
    await settle(tester);
    await tester.tap(find.text('폴더로 이동'));
    await settle(tester);
    await tester.tap(find.text('회의').last);
    await settle(tester);
    expect(find.text('옮길 메모'), findsNothing);

    await goBack(tester);
    await tester.tap(find.text('회의'));
    await settle(tester);
    expect(find.text('옮길 메모'), findsOneWidget);
  });

  testWidgets('프라이빗 버튼으로 켜고 해제로 끄며, 상태가 저장된다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('newNoteButton')));
    await settle(tester);
    await enterPrivateText(tester, '하나 둘 셋 넷 다섯');
    expect(find.byKey(const Key('privateModeBar')), findsNothing);

    await tester.tap(find.text('프라이빗'));
    await settle(tester);
    expect(find.byKey(const Key('privateModeBar')), findsOneWidget);
    expect(find.text('최근'), findsOneWidget);
    expect(find.text('마지막'), findsOneWidget);
    expect(find.text('해제'), findsOneWidget);
    expect(find.byKey(const Key('prevWordButton')), findsOneWidget);
    expect(find.byKey(const Key('nextWordButton')), findsOneWidget);

    await goBack(tester);
    final saved = await tester.runAsync(() => db.select(db.notes).getSingle());
    expect(saved!.privateMode, isTrue);

    await tester.tap(find.text('하나 둘 셋 넷 다섯'));
    await settle(tester);
    expect(find.byKey(const Key('privateModeBar')), findsOneWidget);
    await tester.tap(find.text('해제'));
    await settle(tester);
    expect(find.byKey(const Key('privateModeBar')), findsNothing);
  });
}
