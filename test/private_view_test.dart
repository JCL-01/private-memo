import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/editor/hidden_ranges.dart';
import 'package:private_memo/editor/private_view.dart';

const r = HiddenRange.new;

/// 어절별 표시 방식을 글자로 요약: N 보통, n 회색, B 박스, F 파란색.
String summary(String text, ShadeMap map) {
  return allWords(text).map((w) {
    return switch (map[w.start]) {
      Shade.normal => 'N',
      Shade.near => 'n',
      Shade.box => 'B',
      Shade.focus => 'F',
      Shade.peek => 'O',
    };
  }).join();
}

void main() {
  const text = 'w0 w1 w2 w3 w4 w5 w6';
  //            0  3  6  9  12 15 18

  test('현재 어절 그대로, 바로 앞뒤 한 어절씩 회색, 나머지 박스 (F2-1~3)', () {
    // 커서가 w3 끝(11)
    expect(summary(text, privateShades(text, 11)), 'BBnNnBB');
  });

  test('문서 끝에서는 앞쪽 한 어절만 회색', () {
    expect(summary(text, privateShades(text, text.length)), 'BBBBBnN');
  });

  test('커서가 공백 사이에 있으면 양옆 어절이 회색', () {
    // 'w2 w3' 사이 공백 다음(9)은 w3 시작이므로 w3가 현재 어절.
    // 공백 두 개 사이를 만들기 위해 별도 문장 사용
    const t = 'a b  c d e';
    //         0 2  5 7 9   커서 4 = 'b'와 'c' 사이 공백 가운데
    expect(summary(t, privateShades(t, 4)), 'BnnBB');
  });

  test('공백·줄바꿈은 그대로 둔다 (F2-4)', () {
    const t = 'a\nb c';
    final map = privateShades(t, t.length);
    expect(map[1], Shade.normal);
  });

  test('수정 중인 어절은 파란색, 보기 중인 어절은 주황색 (F4-8)', () {
    final map = privateShades(text, text.length, editing: [r(0, 2)]);
    expect(map[0], Shade.focus);
    expect(normalShades(text, [r(0, 2)], editing: [r(0, 2)])[0], Shade.focus);
    expect(normalShades(text, [r(0, 2)], revealed: [r(0, 2)])[0], Shade.peek);
  });

  test('일반 모드: 가린 범위만 박스', () {
    final map = normalShades(text, [r(3, 5)]);
    expect(summary(text, map), 'NBNNNNN');
  });
}
