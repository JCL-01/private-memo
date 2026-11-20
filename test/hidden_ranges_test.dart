import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/editor/hidden_ranges.dart';

const r = HiddenRange.new;

void main() {
  group('hideRange', () {
    const text = '오늘 비밀 회의 있음';
    //            0123456789...  '오늘'[0,2) '비밀'[3,5) '회의'[6,8) '있음'[9,11)

    test('선택에 걸친 어절 전체를 가린다 (어절 중간 선택 포함)', () {
      // '늘 비' 선택 → '오늘', '비밀' 전체
      expect(hideRange(text, [], 1, 4), [r(0, 2), r(3, 5)]);
    });

    test('어절 사이 공백은 가리지 않는다', () {
      final hidden = hideRange(text, [], 0, text.length);
      expect(hidden, [r(0, 2), r(3, 5), r(6, 8), r(9, 11)]);
    });

    test('공백만 선택하면 아무것도 가리지 않는다', () {
      expect(hideRange('a   b', [], 2, 3), isEmpty);
    });

    test('해제는 선택에 걸친 어절의 범위만 푼다', () {
      final hidden = [r(0, 2), r(3, 5), r(6, 8)];
      expect(unhideRange(text, hidden, 4, 4 + 1), [r(0, 2), r(6, 8)]);
    });

    test('메뉴 표시 조건', () {
      final hidden = [r(3, 5)];
      expect(canHide(text, hidden, 3, 5), isFalse);
      expect(canHide(text, hidden, 0, 5), isTrue);
      expect(canUnhide(text, hidden, 3, 5), isTrue);
      expect(canUnhide(text, hidden, 0, 2), isFalse);
    });
  });

  group('diffText', () {
    test('반복 글자 앞에 입력해도 커서 위치로 정확히 찾는다', () {
      expect(diffText('ba', 'bba', cursor: 1), const TextEdit(0, 0, 'b'));
    });

    test('한글 조합: 방금 넣은 글자를 바꾼다', () {
      expect(diffText('가', '각', cursor: 1), const TextEdit(0, 1, '각'));
    });

    test('커서 정보 없이: 앞뒤 공통 부분으로 찾는다(대체 단어 바꾸기)', () {
      expect(diffText('오늘 나왓다 ', '오늘 나왔다 '), const TextEdit(4, 1, '왔'));
    });

    test('백스페이스', () {
      expect(diffText('abc', 'ab', cursor: 2), const TextEdit(2, 1, ''));
    });
  });

  group('applyEdit', () {
    // 'ab [cdef] gh' : cdef 가 [3,7)
    final hidden = [r(3, 7)];

    test('앞에 입력하면 범위가 따라간다 (F3-8)', () {
      expect(applyEdit(hidden, const TextEdit(0, 0, 'xx')), [r(5, 9)]);
    });

    test('앞에서 지워도 범위가 따라간다 (F3-8)', () {
      expect(applyEdit(hidden, const TextEdit(0, 2, '')), [r(1, 5)]);
    });

    test('박스 바로 뒤·앞에 입력한 글자는 가리지 않는다 (F3-5)', () {
      expect(applyEdit(hidden, const TextEdit(7, 0, 'x')), [r(3, 7)]);
      expect(applyEdit(hidden, const TextEdit(3, 0, 'x')), [r(4, 8)]);
    });

    test('박스 중간에 넣은 글자는 가리지 않는다 (F3-5)', () {
      expect(applyEdit(hidden, const TextEdit(5, 0, 'X')), [r(3, 5), r(6, 8)]);
    });

    test('박스 글자를 지우면 박스 길이만 줄어든다 (F3-7)', () {
      expect(applyEdit(hidden, const TextEdit(6, 1, '')), [r(3, 6)]);
      expect(applyEdit(hidden, const TextEdit(3, 4, '')), isEmpty);
    });

    test('수정 중: 입력한 글자도 가리고, 공백으로 나누면 둘 다 가린다 (F4-3)', () {
      expect(applyEdit(hidden, const TextEdit(5, 0, 'X'), hideInserted: true), [
        r(3, 8),
      ]);
      expect(applyEdit(hidden, const TextEdit(5, 0, ' '), hideInserted: true), [
        r(3, 5),
        r(6, 8),
      ]);
    });
  });

  test('JSON 저장/복원', () {
    final ranges = [r(0, 2), r(5, 9)];
    expect(decodeRanges(encodeRanges(ranges)), ranges);
    expect(decodeRanges('잘못된 값'), isEmpty);
  });
}
