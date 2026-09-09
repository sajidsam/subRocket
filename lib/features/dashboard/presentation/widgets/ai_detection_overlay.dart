import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

enum AiTargetCategory {
  person('PERSON', Icons.person_outline, GcsColors.cyanAccent),
  vehicle('VEHICLE', Icons.directions_car_outlined, GcsColors.warningOrange),
  drone('UAV / DRONE', Icons.flight_outlined, GcsColors.channelBlue),
  landingPad('LANDING PAD', Icons.crop_free, GcsColors.channelGreen),
  obstacle('OBSTACLE / HAZARD', Icons.warning_amber_rounded, GcsColors.channelRed);

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

class _AiDetectionOverlayState extends State<AiDetectionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String? _lockedTargetId;
  String _selectedFilter = 'ALL';

  final List<AiDetectedTarget> _defaultTargets = const [
    AiDetectedTarget(
      id: 'TRK-01',
      category: AiTargetCategory.person,
      label: 'PERSON',
      confidence: 0.964,
      baseDistanceMeters: 18.5,
      speedKmh: 4.8,
      normalizedRect: Rect.fromLTWH(0.20, 0.32, 0.16, 0.38),
      phaseOffset: 0.0,
    ),
    AiDetectedTarget(
      id: 'TRK-02',
      category: AiTargetCategory.vehicle,
      label: 'VEHICLE (SUV)',
      confidence: 0.942,
      baseDistanceMeters: 45.2,
      speedKmh: 28.5,
      normalizedRect: Rect.fromLTWH(0.58, 0.42, 0.24, 0.28),
      phaseOffset: 1.5,
    ),
    AiDetectedTarget(
      id: 'TRK-03',
      category: AiTargetCategory.landingPad,
      label: 'LANDING PAD LZ-A',
      confidence: 0.991,
      baseDistanceMeters: 29.0,
      speedKmh: 0.0,
      normalizedRect: Rect.fromLTWH(0.40, 0.68, 0.18, 0.18),
      phaseOffset: 3.0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final activeTargets = _defaultTargets.where((t) {
          if (_selectedFilter == 'ALL') return true;
          if (_selectedFilter == 'PERSONS') return t.category == AiTargetCategory.person;
          if (_selectedFilter == 'VEHICLES') return t.category == AiTargetCategory.vehicle;
          if (_selectedFilter == 'LZ / PADS') return t.category == AiTargetCategory.landingPad;
          return true;
        }).toList();

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final animVal = _animController.value;
            // Laser scanline vertical position
            final scanY = (animVal * (height + 40)) - 20;

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Subtle Laser Scan Beam
                IgnorePointer(
                  child: CustomPaint(
                    painter: _AiScanlinePainter(scanY: scanY, width: width, height: height),
                  ),
                ),

                // 2. Detected Object Bounding Boxes
                ...activeTargets.map((target) {
                  final isLocked = _lockedTargetId == target.id;
                  // Dynamic subtle micro-movement simulation
                  final t = animVal * 2 * pi + target.phaseOffset;
                  final dx = sin(t) * 4.0;
                  final dy = cos(t * 0.8) * 3.0;

                  final rect = Rect.fromLTWH(
                    (target.normalizedRect.left * width + dx).clamp(4.0, width - 60),
                    (target.normalizedRect.top * height + dy).clamp(4.0, height - 60),
                    (target.normalizedRect.width * width).clamp(40.0, width),
                    (target.normalizedRect.height * height).clamp(40.0, height),
                  );

                  return Positioned(
                    left: rect.left,
                    top: (rect.top - 24).clamp(0.0, height - 80),
                    width: rect.width,
                    height: rect.height + 44,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleLockTarget(target.id),
                      child: _AiBoundingBox(
                        target: target,
                        boxHeight: rect.height,
                        isLocked: isLocked,
                        pulseValue: sin(animVal * 4 * pi),
                      ),
                    ),
                  );
                }),

                // 3. Top-Center AI Neural Engine Telemetry Strip
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: GcsColors.cyanAccent.withValues(alpha: 0.6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GcsColors.cyanAccent.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsing AI Online Indicator
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: GcsColors.cyanAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: GcsColors.cyanAccent.withValues(
                                    alpha: 0.5 + 0.5 * sin(animVal * 4 * pi).abs(),
                                  ),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'AI VISION ACTIVE',
                            style: TextStyle(
                              color: GcsColors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 10, color: Colors.white24),
                          const SizedBox(width: 8),
                          Text(
                            'YOLOv8-UAV • 60 FPS • 12ms',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _lockedTargetId != null
                                  ? GcsColors.goldAccent.withValues(alpha: 0.3)
                                  : GcsColors.cyanAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _lockedTargetId != null
                                  ? 'TARGET LOCKED: $_lockedTargetId'
                                  : '${activeTargets.length} TARGETS',
                              style: TextStyle(
                                color: _lockedTargetId != null
                                    ? GcsColors.goldAccent
                                    : GcsColors.cyanAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Quick Target Filter Bar (Top Center-Left below top bar)
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFilterChip('ALL'),
                            _buildFilterChip('PERSONS'),
                            _buildFilterChip('VEHICLES'),
                            _buildFilterChip('LZ / PADS'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? GcsColors.cyanAccent.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? GcsColors.cyanAccent : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? GcsColors.cyanAccent : Colors.white60,
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// Tactical Bounding Box Widget
class _AiBoundingBox extends StatelessWidget {
  final AiDetectedTarget target;
  final double boxHeight;
  final bool isLocked;
  final double pulseValue;

  const _AiBoundingBox({
    required this.target,
    required this.boxHeight,
    required this.isLocked,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isLocked ? GcsColors.goldAccent : target.category.color;

    return Stack(
      children: [
        // Top Classification & Confidence Pill
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: activeColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(target.category.icon, size: 10, color: activeColor),
                const SizedBox(width: 4),
                Text(
                  '${target.id} ${target.label}',
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(target.confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
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

        // Corner Brackets & Inner Glow Box
        Positioned(
          top: 22,
          left: 0,
          right: 0,
          height: boxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _TacticalBoxPainter(
                  color: activeColor,
                  isLocked: isLocked,
                  pulseAlpha: (0.6 + 0.4 * pulseValue.abs()).clamp(0.2, 1.0),
                ),
              ),
              Center(
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: activeColor.withValues(alpha: isLocked ? 0.9 : 0.4),
                ),
              ),
            ],
          ),
        ),

        // Bottom Telemetry Pill (Range & Speed)
        Positioned(
          top: 24 + boxHeight + 2,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: activeColor.withValues(alpha: 0.5), width: 0.8),
            ),
            child: Text(
              'RNG: ${target.baseDistanceMeters.toStringAsFixed(1)}m | VEL: ${target.speedKmh.toStringAsFixed(1)}km/h',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 8,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Tactical Corner Brackets Painter
class _TacticalBoxPainter extends CustomPainter {
  final Color color;
  final bool isLocked;
  final double pulseAlpha;

  _TacticalBoxPainter({
    required this.color,
    required this.isLocked,
    required this.pulseAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bracketPaint = Paint()
      ..color = color.withValues(alpha: pulseAlpha)
      ..strokeWidth = isLocked ? 2.2 : 1.6
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isLocked ? 0.12 : 0.05)
      ..style = PaintingStyle.fill;

    // Fill subtle tinted box
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fillPaint);

    final bracketLen = min(14.0, min(size.width, size.height) * 0.3);

    // Top-Left Corner
    canvas.drawLine(const Offset(0, 0), Offset(bracketLen, 0), bracketPaint);
    canvas.drawLine(const Offset(0, 0), Offset(0, bracketLen), bracketPaint);

    // Top-Right Corner
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - bracketLen, 0), bracketPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, bracketLen), bracketPaint);

    // Bottom-Left Corner
    canvas.drawLine(Offset(0, size.height), Offset(bracketLen, size.height), bracketPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - bracketLen), bracketPaint);

    // Bottom-Right Corner
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - bracketLen, size.height), bracketPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - bracketLen), bracketPaint);

    // If locked, draw outer target tracking reticle brackets
    if (isLocked) {
      final lockPaint = Paint()
        ..color = GcsColors.goldAccent.withValues(alpha: pulseAlpha)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final pad = 5.0;
      canvas.drawRect(
        Rect.fromLTWH(-pad, -pad, size.width + pad * 2, size.height + pad * 2),
        lockPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TacticalBoxPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.pulseAlpha != pulseAlpha;
  }
}

// Laser Scanning Line Painter
class _AiScanlinePainter extends CustomPainter {
  final double scanY;
  final double width;
  final double height;

  _AiScanlinePainter({
    required this.scanY,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scanY < 0 || scanY > height) return;

    final linePaint = Paint()
      ..color = GcsColors.cyanAccent.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Scan line
    canvas.drawLine(Offset(0, scanY), Offset(width, scanY), linePaint);

    // Scan gradient trail above line
    final trailRect = Rect.fromLTWH(0, max(0, scanY - 30), width, min(scanY, 30));
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        GcsColors.cyanAccent.withValues(alpha: 0.0),
        GcsColors.cyanAccent.withValues(alpha: 0.15),
      ],
    );

    final fillPaint = Paint()..shader = gradient.createShader(trailRect);
    canvas.drawRect(trailRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _AiScanlinePainter oldDelegate) {
    return oldDelegate.scanY != scanY;
  }
}
