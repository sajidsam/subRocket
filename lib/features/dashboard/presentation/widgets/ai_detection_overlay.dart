import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/real_ai_detector_service.dart';

enum AiTargetCategory {
  person('PERSON', Icons.person_outline, GcsColors.warningOrange),
  vehicle('VEHICLE', Icons.directions_car_outlined, GcsColors.warningOrange),
  drone('UAV', Icons.flight_outlined, GcsColors.cyanAccent),
  landingPad('LZ', Icons.crop_free, GcsColors.channelGreen),
  obstacle('OBJECT', Icons.crop_square, GcsColors.goldAccent);

  final String displayName;
  final IconData icon;
  final Color color;
  const AiTargetCategory(this.displayName, this.icon, this.color);
}

class AiDetectedTarget {
  final String id;
  final AiTargetCategory category;
  final String label;
  final double confidence;
  final double baseDistanceMeters;
  final double speedKmh;
  final Rect normalizedRect; // 0.0 to 1.0 coordinates relative to container
  final double phaseOffset;

  const AiDetectedTarget({
    required this.id,
    required this.category,
    required this.label,
    required this.confidence,
    required this.baseDistanceMeters,
    required this.speedKmh,
    required this.normalizedRect,
    this.phaseOffset = 0.0,
  });
}

class AiDetectionOverlay extends StatefulWidget {
  final bool isAiDetectActive;
  final ValueChanged<String?>? onTargetSelected;

  const AiDetectionOverlay({
    super.key,
    required this.isAiDetectActive,
    this.onTargetSelected,
  });

  @override
  State<AiDetectionOverlay> createState() => _AiDetectionOverlayState();
}

class _AiDetectionOverlayState extends State<AiDetectionOverlay> {
  String? _lockedTargetId;

  @override
  void initState() {
    super.initState();
    RealAiDetectorService.instance.start();
  }

  @override
  void dispose() {
    RealAiDetectorService.instance.stop();
    super.dispose();
  }

  void _toggleLockTarget(String id) {
    setState(() {
      if (_lockedTargetId == id) {
        _lockedTargetId = null;
      } else {
        _lockedTargetId = id;
      }
    });
    widget.onTargetSelected?.call(_lockedTargetId);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAiDetectActive) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<List<AiDetectedTarget>>(
      valueListenable: RealAiDetectorService.instance.detectionsNotifier,
      builder: (context, realTargets, _) {
        // If no real targets detected by YOLO, show completely clean screen
        if (realTargets.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                ...realTargets.map((target) {
                  final isLocked = _lockedTargetId == target.id;

                  final rect = Rect.fromLTWH(
                    (target.normalizedRect.left * width).clamp(0.0, width - 20),
                    (target.normalizedRect.top * height).clamp(0.0, height - 20),
                    (target.normalizedRect.width * width).clamp(20.0, width),
                    (target.normalizedRect.height * height).clamp(20.0, height),
                  );

                  return Positioned(
                    left: rect.left,
                    top: (rect.top - 20).clamp(0.0, height - 30),
                    width: rect.width,
                    height: rect.height + 25,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleLockTarget(target.id),
                      child: _RealBoundingBox(
                        target: target,
                        boxHeight: rect.height,
                        isLocked: isLocked,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

// Clean Real-Time Bounding Box Widget
class _RealBoundingBox extends StatelessWidget {
  final AiDetectedTarget target;
  final double boxHeight;
  final bool isLocked;

  const _RealBoundingBox({
    required this.target,
    required this.boxHeight,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isLocked ? GcsColors.goldAccent : GcsColors.warningOrange;

    return Stack(
      children: [
        // Top Classification & Confidence Badge
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: activeColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${target.label} ${(target.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                    decoration: BoxDecoration(
                      color: GcsColors.goldAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'LOCK',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Corner Brackets Tactical Box
        Positioned(
          top: 18,
          left: 0,
          right: 0,
          height: boxHeight,
          child: CustomPaint(
            painter: _CleanBoxPainter(
              color: activeColor,
              isLocked: isLocked,
            ),
          ),
        ),
      ],
    );
  }
}

// Clean Corner Brackets Painter
class _CleanBoxPainter extends CustomPainter {
  final Color color;
  final bool isLocked;

  _CleanBoxPainter({
    required this.color,
    required this.isLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bracketPaint = Paint()
      ..color = color
      ..strokeWidth = isLocked ? 2.0 : 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fillPaint);

    final bracketLen = min(12.0, min(size.width, size.height) * 0.25);

    // 4 Corner Brackets
    canvas.drawLine(const Offset(0, 0), Offset(bracketLen, 0), bracketPaint);
    canvas.drawLine(const Offset(0, 0), Offset(0, bracketLen), bracketPaint);

    canvas.drawLine(Offset(size.width, 0), Offset(size.width - bracketLen, 0), bracketPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, bracketLen), bracketPaint);

    canvas.drawLine(Offset(0, size.height), Offset(bracketLen, size.height), bracketPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - bracketLen), bracketPaint);

    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - bracketLen, size.height), bracketPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - bracketLen), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant _CleanBoxPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isLocked != isLocked;
  }
}
