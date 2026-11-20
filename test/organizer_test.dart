import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/organize/organizer.dart';

class FakeSummarizer implements MemoSummarizer {
  @override
  Future<List<String>> summarize(String memo) async => ['장보기와 찬양팀 연습이 있다.'];
}

void main() {
  const memo = '내일 3시 장보고 오기\n당근, 파채, 소고기 두 근\n요리는 누나가\n28일 13:30 찬양팀 연습';

  test('할 일에 일정과 세부 내용을 붙이고, 맡은 사람별로 나눈다', () async {
    final r = await organizeMemo(memo);
    expect(
      r.toText(),
      '할 일\n'
      '[나]\n'
      '- 내일 3시 장보고 오기 (내일 3시)\n'
      '  · 당근, 파채, 소고기 두 근\n'
      '- 28일 13:30 찬양팀 연습 (28일 13:30)\n'
      '[누나]\n'
      '- 요리',
    );
  });

  test('내 일만 있으면 사람별로 나누지 않는다', () async {
    final r = await organizeMemo('견적 수정본 금요일까지\n박대리한테 자료 받기');
    expect(r.toText(), '할 일\n- 견적 수정본 금요일까지 (금요일까지)\n- 박대리한테 자료 받기');
  });

  test('요약이 있으면 요약 다음에 할 일', () async {
    final r = await organizeMemo(memo, summarizer: FakeSummarizer());
    expect(r.toText(), startsWith('요약\n- 장보기와 찬양팀 연습이 있다.\n\n할 일\n'));
  });

  test('할 일이 없으면 할 일을 쓰지 않는다 (F8-2d)', () async {
    final r = await organizeMemo(
      '와이파이 cafe2024!',
      summarizer: FakeSummarizer(),
    );
    expect(r.toText(), isNot(contains('할 일')));
  });
}
