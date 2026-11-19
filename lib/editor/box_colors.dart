import 'package:material_ui/material_ui.dart';

/// 박스 색. 라이트/다크 모드에서 배경과 구분되도록 고른 회색.
Color boxColorOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF5A5A5E)
    : const Color(0xFFC7C7CC);

/// `수정` 중인 어절 색(파란색). (F4-8)
Color focusColorOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF7FB2FF)
    : const Color(0xFF1F5FD1);

/// `보기`로 잠시 연 어절 색(주황색). (F4-8)
Color peekColorOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFFA94D)
    : const Color(0xFFD9640B);
