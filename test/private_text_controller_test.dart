import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/editor/hidden_ranges.dart';
import 'package:private_memo/editor/private_text_controller.dart';

const r = HiddenRange.new;

/// 사용자 입력처럼 컨트롤러 값을 바꾼다.
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
  // '오늘 비밀 회의' : '비밀' [3,5)
  PrivateTextController make() =>
      PrivateTextController(text: '오늘 비밀 회의', hidden: [r(3, 5)]);

  group('박스 짧게 누르기 (F4-6)', () {
    test('박스 안을 누르면 가까운 쪽 끝으로 커서가 간다', () {
      final c = make();
      userSelect(c, 0);
      userSelect(c, 4); // 박스 안, 뒤쪽이 가까움(4-3=1, 5-4=1 → 앞)
      expect(c.selection.baseOffset, 3);
    });

    test('방향키로 들어오면 박스를 건너뛴다', () {
      final c = make();
      userSelect(c, 3);
      userSelect(c, 4); // → 오른쪽 한 칸
      expect(c.selection.baseOffset, 5);
      userSelect(c, 4); // ← 왼쪽 한 칸
      expect(c.selection.baseOffset, 3);
    });
  });

  group('프라이빗 / 해제', () {
    test('선택한 어절을 가리고, 되돌리기로 복구한다 (F5-3)', () {
      final c = make();
      userSelect(c, 6, 8);
      c.hideSelection();
      expect(c.hidden, [r(3, 5), r(6, 8)]);
      c.undo();
      expect(c.hidden, [r(3, 5)]);
      c.redo();
      expect(c.hidden, [r(3, 5), r(6, 8)]);
    });

    test('해제', () {
      final c = make();
      userSelect(c, 0, 8);
      c.unhideSelection();
      expect(c.hidden, isEmpty);
    });
  });

  group('수정 (F4-2, F4-3)', () {
    test('수정 중에는 보이고, 커서가 벗어나면 다시 박스', () {
      final c = make();
      c.startEditing(r(3, 5));
      expect(c.isBoxed(r(3, 5)), isFalse);
      userSelect(c, 0);
      expect(c.editingRange, isNull);
      expect(c.isBoxed(r(3, 5)), isTrue);
    });

    test('수정 중 입력한 글자도 가려진 어절의 일부가 된다', () {
      final c = make();
      c.startEditing(r(3, 5));
      userSet(c, '오늘 비밀들 회의', 6);
      expect(c.hidden, [r(3, 6)]);
      expect(c.editingRange, r(3, 6));
    });

    test('수정 중 공백으로 나누면 두 어절 모두 가린다', () {
      final c = make();
      c.startEditing(r(3, 5));
      userSelect(c, 4);
      userSet(c, '오늘 비 밀 회의', 5);
      expect(c.hidden, [r(3, 4), r(5, 6)]);
    });

    test('수정이 아닐 때 박스 바로 뒤에 쓴 글자는 보인다 (F3-5)', () {
      final c = make();
      userSelect(c, 5);
      userSet(c, '오늘 비밀x 회의', 6);
      expect(c.hidden, [r(3, 5)]);
    });
  });

  group('보기 (F4-4)', () {
    test('보기로 연 박스는 다른 곳을 누르면 다시 가려진다', () {
      final c = make();
      c.reveal(r(3, 5));
      expect(c.isBoxed(r(3, 5)), isFalse);
      userSelect(c, 0);
      expect(c.isBoxed(r(3, 5)), isTrue);
    });

    test('dismissReveal', () {
      final c = make();
      c.reveal(r(3, 5));
      c.dismissReveal();
      expect(c.revealedRange, isNull);
    });

    test('보기는 되돌리기 대상이 아니다 (F5-4)', () {
      final c = make();
      c.reveal(r(3, 5));
      expect(c.canUndo, isFalse);
    });
  });

  test('되돌리기는 글자·커서·가린 범위를 함께 되돌린다', () {
    final c = make();
    userSelect(c, 0);
    userSet(c, 'X오늘 비밀 회의', 1);
    expect(c.hidden, [r(4, 6)]);
    c.undo();
    expect(c.text, '오늘 비밀 회의');
    expect(c.hidden, [r(3, 5)]);
    expect(c.selection.baseOffset, 0);
  });
}
