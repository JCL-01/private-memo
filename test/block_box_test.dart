import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:private_memo/organize/block_box.dart';
import 'package:private_memo/organize/note_blocks.dart';

void main() {
  Widget host(NoteBlock block, {VoidCallback? toggle, double height = 2000}) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                BlockBox(
                  block: block,
                  onSelect: () {},
                  onCut: () {},
                  onCopy: () {},
                  onToggleReveal: toggle,
                ),
                SizedBox(height: height),
              ],
            ),
          ),
        ),
      );

  testWidgets('가린 정리본은 해제 버튼이 있고, 글자 대신 박스로 보인다 (F8-2f)', (tester) async {
    await tester.pumpWidget(
      host(
        const NoteBlock(
          kind: BlockKind.organized,
          text: '비밀 할 일',
          isPrivate: true,
        ),
        toggle: () {},
      ),
    );
    expect(find.text('해제'), findsOneWidget);
    final rich = tester.widget<Text>(find.byKey(const Key('blockText-정리본')));
    expect(rich.textSpan!.toPlainText(), isNot(contains('비밀')));
  });

  testWidgets('해제된 정리본은 가리기 버튼', (tester) async {
    await tester.pumpWidget(
      host(
        const NoteBlock(
          kind: BlockKind.organized,
          text: '비밀 할 일',
          isPrivate: true,
          revealed: true,
        ),
        toggle: () {},
      ),
    );
    expect(find.text('가리기'), findsOneWidget);
    final rich = tester.widget<Text>(find.byKey(const Key('blockText-정리본')));
    expect(rich.textSpan!.toPlainText(), contains('비밀 할 일'));
  });

  testWidgets('상단 바가 화면 위로 사라지면 바가 박스 아래로 내려온다 (F8-2c)', (tester) async {
    final longText = List.generate(80, (i) => '줄 $i').join('\n');
    await tester.pumpWidget(
      host(NoteBlock(kind: BlockKind.original, text: longText)),
    );
    await tester.pump();
    expect(find.byKey(const Key('blockBar-원본')), findsOneWidget);
    expect(find.byKey(const Key('blockBarBottom-원본')), findsNothing);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('blockBar-원본')), findsNothing);
    expect(find.byKey(const Key('blockBarBottom-원본')), findsOneWidget);
  });

  testWidgets('바가 조금이라도 잘리면 바로 아래로 옮기고, 다 보이면 위에 둔다', (tester) async {
    final longText = List.generate(80, (i) => '줄 \$i').join('\n');
    await tester.pumpWidget(
      host(NoteBlock(kind: BlockKind.original, text: longText)),
    );
    await tester.pump();
    final scroll = find.byType(SingleChildScrollView);

    // 바깥 여백(8)만큼은 올려도 바는 다 보인다 → 위에 그대로
    await tester.drag(scroll, const Offset(0, -6));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('blockBar-원본')), findsOneWidget);

    // 바가 4px 잘리면 → 아래로
    await tester.drag(scroll, const Offset(0, -6));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('blockBarBottom-원본')), findsOneWidget);

    // 다시 내리면 → 위로
    await tester.drag(scroll, const Offset(0, 20));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('blockBar-원본')), findsOneWidget);
  });
}
