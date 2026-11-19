import 'package:material_ui/material_ui.dart';

import 'hidden_ranges.dart';

/// 목록 미리보기용: [boxes] 구간을 같은 높이의 회색 박스로 바꾼 글자 조각들. (F1-7)
List<InlineSpan> maskedSpans({
  required String text,
  required List<HiddenRange> boxes,
  required Color boxColor,
  required TextStyle style,
}) {
  final spans = <InlineSpan>[];
  var i = 0;
  for (final b in boxes) {
    final start = b.start.clamp(0, text.length);
    final end = b.end.clamp(0, text.length);
    if (start >= end) continue;
    if (i < start) spans.add(TextSpan(text: text.substring(i, start)));
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: MaskBox(
          text: text.substring(start, end),
          style: style,
          color: boxColor,
        ),
      ),
    );
    i = end;
  }
  if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
  return spans;
}

/// 글자 [text]의 폭만큼, 글자 크기에 맞춘 높이의 회색 박스.
class MaskBox extends StatelessWidget {
  const MaskBox({
    super.key,
    required this.text,
    required this.style,
    required this.color,
  });

  final String text;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final fontSize = scaler.scale(style.fontSize ?? 14);
    final width = painter.width;
    painter.dispose();
    return Container(
      width: width,
      height: fontSize * 0.9,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(fontSize * 0.16),
      ),
    );
  }
}
