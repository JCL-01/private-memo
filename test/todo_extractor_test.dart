import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/organize/todo_extractor.dart';

String show(List<TodoItem> todos) => todos
    .map(
      (t) =>
          '${t.owner.isEmpty ? '' : '[${t.owner}] '}${t.task}'
          '${t.details.isEmpty ? '' : ' · ${t.details.join(', ')}'}'
          '${t.when.isEmpty ? '' : ' (${t.when})'}',
    )
    .join(' | ');

void main() {
  test('할 일 여러 개를 나누고, 물건 목록은 세부 내용, 다른 사람 일은 그 사람 몫으로', () {
    expect(
      show(
        extractTodos(
          '내일 3시 장보고 오기\n당근, 파채, 소고기 두 근\n요리는 누나가\n28일 13:30 찬양팀 연습',
        ),
      ),
      '내일 3시 장보고 오기 · 당근, 파채, 소고기 두 근 (내일 3시) | [누나] 요리 | 28일 13:30 찬양팀 연습 (28일 13:30)',
    );
  });

  test('역할 나누기: 담당·님이·가족', () {
    expect(
      show(extractTodos('디자인 시안 수정 (지수 담당)\n김팀장님이 견적 검토\n엄마가 반찬 준비\n설거지 하기')),
      '[지수] 디자인 시안 수정 | [김팀장님] 견적 검토 | [엄마] 반찬 준비 | 설거지 하기',
    );
  });

  test('아이디어·고민 메모는 할 일 없음', () {
    expect(
      extractTodos(
        '독자적인 메모 앱을 만들어 유료화 할 지(=> 완성도 높게) 생각해야 함.\n\n'
        '클라우드 데이터는 애플/안드로이드 클라우드에 올리기.\n\n'
        '프라이빗 필름을 사용하면 되지 않나? -> 보기에 불편함.',
      ).map((t) => t.task),
      ['클라우드 데이터는 애플/안드로이드 클라우드에 올리기.'],
    );
  });

  test('정보 기록은 할 일 없음', () {
    expect(extractTodos('와이파이 cafe2024!\n주차 B2 37번\n관리실 02-123-4567'), isEmpty);
  });

  test('강의 메모는 과제만 할 일', () {
    expect(
      show(
        extractTodos(
          '운영체제 7강\n프로세스 vs 스레드\n스레드는 메모리 공유 -> 동기화 필요\n과제 다음주 수 자정까지',
        ),
      ),
      '과제 다음주 수 자정까지 (다음주 수 자정까지)',
    );
  });

  test('통화 메모', () {
    expect(
      show(
        extractTodos('김팀장 통화\n견적 수정본 금요일까지\n박대리한테 작년 자료 받기\n다음주 화 2시 미팅 확정'),
      ),
      '견적 수정본 금요일까지 (금요일까지) | 박대리한테 작년 자료 받기 | 다음주 화 2시 미팅 확정 (다음주 화 2시)',
    );
  });

  test('여행 계획: 일정 설명은 렌트카 예약의 세부 내용이 아님', () {
    expect(
      show(extractTodos('렌트카 예약해야함\n첫날 협재 둘째날 성산일출봉\n숙소 아직 → 이번주안에')),
      '렌트카 예약해야함 | 숙소 아직 → 이번주안에 (이번주안에)',
    );
  });

  test('목표는 할 일이 아님', () {
    expect(extractTodos('출시 12월 중순 목표'), isEmpty);
  });

  test('한 줄 낱말 목록은 장보기 할 일 하나', () {
    expect(show(extractTodos('우유 계란 두부 대파 휴지 세제')), '사기: 우유 계란 두부 대파 휴지 세제');
  });
}
