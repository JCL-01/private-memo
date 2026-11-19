import 'package:material_ui/material_ui.dart';

/// 박스 색. 라이트/다크 모드에서 배경과 구분되도록 고른 회색.
Color boxColorOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF5A5A5E)
    : const Color(0xFFC7C7CC);

/// `수정`·`보기`로 잠시 열린 어절 색. (F4-8)
Color focusColorOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF7FB2FF)
    : const Color(0xFF1F5FD1);
