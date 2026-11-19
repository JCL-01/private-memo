import '../editor/hidden_ranges.dart';
import 'database.dart';

/// 목록에 보여 줄 한 줄과 본문 안에서의 시작 위치.
class NoteLine {
  const NoteLine(this.text, this.start);

  final String text;
  final int start;

  /// 이 줄에 걸친 가린 범위(줄 기준 오프셋).
  List<HiddenRange> hiddenIn(List<HiddenRange> ranges) => [
    for (final r in ranges)
      if (r.overlaps(start, start + text.length))
        HiddenRange(
          (r.start - start).clamp(0, text.length),
          (r.end - start).clamp(0, text.length),
        ),
  ];
}

/// 화면에서 쓰는 메모 표시용 헬퍼.
extension NoteDisplay on Note {
  /// 앞뒤 공백을 뺀, 비어 있지 않은 줄들.
  List<NoteLine> get _lines {
    final out = <NoteLine>[];
    var offset = 0;
    for (final raw in content.split('\n')) {
      final trimmedLeft = raw.trimLeft();
      final text = trimmedLeft.trimRight();
      if (text.isNotEmpty) {
        out.add(NoteLine(text, offset + raw.length - trimmedLeft.length));
      }
      offset += raw.length + 1;
    }
    return out;
  }

  /// 첫 번째 비어 있지 않은 줄. 없으면 null.
  NoteLine? get titleLine => _lines.firstOrNull;

  /// 두 번째 비어 있지 않은 줄. 없으면 null.
  NoteLine? get previewLine => _lines.elementAtOrNull(1);

  /// 첫 번째 비어 있지 않은 줄. 없으면 '새로운 메모'.
  String get title => titleLine?.text ?? '새로운 메모';

  /// 두 번째 비어 있지 않은 줄(미리보기). 없으면 빈 문자열.
  String get preview => previewLine?.text ?? '';

  List<HiddenRange> get hidden => decodeRanges(hiddenRanges);

  bool get isBlank => content.trim().isEmpty;
}
