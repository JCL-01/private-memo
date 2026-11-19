import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:private_memo/editor/edit_navigator_bar.dart';
import 'package:private_memo/editor/hidden_ranges.dart';
import 'package:private_memo/editor/private_editor.dart';
import 'package:private_memo/editor/private_text_controller.dart';

const r = HiddenRange.new;

void main() {
  late PrivateTextController c;

  Future<void> pumpEditor(WidgetTester tester) async {
    c = PrivateTextController(text: '오늘 비밀 회의', hidden: [r(3, 5)]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PrivateEditor(controller: c)),
      ),
    );
    await tester.pump();
  }

  /// 본문 [offset] 글자의 화면 위치(가운데).
  Offset charCenter(WidgetTester tester, int offset) {
    final state = tester.state<EditableTextState>(find.byType(EditableText));
    final box = state.renderEditable;
    final a = box.getLocalRectForCaret(TextPosition(offset: offset));
    final b = box.getLocalRectForCaret(TextPosition(offset: offset + 1));
    return box.localToGlobal(Offset((a.left + b.left) / 2, a.center.dy));
  }

  testWidgets('박스를 길게 누르면 수정/보기 메뉴, 보기를 고르면 박스가 풀린다', (tester) async {
    await pumpEditor(tester);
    await tester.longPressAt(charCenter(tester, 3));
    await tester.pumpAndSettle();

    expect(find.text('수정'), findsOneWidget);
    expect(find.text('보기'), findsOneWidget);
    expect(find.text('프라이빗'), findsNothing);

    await tester.tap(find.text('보기'));
    await tester.pumpAndSettle();
    expect(c.revealedRanges, {r(3, 5)});

    // 화면을 누르고 있는 동안에는 열려 있고, 손을 떼면 다시 가려진다 (F4-4)
    final gesture = await tester.startGesture(charCenter(tester, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.revealedRanges, {r(3, 5)});
    await gesture.up();
    await tester.pump();
    expect(c.revealedRanges, isEmpty);
  });

  testWidgets('박스 수정 메뉴', (tester) async {
    await pumpEditor(tester);
    await tester.longPressAt(charCenter(tester, 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();
    expect(c.editingRange, r(3, 5));
  });

  testWidgets('일반 어절을 길게 눌러 선택하면 프라이빗 메뉴가 나온다', (tester) async {
    await pumpEditor(tester);
    await tester.longPressAt(charCenter(tester, 6));
    await tester.pumpAndSettle();

    expect(find.text('프라이빗'), findsOneWidget);
    await tester.tap(find.text('프라이빗'));
    await tester.pumpAndSettle();
    expect(c.hidden, [r(3, 5), r(6, 8)]);
  });

  testWidgets('Ctrl+Z / Ctrl+Y 로 프라이빗 적용을 되돌리고 다시 실행한다', (tester) async {
    await pumpEditor(tester);
    await tester.showKeyboard(find.byType(TextField));
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    c.hideSelection();
    await tester.pump();
    expect(c.hidden, [r(0, 2), r(3, 5)]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(c.hidden, [r(3, 5)]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(c.hidden, [r(0, 2), r(3, 5)]);
  });

  testWidgets('박스 글자는 투명하게 그리고, 수정 중인 어절은 파란색', (tester) async {
    await pumpEditor(tester);
    TextSpan build() => c.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      withComposing: false,
    );
    var spans = build().children!.cast<TextSpan>();
    final boxed = spans.where((s) => s.style?.color?.a == 0).toList();
    expect(boxed.map((s) => s.text), ['비밀']);
    expect(c.boxes, [r(3, 5)]);

    c.startEditing([r(3, 5)]);
    spans = build().children!.cast<TextSpan>();
    final blue = spans.firstWhere((s) => s.text == '비밀');
    expect(blue.style!.color!.b, greaterThan(blue.style!.color!.r));
  });

  testWidgets('윈도우: 박스 우클릭 → 수정/보기, 박스 클릭 → 박스 앞/뒤에 커서', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpEditor(tester);
      await tester.tapAt(charCenter(tester, 4), kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 500));
      expect([3, 5], contains(c.selection.baseOffset));

      await tester.tapAt(
        charCenter(tester, 3),
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(find.text('수정'), findsOneWidget);
      expect(find.text('보기'), findsOneWidget);
      expect(find.text('해제'), findsOneWidget);
      await tester.tap(find.text('보기'));
      await tester.pumpAndSettle();
      expect(c.revealedRanges, {r(3, 5)});
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('일반 어절과 박스가 섞인 선택: 수정·보기·해제·프라이빗 + 기본 메뉴', (tester) async {
    await pumpEditor(tester);
    await tester.showKeyboard(find.byType(TextField));
    final state = tester.state<EditableTextState>(find.byType(EditableText));
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();
    state.showToolbar();
    await tester.pumpAndSettle();
    expect(find.text('수정'), findsOneWidget);
    // 안드로이드 툴바는 칸이 모자라면 나머지를 ⋮ 더보기로 보낸다.
    final more = find.byType(IconButton);
    if (more.evaluate().isNotEmpty) {
      await tester.tap(more.last);
      await tester.pumpAndSettle();
    }
    for (final label in ['보기', '해제', '프라이빗', 'Copy']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    await tester.tap(find.text('해제'));
    await tester.pumpAndSettle();
    expect(c.hidden, isEmpty);
  });

  testWidgets('프라이빗 모드: 박스를 길게 눌러도 드러나지 않고, 수정·보기만 뜬다', (tester) async {
    c = PrivateTextController(text: '하나 둘 셋 넷 다섯 여섯', privateMode: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PrivateEditor(controller: c)),
      ),
    );
    await tester.pump();
    // 커서가 끝(여섯)에 있으므로 '하나'는 박스
    expect(c.isBoxed(r(0, 2)), isTrue);

    await tester.longPressAt(charCenter(tester, 0));
    await tester.pumpAndSettle();
    expect(c.isBoxed(r(0, 2)), isTrue, reason: '길게 눌러 선택해도 박스 유지');
    expect(find.text('수정'), findsOneWidget);
    expect(find.text('보기'), findsOneWidget);
    expect(find.text('해제'), findsNothing);
    expect(find.text('프라이빗'), findsNothing);

    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();
    expect(c.editingRange, r(0, 2));
    expect(c.isBoxed(r(0, 2)), isFalse);
  });

  testWidgets('수정 모드 바: 수정 완료를 누르면 바가 사라진다 (F4-2b)', (tester) async {
    c = PrivateTextController(text: 'a b c', hidden: [r(0, 1), r(4, 5)]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(child: PrivateEditor(controller: c)),
              EditNavigatorBar(controller: c),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('editNavigatorBar')), findsNothing);

    c.startEditing([r(0, 1), r(4, 5)]);
    await tester.pump();
    expect(find.text('수정 완료'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);

    await tester.tap(find.byKey(const Key('editDoneButton')));
    await tester.pump();
    expect(c.isEditingBox, isFalse);
    expect(find.byKey(const Key('editNavigatorBar')), findsNothing);
  });

  testWidgets('Esc 키로 수정 모드에서 빠져나온다', (tester) async {
    await pumpEditor(tester);
    await tester.showKeyboard(find.byType(TextField));
    c.startEditing([r(3, 5)]);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(c.isEditingBox, isFalse);
  });
}
