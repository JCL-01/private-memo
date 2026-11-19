import '../editor/hidden_ranges.dart';
import '../editor/private_view.dart';

/// 어절 앞뒤에서 떼어 내고 검사할 문장 부호.
final RegExp _leadingPunct = RegExp(r'''^[\(\[\{"'“‘「『<《〈…·~\-]+''');
final RegExp _trailingPunct = RegExp(r'''[\)\]\}"'”’」』>》〉.,!?;:…·~\-]+$''');
final RegExp _hangul = RegExp(r'[가-힣]');
final RegExp _digit = RegExp(r'\d');

/// 맞춤법 검사 대상: 어절에서 앞뒤 문장 부호를 뺀 부분.
/// 한글이 없는 어절(영어, 숫자, 기호)과 숫자가 섞인 어절은 검사하지 않는다.
List<HiddenRange> checkableWords(String text) {
  final out = <HiddenRange>[];
  for (final w in allWords(text)) {
    var s = w.start;
    var e = w.end;
    final word = text.substring(s, e);
    final lead = _leadingPunct.firstMatch(word);
    if (lead != null) s += lead.end;
    final trail = _trailingPunct.firstMatch(text.substring(s, e));
    if (trail != null) e = s + trail.start;
    if (s >= e) continue;
    final core = text.substring(s, e);
    if (!_hangul.hasMatch(core) || _digit.hasMatch(core)) continue;
    out.add(HiddenRange(s, e));
  }
  return out;
}
