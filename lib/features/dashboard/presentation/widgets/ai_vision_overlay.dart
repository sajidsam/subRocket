import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/models/ai_detection_model.dart';

class AiVisionOverlay extends StatelessWidget {
  final List<DetectedObject> detections;
  final Animation<double> animation;

  const AiVisionOverlay({
    super.key,
    required this.detections,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _AiVisionPainter(
            detections: detections,
            animValue: animation.value,
          ),
        );
      },
    );
  }
}

class _AiVisionPainter extends CustomPainter {
  final List<DetectedObject> detections;
  final double animValue;

  _AiVisionPainter({
    required this.detections,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final obj in detections) {
      final rect = Rect.fromLTWH(
        obj.normalizedRect.left * size.width,
        obj.normalizedRect.top * size.height,
        obj.normalizedRect.width * size.width,
        obj.normalizedRect.height * size.height,
      );

      _drawTacticalBoundingBox(canvas, rect, obj);
    }
  }

  void _drawTacticalBoundingBox(Canvas canvas, Rect rect, DetectedObject obj) {
    final cornerLength = min(rect.width, rect.height) * 0.28;
    final color = obj.color;

    // 1. Semi-transparent fill highlight
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 2. Corner Brackets (Tactical HUD Box)
    final boxPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Top-Left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerLength, 0), boxPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerLength), boxPaint);

    // Top-Right
    canvas.drawLine(rect.topRight, rect.topRight - Offset(cornerLength, 0), boxPaint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, cornerLength), boxPaint);

    // Bottom-Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(cornerLength, 0), boxPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft - Offset(0, cornerLength), boxPaint);

    // Bottom-Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(cornerLength, 0), boxPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(0, cornerLength), boxPaint);

    // 3. Center Aim Dot
    canvas.drawCircle(
      rect.center,
      2.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // 4. Tactical Tag HUD Header (Label + Confidence + Distance)
    final confPercent = (obj.confidence * 100).toStringAsFixed(0);
    final textSpan = TextSpan(
      text: '${obj.label} $confPercent% • ${obj.distanceMeters.toStringAsFixed(0)}m',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        letterSpacing: 0.4,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final tagBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 7,
        textPainter.width + 12,
        textPainter.height + 6,
      ),
      const Radius.circular(3),
    );

    // Tag background with category color border
    canvas.drawRRect(
      tagBgRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      tagBgRect,
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Render tag text
    textPainter.paint(
      canvas,
      Offset(rect.left + 6, rect.top - textPainter.height - 4),
    );
  }

  @override
  bool shouldRepaint(covariant _AiVisionPainter oldDelegate) => true;
}
