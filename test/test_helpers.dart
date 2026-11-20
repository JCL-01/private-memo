import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 프라이빗 입력창은 EditableText를 상속한 위젯이라 `find.byType(EditableText)`로는 안 찾힌다.
final Finder editableFinder = find.byWidgetPredicate((w) => w is EditableText);

/// 프라이빗 입력창에 키보드를 연결한다(`tester.showKeyboard` 대신).
Future<void> showPrivateKeyboard(WidgetTester tester) async {
  final state = tester.state<EditableTextState>(editableFinder);
  tester.binding.focusedEditable = state;
  await tester.pump();
}

/// 프라이빗 입력창에 글자를 넣는다(`tester.enterText` 대신).
Future<void> enterPrivateText(WidgetTester tester, String text) async {
  await showPrivateKeyboard(tester);
  tester.testTextInput.enterText(text);
  await tester.pump();
}
