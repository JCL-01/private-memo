import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import 'private_text_controller.dart';

/// 에디터 글자 뒤에 회색 박스를 그린다.
///
/// 글자 배경색이나 취소선으로 그리면 글꼴마다 두께가 달라지고 위아래 줄과 붙는다.
/// 그래서 박스 글자는 투명하게 두고, 그 자리에 모두 같은 높이의 둥근 사각형을 그린다.
class HiddenBoxPainter extends CustomPainter {
  HiddenBoxPainter({
    required this.controller,
    required this.findEditable,
    required this.selfBox,
    required this.boxColor,
    required this.boxHeight,
    Listenable? repaint,
  }) : super(repaint: Listenable.merge([controller, ?repaint]));

  final PrivateTextController controller;

  /// 텍스트를 그리는 RenderEditable을 찾는다.
  final RenderEditable? Function() findEditable;

  /// 이 CustomPaint의 RenderBox.
  final RenderBox? Function() selfBox;

  final Color boxColor;

  /// 박스 높이(논리 픽셀). 모든 박스가 같은 높이.
  final double boxHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final editable = findEditable();
    final me = selfBox();
    if (editable == null || me == null) return;
    if (!editable.attached || !editable.hasSize || !me.attached) return;

    final transform = editable.getTransformTo(me);
    final visible = MatrixUtils.transformRect(
      transform,
      Offset.zero & editable.size,
    );
    canvas.save();
    canvas.clipRect(visible);

    final paint = Paint()..color = boxColor;
    final radius = Radius.circular(boxHeight * 0.18);
    for (final b in controller.boxes) {
      final rects = editable.getBoxesForSelection(
        TextSelection(baseOffset: b.start, extentOffset: b.end),
      );
      for (final tb in rects) {
        final r = MatrixUtils.transformRect(transform, tb.toRect());
        if (r.width <= 0) continue;
        final box = Rect.fromCenter(
          center: r.center,
          width: r.width,
          height: boxHeight,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(box, radius), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(HiddenBoxPainter old) =>
      old.boxColor != boxColor || old.boxHeight != boxHeight;
}
