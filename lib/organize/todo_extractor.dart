import 'date_finder.dart';

/// 정리본의 할 일 한 개. (F8-2d)
class TodoItem {
  const TodoItem({
    required this.task,
    this.when = '',
    this.details = const [],
    this.owner = '',
  });

  /// 이 일을 맡은 사람. 빈 문자열이면 메모를 쓴 사람(나). (역할 나누기)
  final String owner;

  /// 할 일 내용(메모의 그 줄).
  final String task;

  /// 그 줄에 적힌 날짜·시간 표현. 없으면 빈 문자열.
  final String when;

  /// 다음 줄에 이어 적은 세부 내용(살 물건 목록 등).
  final List<String> details;

  TodoItem withDetail(String detail) => TodoItem(
    task: task,
    when: when,
    details: [...details, detail],
    owner: owner,
  );

  @override
  String toString() => 'TodoItem($task, $when, $details, $owner)';
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
const _kin = r'누나|형|언니|오빠|엄마|아빠|동생|남편|아내|와이프';

/// 다른 사람이 맡은 일: "(지수 담당)", "요리는 누나가", "김팀장님이 …", "누나가 요리".
final _ownerTag = RegExp(r'\(?\s*([가-힣A-Za-z]+)\s*담당\s*\)?');
final _ownerTail = RegExp('\\s*(?:([가-힣A-Za-z]+?)(님|씨)|($_kin))(?:이|가)\\s*\$');
final _ownerHead = RegExp('^(?:([가-힣A-Za-z]+?)(님|씨)|($_kin))(?:이|가)\\s+');

/// 줄에서 맡은 사람을 찾고, 그 사람을 뺀 할 일 내용을 돌려준다. 내 일이면 null.
({String owner, String task})? _otherOwner(String line) {
  final tag = _ownerTag.firstMatch(line);
  if (tag != null) {
    final task = line.replaceRange(tag.start, tag.end, '').trim();
    return (owner: tag.group(1)!, task: task);
  }
  for (final re in [_ownerTail, _ownerHead]) {
    final m = re.firstMatch(line);
    if (m == null) continue;
    final owner = m.group(3) ?? '${m.group(1)}${m.group(2)}';
    var task = line.replaceRange(m.start, m.end, '').trim();
    // "요리는 누나가" → "요리"
    task = task.replaceFirst(RegExp(r'(은|는)$'), '').trim();
    return (owner: owner, task: task);
  }
  return null;
}

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
      todos.add(todos.removeLast().withDetail(line));
      continue;
    }

    // 다른 사람이 맡은 일은 그 사람의 할 일로 나눈다.
    final other = _otherOwner(line);
    if (other != null && other.task.isNotEmpty) {
      final d = findDates(other.task);
      todos.add(
        TodoItem(
          task: other.task,
          when: d.isEmpty ? '' : d.first.text,
          owner: other.owner,
        ),
      );
      lastTodoLine = line;
      continue;
    }
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
