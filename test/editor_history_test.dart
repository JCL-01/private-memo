import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/editor/editor_history.dart';
import 'package:private_memo/editor/hidden_ranges.dart';

EditorSnapshot snap(String text) => EditorSnapshot(
  text,
  TextSelection.collapsed(offset: text.length),
  const [],
);

void main() {
  test('어절 단위로 묶어서 되돌린다 (F5-5)', () {
    final h = EditorHistory();
    var text = '';
    for (final ch in '안녕 하세요'.split('')) {
      final edit = TextEdit(text.length, 0, ch);
      h.recordEdit(snap(text), edit);
      text += ch;
    }
    // '안녕 ' / '하세요' 두 묶음
    final first = h.undo(snap(text))!;
    expect(first.text, '안녕 ');
    final second = h.undo(snap(first.text))!;
    expect(second.text, '');
    expect(h.canUndo, isFalse);
  });

  test('한글 조합 중 글자 바꿈은 같은 묶음이다', () {
    final h = EditorHistory();
    h.recordEdit(snap(''), const TextEdit(0, 0, 'ㄱ'));
    h.recordEdit(snap('ㄱ'), const TextEdit(0, 1, '가'));
    h.recordEdit(snap('가'), const TextEdit(0, 1, '각'));
    expect(h.undo(snap('각'))!.text, '');
  });

  test('되돌린 뒤 새로 편집하면 다시 실행 기록이 사라진다 (F5-6)', () {
    final h = EditorHistory();
    h.recordEdit(snap(''), const TextEdit(0, 0, 'a'));
    h.undo(snap('a'));
    expect(h.canRedo, isTrue);
    h.recordEdit(snap(''), const TextEdit(0, 0, 'b'));
    expect(h.canRedo, isFalse);
  });
}
