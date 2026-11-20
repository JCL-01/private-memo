import 'date_finder.dart';

/// 정리본의 할 일 한 개. (F8-2d)
class TodoItem {
  const TodoItem({required this.task, this.when = '', this.details = const []});

  /// 할 일 내용(메모의 그 줄).
  final String task;

  /// 그 줄에 적힌 날짜·시간 표현. 없으면 빈 문자열.
  final String when;

  /// 다음 줄에 이어 적은 세부 내용(살 물건 목록 등).
  final List<String> details;

  @override
  String toString() => 'TodoItem($task, $when, $details)';
}

final _bullet = RegExp(r'^[-*•·]\s*');

/// 해야 할 일을 나타내는 표현.
final _action = RegExp(
  r'(하기|오기|가기|받기|사기|보기|주기|내기|드리기|챙기기|넣기|맡기기|보내기|부치기|올리기|[가-힣]기|'
  r'예약\s*(?:필요|하기|해야\S*)|해야\s*(?:함|됨|해|지)?|할\s*것|확인\s*후|연락|제출|신청|준비)'
  r'\s*[!?.]*$'
  r'|(까지|미리|해야)',
);

/// '필요'는 화살표 설명(예: "스레드는 메모리 공유 -> 동기화 필요")이 아닐 때만 할 일.
final _need = RegExp(r'필요\s*[!?.]*$');
final _arrow = RegExp(r'->|→|=>');

/// '-기'로 끝나지만 할 일이 아닌 낱말.
final _notVerbGi = RegExp(r'(이야기|얘기|일기|분위기|경기|인기|용기|날씨|느낌)\s*[!?.]*$');

bool _isAction(String line) {
  if (_notVerbGi.hasMatch(line) &&
      !_action.hasMatch(line.replaceFirst(_notVerbGi, ''))) {
    return false;
  }
  return _action.hasMatch(line) ||
      (_need.hasMatch(line) && !_arrow.hasMatch(line));
}

/// 다른 사람이 하는 일.
final _other = RegExp(r'(담당\)?\s*$|님이|씨가|누나가|형이|언니가|오빠가|엄마가|아빠가)');

/// 단순 정보 기록.
final _info = RegExp(
  r'(비번|비밀번호|와이파이|wifi|주차|\d{2,4}-\d{3,4}-\d{4})',
  caseSensitive: false,
);

/// 의견·고민·질문.
final _opinion = RegExp(r'(\?\s*$|생각해야|할\s*지|할지|않나|=>|인가\s*$)');

/// 목표·결과 기록(할 일이 아님).
final _goal = RegExp(r'(목표|예정|완료|했음|함\s*$)');

/// 쉼표나 수량으로 된 물건 목록(앞 줄 할 일의 세부 내용).
final _itemList = RegExp(
  r'^[^,]+(,\s*[^,]+)+$|\d+\s*(개|근|장|병|봉지|팩|kg|g|L|권|켤레)',
);

/// 한 줄 전체가 띄어 쓴 낱말 목록(장보기 목록 등).
final _wordList = RegExp(r'^[가-힣A-Za-z]+(\s+[가-힣A-Za-z]+){2,}$');

/// 러프한 메모에서 할 일을 찾는다. (F8-2d)
///
/// 작은 모델은 "무엇이 할 일인가"를 잘 가리지 못해서(시험 결과), 규칙으로 고른다.
/// - 날짜 표현이나 행동 표현이 있는 줄은 할 일
/// - 정보 기록, 의견·질문, 다른 사람의 일, 목표·결과 기록은 할 일이 아님
/// - 할 일 바로 다음 줄의 물건 목록은 그 할 일의 세부 내용
/// - 한 줄짜리 낱말 목록은 장보기 같은 할 일 하나
List<TodoItem> extractTodos(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .map((l) => l.replaceFirst(_bullet, ''))
      .toList();

  final todos = <TodoItem>[];
  String? lastTodoLine;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final dates = findDates(line);
    final previous = i > 0 ? lines[i - 1] : null;

    // 바로 앞 줄 할 일의 세부 내용(물건 목록)
    if (todos.isNotEmpty &&
        previous != null &&
        previous == lastTodoLine &&
        dates.isEmpty &&
        !_isAction(line) &&
        _itemList.hasMatch(line)) {
      final last = todos.removeLast();
      todos.add(
        TodoItem(
          task: last.task,
          when: last.when,
          details: [...last.details, line],
        ),
      );
      continue;
    }

    if (_other.hasMatch(line)) continue;
    if (_info.hasMatch(line) && dates.isEmpty) continue;
    final opinion = _opinion.hasMatch(line);
    if (opinion && dates.isEmpty) continue;
    if (_goal.hasMatch(line) && !_isAction(line) && dates.isEmpty) {
      continue;
    }
    if (_goal.hasMatch(line) && line.contains('목표')) continue;

    final isTodo = _isAction(line) || (dates.isNotEmpty && !opinion);
    if (!isTodo) continue;
    todos.add(
      TodoItem(task: line, when: dates.isEmpty ? '' : dates.first.text),
    );
    lastTodoLine = line;
  }

  if (todos.isEmpty && lines.length == 1 && _wordList.hasMatch(lines.single)) {
    todos.add(TodoItem(task: '사기: ${lines.single}'));
  }
  return todos;
}
