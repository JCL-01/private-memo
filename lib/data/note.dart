import 'database.dart';

/// 화면에서 쓰는 메모 표시용 헬퍼.
extension NoteDisplay on Note {
  List<String> get _lines => content
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  /// 첫 번째 비어 있지 않은 줄. 없으면 '새로운 메모'.
  String get title => _lines.isEmpty ? '새로운 메모' : _lines.first;

  /// 두 번째 비어 있지 않은 줄(미리보기). 없으면 빈 문자열.
  String get preview => _lines.length > 1 ? _lines[1] : '';

  bool get isBlank => content.trim().isEmpty;
}
