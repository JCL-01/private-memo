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
    test('수정 모드는 커서가 벗어나도 유지되고, ✕(stopEditing)로만 끝난다', () {
      final c = make();
      c.startEditing([r(3, 5)]);
      expect(c.isBoxed(r(3, 5)), isFalse);
      userSelect(c, 0);
      expect(c.editingRange, r(3, 5));
      expect(c.isBoxed(r(3, 5)), isFalse);
      c.stopEditing();
      expect(c.isEditingBox, isFalse);
      expect(c.isBoxed(r(3, 5)), isTrue);
    });

    test('수정 중인 어절 밖에서 입력한 글자는 가리지 않고, 대상 위치는 따라간다', () {
      final c = make();
      c.startEditing([r(3, 5)]);
      userSelect(c, 0);
      userSet(c, 'X오늘 비밀 회의', 1);
      expect(c.hidden, [r(4, 6)]);
      expect(c.editingRange, r(4, 6));
    });

    test('수정 중 입력한 글자도 가려진 어절의 일부가 된다', () {
      final c = make();
      c.startEditing([r(3, 5)]);
      userSet(c, '오늘 비밀들 회의', 6);
      expect(c.hidden, [r(3, 6)]);
      expect(c.editingRange, r(3, 6));
    });

    test('수정 중 공백으로 나누면 두 어절 모두 가린다', () {
      final c = make();
      c.startEditing([r(3, 5)]);
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
    test('커서가 움직이는 것만으로는 보기가 닫히지 않는다(손을 뗄 때 닫힘)', () {
      final c = make();
      c.reveal([r(3, 5)]);
      expect(c.isBoxed(r(3, 5)), isFalse);
      userSelect(c, 0);
      expect(c.isBoxed(r(3, 5)), isFalse);
      c.dismissReveal();
      expect(c.isBoxed(r(3, 5)), isTrue);
    });

    test('dismissReveal', () {
      final c = make();
      c.reveal([r(3, 5)]);
      c.dismissReveal();
      expect(c.revealedRanges, isEmpty);
    });

    test('보기는 되돌리기 대상이 아니다 (F5-4)', () {
      final c = make();
      c.reveal([r(3, 5)]);
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

  group('수정 모드 이동 (F4-2)', () {
    // 'a b c d' 에서 a, c, d 가린 상태
    PrivateTextController make3() => PrivateTextController(
      text: 'a b c d',
      hidden: [r(0, 1), r(4, 5), r(6, 7)],
    );

    test('수정 범위의 모든 어절이 박스에서 풀리고, 수정 완료로 다시 박스 (F4-2)', () {
      final c = make3();
      c.startEditing([r(4, 5), r(6, 7)]);
      expect(c.editingRanges, [r(4, 5), r(6, 7)]);
      expect(c.isBoxed(r(4, 5)), isFalse);
      expect(c.isBoxed(r(6, 7)), isFalse);
      expect(c.isBoxed(r(0, 1)), isTrue); // 범위 밖은 박스
      expect(c.selection.baseOffset, 5); // 첫 어절 끝
      c.stopEditing();
      expect(c.isEditingBox, isFalse);
      expect(c.isBoxed(r(4, 5)), isTrue);
      expect(c.isBoxed(r(6, 7)), isTrue);
    });

    test('범위 안 어느 어절에서든 고칠 수 있고, 새 글자도 가린다', () {
      final c = make3();
      c.startEditing([r(4, 5), r(6, 7)]);
      userSelect(c, 7);
      userSet(c, 'a b c dx', 8);
      expect(c.hidden, [r(0, 1), r(4, 5), r(6, 8)]);
      expect(c.editingRanges, [r(4, 5), r(6, 8)]);
    });

    test('공백으로 나눈 두 조각 모두 대상이 된다', () {
      final c = make3();
      c.startEditing([r(4, 5)]);
      userSet(c, 'a b cx d', 6); // 수정 중 x 입력 → 'cx'
      expect(c.editingRange, r(4, 6));
      userSelect(c, 5);
      userSet(c, 'a b c x d', 6); // c|x 사이에 공백
      expect(c.hidden, [r(0, 1), r(4, 5), r(6, 7), r(8, 9)]);
      expect(c.editingCount, 2);
      expect(c.editingRange, r(6, 7));
    });
  });

  group('메뉴 대상 박스 (F4-1)', () {
    test('선택에 일부라도 걸친 박스 전부', () {
      final c = PrivateTextController(
        text: 'a bb cc d',
        hidden: [r(2, 4), r(5, 7)],
      );
      c.selection = const TextSelection(baseOffset: 3, extentOffset: 6);
      expect(c.boxesForMenu(), [r(2, 4), r(5, 7)]);
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 1);
      expect(c.boxesForMenu(), isEmpty);
    });

    test('선택이 없으면 누른 위치의 박스', () {
      final c = make();
      c.selection = const TextSelection.collapsed(offset: 0);
      expect(c.boxesForMenu(pressedOffset: 4), [r(3, 5)]);
      expect(c.boxesForMenu(pressedOffset: 0), isEmpty);
    });

    test('보기는 여러 박스를 한꺼번에 연다', () {
      final c = PrivateTextController(
        text: 'a bb cc d',
        hidden: [r(2, 4), r(5, 7)],
      );
      c.reveal([r(2, 4), r(5, 7)]);
      expect(c.isBoxed(r(2, 4)), isFalse);
      expect(c.isBoxed(r(5, 7)), isFalse);
      c.dismissReveal();
      expect(c.isBoxed(r(2, 4)), isTrue);
    });

    test('해제는 지정한 박스만 풀고 되돌릴 수 있다', () {
      final c = PrivateTextController(
        text: 'a bb cc d',
        hidden: [r(2, 4), r(5, 7)],
      );
      c.unhideBoxes([r(2, 4)]);
      expect(c.hidden, [r(5, 7)]);
      c.undo();
      expect(c.hidden, [r(2, 4), r(5, 7)]);
    });
  });

  group('수정 중 어절을 다 지웠을 때 (F4-2e)', () {
    test('수정 모드는 이어지고, 다시 쓴 글자도 가려진다', () {
      final c = make(); // '오늘 비밀 회의', 비밀 [3,5) 가림
      c.startEditing([r(3, 5)]);
      userSet(c, '오늘 비 회의', 4);
      userSet(c, '오늘  회의', 3);
      expect(c.isEditingBox, isTrue);
      expect(c.editingRange, r(3, 3));
      expect(c.hidden, isEmpty);

      userSet(c, '오늘 새 회의', 4);
      expect(c.isEditingBox, isTrue);
      expect(c.editingRange, r(3, 4));
      expect(c.hidden, [r(3, 4)]);
      c.stopEditing();
      expect(c.isBoxed(r(3, 4)), isTrue);
    });

    test('빈 자리에서 다른 어절로 갔다가 돌아와도 이어서 쓸 수 있다', () {
      final c = PrivateTextController(
        text: 'a bb cc',
        hidden: [r(2, 4), r(5, 7)],
      );
      c.startEditing([r(2, 4), r(5, 7)]);
      userSet(c, 'a b cc', 3);
      userSet(c, 'a  cc', 2);
      expect(c.editingRanges, [r(2, 2), r(3, 5)]);
      userSelect(c, 5);
      userSelect(c, 2);
      userSet(c, 'a x cc', 3);
      expect(c.hidden, [r(2, 3), r(4, 6)]);
    });
  });

  test('Esc: 수정 모드와 보기를 모두 끝낸다 (F4-10)', () {
    final c = PrivateTextController(
      text: 'a bb cc',
      hidden: [r(2, 4), r(5, 7)],
    );
    c.reveal([r(5, 7)]);
    expect(c.exitModes(), isTrue);
    expect(c.revealedRanges, isEmpty);
    c.startEditing([r(2, 4)]);
    expect(c.exitModes(), isTrue);
    expect(c.isEditingBox, isFalse);
    expect(c.exitModes(), isFalse);
  });
}
