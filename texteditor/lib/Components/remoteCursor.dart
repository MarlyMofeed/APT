import 'package:flutter/material.dart';

class RemoteCursorWidget extends StatelessWidget {
  final Offset position;
  final Color color;

  const RemoteCursorWidget({
    required this.position,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position.dy,
      left: position.dx,
      child: Container(
        width: 2.0,
        height: 20.0,
        color: color,
      ),
    );
  }
}

Offset calculateCursorOffset(TextEditingController controller, int position) {
  final textSpan = TextSpan(
    text: controller.text,
    style: TextStyle(fontSize: 16.0),
  );

  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();

  final offset = textPainter.getOffsetForCaret(
    TextPosition(offset: position),
    Rect.zero,
  );

  return offset;
}
