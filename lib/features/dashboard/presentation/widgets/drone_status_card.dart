import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/mavlink_service.dart';

class DroneStatusCard extends StatefulWidget {
  const DroneStatusCard({super.key});

  @override
  State<DroneStatusCard> createState() => _DroneStatusCardState();
}

class _DroneStatusCardState extends State<DroneStatusCard> {
  // Slider 1: Altitude limited (ML values: 10 to 300 ML)
  double _altitudeMl = 200.0;
  final List<double> _altitudeSteps = [10.0, 50.0, 100.0, 150.0, 200.0, 250.0, 300.0];

  // Slider 2: Resolution px (px values: 2 to 14 px)
  double _resolutionPx = 8.0;
  final List<double> _resolutionSteps = [2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0];

  // Bottom 3-Segment Selector (ISO / HDR / DVR)
  String _selectedMode = 'HDR';

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final mavlink = context.watch<MavlinkService>();

    return Container(
      decoration: BoxDecoration(
        color: GcsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GcsColors.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Battery Section with Technical Corner Brackets
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Battery',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF13171E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: CustomPaint(
                  painter: _CornerBracketsPainter(
                    color: Colors.white70,
                    bracketLength: 6.0,
                    strokeWidth: 1.4,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      children: [
                        // Battery Icon
                        Container(
                          width: 20,
                          height: 11,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFA7B35), width: 1.4),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                          padding: const EdgeInsets.all(1.5),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFA7B35),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          vehicle.batteryRemaining > 0 ? '${vehicle.batteryRemaining}%' : '50%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${((vehicle.batteryRemaining > 0 ? vehicle.batteryRemaining : 50) / 100 * 4366).toInt()} / 4366 Mah',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 14, color: Colors.white24),
                        const SizedBox(width: 12),
                        const Text(
                          '27°C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Altitude Limited Slider Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Altitude limited',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              _RulerSlider(
                value: _altitudeMl,
                min: 10.0,
                max: 300.0,
                unit: 'ML',
                onChanged: (val) {
                  setState(() => _altitudeMl = val);
                  vehicle.updateGeofence(
                    enabled: vehicle.geofenceEnabled,
                    maxAlt: val,
                    maxRadius: vehicle.geofenceMaxRadius,
                  );
                },
              ),
              const SizedBox(height: 4),
              _ScaleLabelsRow(
                steps: _altitudeSteps,
                currentVal: _altitudeMl,
                unit: 'ML',
                onSelect: (val) {
                  setState(() => _altitudeMl = val);
                  vehicle.updateGeofence(
                    enabled: vehicle.geofenceEnabled,
                    maxAlt: val,
                    maxRadius: vehicle.geofenceMaxRadius,
                  );
                },
              ),
            ],
          ),

          // 3. Resolution px Slider Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Resolution px',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              _RulerSlider(
                value: _resolutionPx,
                min: 2.0,
                max: 14.0,
                unit: 'px',
                onChanged: (val) {
                  setState(() => _resolutionPx = val);
                },
              ),
              const SizedBox(height: 4),
              _ScaleLabelsRow(
                steps: _resolutionSteps,
                currentVal: _resolutionPx,
                unit: 'px',
                onSelect: (val) {
                  setState(() => _resolutionPx = val);
                },
              ),
            ],
          ),

          // 4. Bottom 3-Segment Button Bar: ISO / HDR / DVR
          Container(
            height: 38,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF13171E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: Row(
              children: [
                _buildModeTab('ISO'),
                _buildModeTab('HDR'),
                _buildModeTab('DVR'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label) {
    final isSelected = _selectedMode == label;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => setState(() => _selectedMode = label),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFA7B35) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFA7B35).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF9AA4B2),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Interactive Ruler Slider Track with Orange Handle & Readout
class _RulerSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _RulerSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF13171E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          // Slider Track with Ticks & Sliding Handle
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final thumbWidth = 22.0;
                final availableWidth = trackWidth - thumbWidth;
                final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);
                final thumbLeft = ratio * availableWidth;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    final newRatio = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                    final newVal = min + newRatio * (max - min);
                    onChanged(newVal);
                  },
                  onTapDown: (details) {
                    final newRatio = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                    final newVal = min + newRatio * (max - min);
                    onChanged(newVal);
                  },
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Ruler Ticks
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RulerTicksPainter(tickCount: 14),
                        ),
                      ),

                      // Orange Thumb Handle
                      Positioned(
                        left: thumbLeft,
                        top: 2,
                        bottom: 2,
                        child: Container(
                          width: thumbWidth,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFA7B35),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFA7B35).withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 1.2, height: 13, color: const Color(0xFF1E222A)),
                                const SizedBox(width: 2.5),
                                Container(width: 1.2, height: 13, color: const Color(0xFF1E222A)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Divider
          Container(width: 1, height: 22, color: Colors.white24),

          // Value Readout (e.g. 200 ML or 8px)
          Container(
            width: 62,
            alignment: Alignment.center,
            child: Text(
              '${value.round()} $unit',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Scale Labels Row with Teal Dot and Stepped Values
class _ScaleLabelsRow extends StatelessWidget {
  final List<double> steps;
  final double currentVal;
  final String unit;
  final ValueChanged<double> onSelect;

  const _ScaleLabelsRow({
    required this.steps,
    required this.currentVal,
    required this.unit,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          // Teal Dot
          Container(
            width: 4.5,
            height: 4.5,
            decoration: const BoxDecoration(
              color: Color(0xFF20DFB3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),

          // Stepped Scale Labels with Dashes
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: steps.map((step) {
                final isCurrent = (currentVal - step).abs() < 5;
                return InkWell(
                  onTap: () => onSelect(step),
                  child: Text(
                    '${step.toInt()}$unit',
                    style: TextStyle(
                      color: isCurrent ? Colors.white : const Color(0xFF8896A6),
                      fontSize: 8.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter for Ruler Tick Marks inside Slider Track
class _RulerTicksPainter extends CustomPainter {
  final int tickCount;

  _RulerTicksPainter({required this.tickCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    final step = size.width / (tickCount + 1);
    for (int i = 1; i <= tickCount; i++) {
      final x = i * step;
      canvas.drawLine(
        Offset(x, size.height * 0.3),
        Offset(x, size.height * 0.7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for Technical Corner Brackets
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double bracketLength;
  final double strokeWidth;

  _CornerBracketsPainter({
    required this.color,
    required this.bracketLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), Offset(bracketLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, bracketLength), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - bracketLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, bracketLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(bracketLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - bracketLength), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - bracketLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - bracketLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
