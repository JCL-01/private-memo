/// 프라이빗 드래그로 가린 범위 계산.
///
/// 모든 범위는 [start, end) 형태의 UTF-16 오프셋이며, 공백 문자를 포함하지 않는다.
/// 목록은 항상 정렬되어 있고, 겹치거나 맞닿은 범위는 하나로 합친다.
library;

import 'dart:convert';
import 'dart:math' as math;

bool isWhitespaceUnit(int unit) =>
    unit == 0x20 || // space
    unit == 0x0A || // \n
    unit == 0x0D || // \r
    unit == 0x09 || // \t
    unit == 0xA0 || // nbsp
    unit == 0x3000; // 전각 공백

class HiddenRange {
  const HiddenRange(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;
  bool get isEmpty => end <= start;

  /// 문자 인덱스 [i]가 범위 안에 있는지.
  bool covers(int i) => i >= start && i < end;

  /// 커서 오프셋 [offset]이 범위의 경계 또는 내부에 있는지.
  bool touches(int offset) => offset >= start && offset <= end;

  /// 커서 오프셋 [offset]이 범위 내부(경계 제외)에 있는지.
  bool strictlyContains(int offset) => offset > start && offset < end;

  bool overlaps(int a, int b) => start < b && end > a;

  @override
  bool operator ==(Object other) =>
      other is HiddenRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end)';
}

/// 정렬하고, 빈 범위를 버리고, 겹치거나 맞닿은 범위를 합친다.
List<HiddenRange> normalizeRanges(Iterable<HiddenRange> ranges) {
  final sorted = ranges.where((r) => !r.isEmpty).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final out = <HiddenRange>[];
  for (final r in sorted) {
    if (out.isNotEmpty && r.start <= out.last.end) {
      final last = out.removeLast();
      out.add(HiddenRange(last.start, math.max(last.end, r.end)));
    } else {
      out.add(r);
    }
  }
  return out;
}

/// [a, b) 와 겹치는 어절들. [a, b)가 비어 있으면 a 위치의 어절(있으면).
List<HiddenRange> wordsOverlapping(String text, int a, int b) {
  final words = <HiddenRange>[];
  var i = 0;
  while (i < text.length) {
    if (isWhitespaceUnit(text.codeUnitAt(i))) {
      i++;
      continue;
    }
    final start = i;
    while (i < text.length && !isWhitespaceUnit(text.codeUnitAt(i))) {
      i++;
    }
    final word = HiddenRange(start, i);
    final hit = a == b ? word.touches(a) : word.overlaps(a, b);
    if (hit) words.add(word);
    if (start >= b && a != b) break;
  }
  return words;
}

/// 선택 [a, b)에 걸친 어절 전체를 가린다. (F3-1, F3-2)
List<HiddenRange> hideRange(
  String text,
  List<HiddenRange> ranges,
  int a,
  int b,
) {
  return normalizeRanges([...ranges, ...wordsOverlapping(text, a, b)]);
}

/// 선택 [a, b)에 걸친 어절의 가린 범위를 푼다. (F3-3)
List<HiddenRange> unhideRange(
  String text,
  List<HiddenRange> ranges,
  int a,
  int b,
) {
  final words = wordsOverlapping(text, a, b);
  if (words.isEmpty) return ranges;
  final from = words.first.start;
  final to = words.last.end;
  return ranges.where((r) => !r.overlaps(from, to)).toList();
}

/// 선택에 아직 가리지 않은 어절 글자가 있는지 → `프라이빗` 메뉴 표시 여부.
bool canHide(String text, List<HiddenRange> ranges, int a, int b) {
  for (final w in wordsOverlapping(text, a, b)) {
    for (var i = w.start; i < w.end; i++) {
      if (!ranges.any((r) => r.covers(i))) return true;
    }
  }
  return false;
}

/// 선택에 가린 어절이 있는지 → `해제` 메뉴 표시 여부.
bool canUnhide(String text, List<HiddenRange> ranges, int a, int b) {
  final words = wordsOverlapping(text, a, b);
  if (words.isEmpty) return false;
  return ranges.any((r) => r.overlaps(words.first.start, words.last.end));
}

/// 텍스트 한 번의 변경: [start]부터 [deleted]글자를 지우고 [inserted]를 넣었다.
class TextEdit {
  const TextEdit(this.start, this.deleted, this.inserted);

  final int start;
  final int deleted;
  final String inserted;

  int get oldEnd => start + deleted;
  int get delta => inserted.length - deleted;

  @override
  bool operator ==(Object other) =>
      other is TextEdit &&
      other.start == start &&
      other.deleted == deleted &&
      other.inserted == inserted;

