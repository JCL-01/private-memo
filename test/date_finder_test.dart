import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/organize/date_finder.dart';

void main() {
  const cases = {
    '내일 3시 장보고 오기': ['내일 3시'],
    '28일 13:30 찬양팀 연습': ['28일 13:30'],
    '견적 수정본 금요일까지': ['금요일까지'],
    '다음주 화 2시 미팅 확정': ['다음주 화 2시'],
    '다음 회의 27일 10시': ['27일 10시'],
    '과제 다음주 수 자정까지': ['다음주 수 자정까지'],
    '민지 생일 12/3 선물 미리': ['12/3'],
    '토 저녁7시 강남역 동창모임 회비 3만': ['토 저녁7시'],
    '재진 12/4 오전 10시 예약함': ['12/4 오전 10시'],
    '제주 1/15~18': ['1/15~18'],
    '숙소 아직 → 이번주안에': ['이번주안에'],
    '출시 12월 중순 목표': ['12월 중순'],
    '와이파이 cafe2024!': <String>[],
    '주차 B2 37번': <String>[],
    '점심 국수 맛있었음': <String>[],
    '단가 5% 더 깎아줄수있는지??': <String>[],
    '수학 3단원 공부': <String>[],
    '일단 해보기': <String>[],
  };

  for (final e in cases.entries) {
    test(e.key, () {
      expect(findDates(e.key).map((d) => d.text).toList(), e.value);
    });
  }

  test('위치도 알려 준다', () {
    final d = findDates('과제 다음주 수 자정까지').single;
    expect('과제 다음주 수 자정까지'.substring(d.start, d.end), '다음주 수 자정까지');
  });
}
