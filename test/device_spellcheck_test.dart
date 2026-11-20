import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:private_memo/editor/hidden_ranges.dart';
import 'package:private_memo/editor/private_editor.dart';
import 'package:private_memo/editor/private_field.dart';
import 'package:private_memo/editor/private_text_controller.dart';

import 'test_helpers.dart';

const r = HiddenRange.new;

/// 기기 맞춤법 검사를 흉내 낸다: '나왓다' → ['나왔다'].
class FakeDeviceSpellCheck implements SpellCheckService {
  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
    Locale locale,
    String text,
  ) async {
    final spans = <SuggestionSpan>[];
    var i = text.indexOf('나왓다');
    while (i >= 0) {
      spans.add(SuggestionSpan(TextRange(start: i, end: i + 3), ['나왔다']));
      i = text.indexOf('나왓다', i + 1);
    }
    return spans;
  }
}

void main() {
  group('deviceMisspelledRanges', () {
    test('검사한 글자와 지금 글자가 같으면 그대로', () {
      final results = SpellCheckResults('a 나왓다', const [
        SuggestionSpan(TextRange(start: 2, end: 5), ['나왔다']),
      ]);
      expect(deviceMisspelledRanges(results, 'a 나왓다'), [r(2, 5)]);
    });

    test('검사 뒤 글자가 바뀌었으면 같은 자리에 같은 단어가 남은 것만', () {
      final results = SpellCheckResults('a 나왓다 됬다', const [
        SuggestionSpan(TextRange(start: 2, end: 5), ['나왔다']),
        SuggestionSpan(TextRange(start: 6, end: 8), ['됐다']),
      ]);
      expect(deviceMisspelledRanges(results, 'a 나왓다 됐다'), [r(2, 5)]);
    });
  });

  test('박스 글자에도 기기 맞춤법 밑줄이 그려진다(박스가 밑줄을 가리지 않음)', () {
    final c = PrivateTextController(text: '오늘 나왓다', hidden: [r(3, 6)]);
    c.updateDeviceMisspelled([r(3, 6)]);
    final spans = buildShadedSpans(
      text: c.text,
      shades: c.shades,
      palette: const ShadePalette(box: Color(0xFFCCCCCC)),
      misspelled: c.deviceMisspelled,
    ).cast<TextSpan>();
    final boxed = spans.firstWhere((s) => s.text == '나왓다');
    expect(boxed.style!.color!.a, 0); // 글자는 투명(박스)
    expect(boxed.style!.decoration, TextDecoration.underline);
    expect(boxed.style!.decorationStyle, TextDecorationStyle.wavy);
    expect(boxed.style!.decorationColor!.a, greaterThan(0));
  });

  group('밑줄 어절 누르기 (F6-4)', () {
    void userSelect(PrivateTextController c, int offset) {
      c.value = c.value.copyWith(
        selection: TextSelection.collapsed(offset: offset),
      );
    }

    test('일반 모드: 박스여도 커서가 그 자리에 머문다(대체 단어 메뉴용)', () {
      final c = PrivateTextController(text: '오늘 나왓다', hidden: [r(3, 6)]);
      c.updateDeviceMisspelled([r(3, 6)]);
      userSelect(c, 4);
      expect(c.selection.baseOffset, 4);
    });

    test('프라이빗 모드: 커서는 머물지만 현재 어절은 그대로', () {
      final c = PrivateTextController(text: '나왓다 하나 둘 셋 넷', privateMode: true);
      c.updateDeviceMisspelled([r(0, 3)]);
      userSelect(c, 1);
      expect(c.selection.baseOffset, 1);
      expect(c.anchor, c.text.length);
      expect(c.isBoxed(r(0, 3)), isTrue);
    });

    test('대체 단어로 바꾸면 가린 어절은 계속 가리고, 프라이빗 모드 현재 어절도 그대로', () {
      final c = PrivateTextController(
        text: '나왓다 하나 둘 셋 넷',
        hidden: [r(0, 3)],
        privateMode: true,
      );
      c.updateDeviceMisspelled([r(0, 3)]);
      userSelect(c, 1);
      c.value = const TextEditingValue(
        text: '나왔다 하나 둘 셋 넷',
        selection: TextSelection.collapsed(offset: 3),
      );
      expect(c.hidden, [r(0, 3)]);
      expect(c.anchor, c.text.length);
      expect(c.selection.baseOffset, c.text.length);
    });
  });

  testWidgets('안드로이드: 가린 오타를 누르면 기기 대체 단어가 뜨고, 바꿔도 가려진다', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final c = PrivateTextController(text: '오늘 나왓다', hidden: [r(3, 6)]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivateEditor(
              controller: c,
              spellCheckService: FakeDeviceSpellCheck(),
            ),
          ),
        ),
      );
      // 글자가 바뀌어야 기기 맞춤법 검사를 요청하므로 끝에 공백을 하나 넣는다.
      await enterPrivateText(tester, '오늘 나왓다 ');
      await tester.pumpAndSettle();
      expect(c.deviceMisspelled, [r(3, 6)]);
      expect(c.isBoxed(r(3, 6)), isTrue);

      final state = tester.state<EditableTextState>(editableFinder);
      final box = state.renderEditable;
      final rect = box.getLocalRectForCaret(const TextPosition(offset: 4));
      await tester.tapAt(box.localToGlobal(rect.center));
      await tester.pumpAndSettle();

      expect(find.text('나왔다'), findsOneWidget); // 대체 단어 메뉴
      await tester.tap(find.text('나왔다'));
      await tester.pumpAndSettle();

      expect(c.text, '오늘 나왔다 ');
      expect(c.hidden, [r(3, 6)]);
      expect(c.isBoxed(r(3, 6)), isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS: 가린 오타를 누르면 기기 대체 단어가 뜨고, 바꿔도 가려진다', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final c = PrivateTextController(text: '오늘 나왓다', hidden: [r(3, 6)]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivateEditor(
              controller: c,
              spellCheckService: FakeDeviceSpellCheck(),
            ),
          ),
        ),
      );
      // 글자가 바뀌어야 기기 맞춤법 검사를 요청하므로 끝에 공백을 하나 넣는다.
      await enterPrivateText(tester, '오늘 나왓다 ');
      await tester.pumpAndSettle();
      expect(c.deviceMisspelled, [r(3, 6)]);
      expect(c.isBoxed(r(3, 6)), isTrue);

      final state = tester.state<EditableTextState>(editableFinder);
      final box = state.renderEditable;
      final rect = box.getLocalRectForCaret(const TextPosition(offset: 4));
      await tester.tapAt(box.localToGlobal(rect.center));
      await tester.pumpAndSettle();

      expect(find.text('나왔다'), findsOneWidget); // 대체 단어 메뉴
      await tester.tap(find.text('나왔다'));
      await tester.pumpAndSettle();

      expect(c.text, '오늘 나왔다 ');
      expect(c.hidden, [r(3, 6)]);
      expect(c.isBoxed(r(3, 6)), isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('윈도우: 가린 오타를 우클릭하면 대체 단어가 메뉴 맨 위에 뜨고, 바꿔도 가려진다', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final c = PrivateTextController(text: '오늘 나왓다', hidden: [r(3, 6)]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivateEditor(
              controller: c,
              spellCheckService: FakeDeviceSpellCheck(),
            ),
          ),
        ),
      );
      await enterPrivateText(tester, '오늘 나왓다 ');
      await tester.pumpAndSettle();
      expect(c.deviceMisspelled, [r(3, 6)]);

      final state = tester.state<EditableTextState>(editableFinder);
      final box = state.renderEditable;
      final rect = box.getLocalRectForCaret(const TextPosition(offset: 4));
      await tester.tapAt(
        box.localToGlobal(rect.center),
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(find.text('나왔다'), findsOneWidget);
      expect(find.text('수정'), findsOneWidget); // 박스 메뉴도 함께
      await tester.tap(find.text('나왔다'));
      await tester.pumpAndSettle();

      expect(c.text, '오늘 나왔다 ');
      expect(c.hidden, [r(3, 6)]);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