  @override
  int get hashCode => Object.hash(start, deleted, inserted);

  @override
  String toString() => 'TextEdit($start, -$deleted, +"$inserted")';
}

/// 이전/이후 텍스트로 변경 내용을 구한다.
///
/// 같은 글자가 반복될 때 위치가 모호하므로, 변경 후 커서 위치 [cursor]를
/// 입력이 끝난 지점으로 보고 우선 사용한다.
TextEdit diffText(String before, String after, {int? cursor}) {
  if (cursor != null && cursor >= 0 && cursor <= after.length) {
    final suffixLen = after.length - cursor;
    if (suffixLen <= before.length &&
        before.endsWith(after.substring(cursor))) {
      final limit = math.min(cursor, before.length - suffixLen);
      var p = 0;
      while (p < limit && before.codeUnitAt(p) == after.codeUnitAt(p)) {
        p++;
      }
      return TextEdit(
        p,
        before.length - suffixLen - p,
        after.substring(p, cursor),
      );
    }
  }
  final maxPrefix = math.min(before.length, after.length);
  var p = 0;
  while (p < maxPrefix && before.codeUnitAt(p) == after.codeUnitAt(p)) {
    p++;
  }
  var s = 0;
  while (s < before.length - p &&
      s < after.length - p &&
      before.codeUnitAt(before.length - 1 - s) ==
          after.codeUnitAt(after.length - 1 - s)) {
    s++;
  }
  return TextEdit(
    p,
    before.length - s - p,
    after.substring(p, after.length - s),
  );
}

/// 텍스트 변경에 맞춰 가린 범위를 옮긴다.
///
/// - 지운 글자는 범위에서 빠진다(박스 길이만 줄어든다). (F3-7)
/// - 앞에서 글자가 늘거나 줄면 범위가 따라간다. (F3-8)
/// - 새로 넣은 글자는 가리지 않는다. (F3-5)
/// - 단, [hideInserted]이면(수정 중인 어절 안의 입력) 넣은 글자 중 공백이 아닌
///   글자는 가린다. 공백으로 나뉜 양쪽은 모두 가린 채 남는다. (F4-3)
List<HiddenRange> applyEdit(
  List<HiddenRange> ranges,
  TextEdit edit, {
  bool hideInserted = false,
}) {
  final out = <HiddenRange>[];
  final start = edit.start;
  final oldEnd = edit.oldEnd;
  final delta = edit.delta;
  for (final r in ranges) {
    if (r.end <= start) {
      out.add(r);
    } else if (r.start >= oldEnd) {
      out.add(HiddenRange(r.start + delta, r.end + delta));
    } else {
      if (r.start < start) out.add(HiddenRange(r.start, start));
      if (r.end > oldEnd) {
        out.add(HiddenRange(oldEnd + delta, r.end + delta));
      }
    }
  }
  if (hideInserted) {
    final ins = edit.inserted;
    var i = 0;
    while (i < ins.length) {
      if (isWhitespaceUnit(ins.codeUnitAt(i))) {
        i++;
        continue;
      }
      final s = i;
      while (i < ins.length && !isWhitespaceUnit(ins.codeUnitAt(i))) {
        i++;
      }
      out.add(HiddenRange(start + s, start + i));
    }
  }
  return normalizeRanges(out);
}

/// [ranges]에서 [minus]와 겹치는 글자를 뺀 범위들.
List<HiddenRange> subtractRanges(
  List<HiddenRange> ranges,
  List<HiddenRange> minus,
) {
  var out = ranges;
  for (final m in minus) {
    out = [
      for (final r in out)
        if (!r.overlaps(m.start, m.end))
          r
        else ...[
          if (r.start < m.start) HiddenRange(r.start, m.start),
          if (r.end > m.end) HiddenRange(m.end, r.end),
        ],
    ];
  }
  return out;
}

/// 텍스트 길이를 벗어난 범위를 잘라낸다(저장된 데이터 보호용).
List<HiddenRange> clampRanges(List<HiddenRange> ranges, int length) {
  return normalizeRanges(
    ranges.map(
      (r) => HiddenRange(r.start.clamp(0, length), r.end.clamp(0, length)),
    ),
  );
}

String encodeRanges(List<HiddenRange> ranges) => jsonEncode([
  for (final r in ranges) [r.start, r.end],
]);

List<HiddenRange> decodeRanges(String json) {
  try {
    final list = jsonDecode(json) as List;
    return normalizeRanges([
      for (final item in list)
        HiddenRange((item as List)[0] as int, item[1] as int),
    ]);
  } catch (_) {
    return const [];
  }
}
