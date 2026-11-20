/// 한국어 메모의 날짜·시간 표현 찾기. (F8-2g)
///
/// 모델에게 날짜를 맡기면 엉뚱한 할 일에 붙이거나 지어내는 일이 많아서(시험 결과),
/// 날짜·시간 표현은 코드가 줄마다 직접 찾는다. 이후 자동 일정 등록에도 쓴다.
library;

const _next = r'(?=$|[^가-힣]|까지|에|부터|전|안|이내|중)';
const _day = '(?<![가-힣])(?:오늘|내일|모레|글피|낼)$_next';
const _weekPrefix = r'(?<![가-힣])(?:(?:이번\s?주|다음\s?주|담주|다다음\s?주|차주)\s*)?';
const _week = '$_weekPrefix(?:월|화|수|목|금|토|일)(?:요일)?$_next';
const _weekOnly =
    r'(?:이번\s?주|다음\s?주|담주|다다음\s?주|차주|이번\s?달|다음\s?달)'
    r'(?:\s*(?:안에|안|중|내|까지))?';
const _date =
    r'(?:\d{1,2}\s*/\s*\d{1,2}(?:\s*~\s*\d{1,2}(?:\s*/\s*\d{1,2})?)?'
    r'|\d{1,2}\s*월\s*\d{1,2}\s*일'
    r'|\d{1,2}\s*월\s*(?:초|중순|말)'
    r'|\d{1,2}\s*일(?![가-힣]))';
const _part = r'(?:오전|오후|아침|점심|저녁|밤|새벽|낮)';
const _time =
    '(?:$_part\\s*)?'
    r'(?:\d{1,2}\s*:\s*\d{2}|\d{1,2}\s*시(?:\s*\d{1,2}\s*분|\s*반)?|자정|정오)';
const _tail = r'(?:\s*(?:까지|이내|전까지|안에))?';
const _atom = '(?:$_date|$_day|$_week|$_weekOnly|$_time|$_part)';

final RegExp _expr = RegExp('$_atom(?:\\s*$_atom)*$_tail');
final RegExp _partOnly = RegExp('^$_part\$');

/// 한 줄에서 찾은 날짜·시간 표현과 그 위치.
class DateMention {
  const DateMention(this.text, this.start, this.end);

  final String text;
  final int start;
  final int end;

  @override
  String toString() => text;
}

/// [line]에서 날짜·시간 표현을 찾는다.
/// 시간대만 있는 경우(예: '점심 국수')는 날짜로 보지 않는다.
List<DateMention> findDates(String line) {
  final out = <DateMention>[];
  for (final m in _expr.allMatches(line)) {
    final raw = m.group(0)!;
    final text = raw.trim();
    if (text.isEmpty || _partOnly.hasMatch(text)) continue;
    final lead = raw.length - raw.trimLeft().length;
    out.add(DateMention(text, m.start + lead, m.start + lead + text.length));
  }
  return out;
}
