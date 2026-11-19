import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/editor/hidden_ranges.dart';
import 'package:private_memo/editor/private_text_controller.dart';

const r = HiddenRange.new;

void userSet(PrivateTextController c, String text, int cursor) {
  c.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor),
  );
}

void userSelect(PrivateTextController c, int base, [int? extent]) {
  c.value = c.value.copyWith(
    selection: TextSelection(baseOffset: base, extentOffset: extent ?? base),
  );
}

void main() {
  const text = 'w0 w1 w2 w3 w4 w5 w6';
  //            0  3  6  9  12 15 18

  PrivateTextController make({List<HiddenRange> hidden = const []}) =>
      PrivateTextController(text: text, hidden: hidden, privateMode: true);

  test('드래그로 가린 어절도 현재·앞뒤 어절이면 보인다 (F2-9)', () {
    final c = make(hidden: [r(18, 20), r(15, 17), r(12, 14), r(0, 2)]);
    userSelect(c, 20);
    expect(c.isBoxed(r(18, 20)), isFalse); // 현재
    expect(c.isBoxed(r(15, 17)), isFalse); // 바로 앞
    expect(c.isBoxed(r(12, 14)), isTrue); // 두 번째 앞은 박스
    expect(c.isBoxed(r(0, 2)), isTrue);
  });

  test('클릭·터치로는 커서와 현재 어절이 바뀌지 않는다 (F2-10)', () {
    final c = make();
    userSelect(c, 20);
    userSelect(c, 4); // w1 가운데 클릭
    expect(c.selection.baseOffset, 20);
    expect(c.isBoxed(r(3, 5)), isTrue);
    userSelect(c, 2); // 어절 사이 공백 클릭
    expect(c.selection.baseOffset, 20);
  });

  test('현재 어절 안에서는 커서를 옮길 수 있다', () {
    final c = make();
    userSelect(c, 19);
    expect(c.selection.baseOffset, 19);
    expect(c.anchor, 19);
  });

  test('범위 선택(길게 누르기)은 되고, 현재 어절은 바뀌지 않는다', () {
    final c = make();
    userSelect(c, 3, 5);
    expect(c.isBoxed(r(3, 5)), isTrue);
    expect(c.boxesForMenu(), [r(3, 5)]);
    userSelect(c, 4); // 선택 해제 → 원래 자리로
    expect(c.selection.baseOffset, 20);
  });

  test('수정으로 현재 어절을 바꾸고, ✕로 원래 자리로 돌아간다', () {
    final c = make();
    c.startEditing([r(3, 5)]);
    expect(c.selection.baseOffset, 5);
    expect(c.isBoxed(r(3, 5)), isFalse);
    userSet(c, 'w0 w1x w2 w3 w4 w5 w6', 6);
    c.stopEditing();
    expect(c.selection.baseOffset, 21); // 원래 끝(20) + 1글자
    expect(c.isBoxed(r(3, 6)), isTrue);
  });

  test('최근: 마지막으로 고친 곳으로, 마지막: 마지막 어절로 (F2-6, F2-7)', () {
    final c = make();
    userSelect(c, 5);
    userSet(c, 'w0 w1x w2 w3 w4 w5 w6', 6); // w1 뒤에 x
    userSelect(c, 0);
    c.jumpToRecent();
    expect(c.selection.baseOffset, 6);
    expect(c.anchor, 6);
    c.jumpToLast();
    expect(c.selection.baseOffset, 21);
  });

  test('마지막: 끝에 공백·줄바꿈이 있어도 마지막 어절 끝으로', () {
    final c = PrivateTextController(text: 'a b\n\n', privateMode: true);
    c.jumpToLast();
    expect(c.selection.baseOffset, 3);
  });

  test('가리지 않은 어절을 수정해도 새 글자는 가려지지 않는다', () {
    final c = make();
    userSelect(c, 20);
    c.startEditing([r(3, 5)]);
    userSet(c, 'w0 w1x w2 w3 w4 w5 w6', 6);
    expect(c.hidden, isEmpty);
    expect(c.editingRange, r(3, 6));
  });

  test('프라이빗 모드 끄면 일반 모드 표시로 돌아간다', () {
    final c = make(hidden: [r(0, 2)]);
    userSelect(c, 20);
    expect(c.isBoxed(r(3, 5)), isTrue);
    c.privateMode = false;
    expect(c.isBoxed(r(3, 5)), isFalse);
    expect(c.isBoxed(r(0, 2)), isTrue);
  });

  test('화살표로 현재 어절을 앞뒤로 옮긴다 (F2-11)', () {
    final c = make(); // 커서는 끝(w6)
    expect(c.canMoveCurrentWordForward, isFalse);
    c.moveCurrentWord(-1);
    expect(c.currentWord, r(15, 17)); // w5
    expect(c.isBoxed(r(15, 17)), isFalse);
    expect(c.isBoxed(r(18, 20)), isFalse); // 바로 뒤 어절은 회색으로 보임
    expect(c.isBoxed(r(9, 11)), isTrue);
    c.moveCurrentWord(1);
    expect(c.currentWord, r(18, 20));
    for (var i = 0; i < 10; i++) {
      c.moveCurrentWord(-1);
    }
    expect(c.currentWord, r(0, 2));
    expect(c.canMoveCurrentWordBack, isFalse);
  });
}
