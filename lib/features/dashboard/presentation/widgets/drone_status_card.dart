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
  // Slider: Altitude limited (ML values: 10 to 300 ML)
  double _altitudeMl = 200.0;
  final List<double> _altitudeSteps = [10.0, 50.0, 100.0, 150.0, 200.0, 250.0, 300.0];

  // Precision Throttle Slider & Directional Gimbal State (Mode 2 UAV)
  double _throttlePercent = 50.0;
  Offset _rightStickPos = Offset.zero; // Pitch (Y), Roll (X)

  void _updateControls(BuildContext context) {
    final mavlink = context.read<MavlinkService>();
    final throttleRatio = (_throttlePercent / 50.0 - 1.0).clamp(-1.0, 1.0);
    final pitch = -(_rightStickPos.dy / 36.0).clamp(-1.0, 1.0);
    final roll = (_rightStickPos.dx / 36.0).clamp(-1.0, 1.0);

    mavlink.setThrottle(_throttlePercent);
    mavlink.simulator.setManualInputs(
      throttle: throttleRatio,
      pitch: pitch,
      roll: roll,
      yaw: 0.0,
    );
  }

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
          // 1. Battery Telemetry Section
          _buildBatterySection(vehicle),

          // 2. Flight Control Deck (Tall Throttle Slider + Aerospace Gimbal + Arm/ESTOP)
          _buildFlightControlDeck(mavlink, vehicle),

          // 3. Altitude Limited Slider Section
          _buildAltitudeSection(vehicle),
        ],
      ),
    );
  }

  // 1. Battery Section
  Widget _buildBatterySection(VehicleState vehicle) {
    final batteryPct = vehicle.batteryRemaining > 0 ? vehicle.batteryRemaining : 50;
    final mahCurrent = (batteryPct / 100 * 4366).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Battery',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2430),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12, width: 0.8),
              ),
              child: const Text(
                '4S LIPO',
                style: TextStyle(
                  color: Color(0xFF8896A6),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13171E),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: CustomPaint(
            painter: _CornerBracketsPainter(
              color: Colors.white60,
              bracketLength: 6.0,
              strokeWidth: 1.2,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Battery Cell Gauge
                  Container(
                    width: 22,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFA7B35), width: 1.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    padding: const EdgeInsets.all(1.5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (batteryPct / 100.0).clamp(0.1, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFA7B35),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$batteryPct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$mahCurrent / 4366 mAh',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 1, height: 14, color: Colors.white24),
                  const SizedBox(width: 10),
                  const Text(
                    '27°C',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
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
    );
  }

  // 2. Flight Control Deck (Seamless integration without artificial sub-box)
  Widget _buildFlightControlDeck(MavlinkService mavlink, VehicleState vehicle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode & Arm Quick Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Arm / Disarm Status Button
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                if (vehicle.isArmed) {
                  mavlink.disarmVehicle();
                } else {
                  mavlink.armVehicle();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: vehicle.isArmed ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: (vehicle.isArmed ? Colors.red : Colors.green).withValues(alpha: 0.35),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vehicle.isArmed ? Icons.lock_open : Icons.lock,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      vehicle.isArmed ? 'ARMED' : 'DISARMED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Emergency Stop Button
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => mavlink.emergencyStop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF191D26),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFA7B35).withValues(alpha: 0.6), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA7B35).withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFFA7B35), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'ESTOP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Controls Row: Tall Throttle Slider (Left) + Aerospace Gimbal (Right)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tall Precision Vertical Throttle Fader
            _buildTallThrottleFader(mavlink, vehicle),

            // Subtle Technical Vertical Divider
            Container(
              width: 1,
              height: 155,
              color: Colors.white12,
            ),

            // Aerospace Gimbal Joystick (Pitch & Roll)
            _buildAerospaceGimbal(
              title: 'PITCH / ROLL',
              position: _rightStickPos,
              upLabel: 'FWD ▲',
              downLabel: 'REV ▼',
              leftLabel: '◀ L',
              rightLabel: 'R ▶',
              knobColor: const Color(0xFF20DFB3),
              onPanUpdate: (d) => setState(() {
                _rightStickPos = Offset(
                  (_rightStickPos.dx + d.delta.dx).clamp(-34.0, 34.0),
                  (_rightStickPos.dy + d.delta.dy).clamp(-34.0, 34.0),
                );
                _updateControls(context);
              }),
              onPanEnd: (d) => setState(() {
                _rightStickPos = Offset.zero; // Full spring return to center
                _updateControls(context);
              }),
            ),
          ],
        ),
      ],
    );
  }

  // Tall Precision Throttle Slider Widget
  Widget _buildTallThrottleFader(MavlinkService mavlink, VehicleState vehicle) {
    const faderHeight = 175.0;
    const faderWidth = 58.0;
    const knobHeight = 24.0;
    const knobWidth = 44.0;
    const topMargin = 14.0;
    const bottomMargin = 14.0;
    const availableTravel = faderHeight - topMargin - bottomMargin - knobHeight;

    final ratio = (_throttlePercent / 100.0).clamp(0.0, 1.0);
    // top is 100%, bottom is 0%
    final knobTop = (1.0 - ratio) * availableTravel + topMargin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFFA7B35),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'THR: ${_throttlePercent.toInt()}%',
              style: const TextStyle(
                color: Color(0xFFFA7B35),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            final localY = details.localPosition.dy;
            final trackRatio = (1.0 - ((localY - topMargin) / availableTravel)).clamp(0.0, 1.0);
            setState(() {
              _throttlePercent = (trackRatio * 100.0).roundToDouble();
            });
            _updateControls(context);
          },
          onTapDown: (details) {
            final localY = details.localPosition.dy;
            final trackRatio = (1.0 - ((localY - topMargin) / availableTravel)).clamp(0.0, 1.0);
            setState(() {
              _throttlePercent = (trackRatio * 100.0).roundToDouble();
            });
            _updateControls(context);
          },
          child: Container(
            width: faderWidth,
            height: faderHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF11151C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ladder Ruler & Slot Painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ThrottleFaderTrackPainter(
                      tickCount: 24,
                      topMargin: topMargin,
                      bottomMargin: bottomMargin,
                    ),
                  ),
                ),

                // Brushed Chrome Metallic Fader Knob
                Positioned(
                  top: knobTop,
                  child: _buildChromeFaderKnob(knobWidth, knobHeight),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Brushed Chrome Metallic Fader Knob
  Widget _buildChromeFaderKnob(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFE2E8F0),
            Color(0xFFCBD5E1),
            Color(0xFF94A3B8),
            Color(0xFF64748B),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        border: Border.all(color: const Color(0xFFF8FAFC), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFFA7B35).withValues(alpha: 0.25),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dark Center Grip Recess
          Container(
            width: width * 0.72,
            height: 3.2,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(1.6),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white30,
                  offset: Offset(0, 1),
                  blurRadius: 0.5,
                ),
              ],
            ),
          ),
          // Top & Bottom Indicator Marks
          Positioned(
            top: 2.5,
            child: Container(
              width: 2.5,
              height: 2.5,
              decoration: const BoxDecoration(
                color: Color(0xFFFA7B35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 2.5,
            child: Container(
              width: 2.5,
              height: 2.5,
              decoration: const BoxDecoration(
                color: Color(0xFFFA7B35),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Aerospace Gimbal Joystick Widget
  Widget _buildAerospaceGimbal({
    required String title,
    required Offset position,
    required String upLabel,
    required String downLabel,
    required String leftLabel,
    required String rightLabel,
    required Color knobColor,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    const double stickDiameter = 110.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: GcsColors.textMuted,
            fontSize: 9.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          child: Container(
            width: stickDiameter,
            height: stickDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF252B36),
                  Color(0xFF191D24),
                  Color(0xFF0F1217),
                ],
              ),
              border: Border.all(color: Colors.white24, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Precision Crosshairs & Radar Concentric Rings
                CustomPaint(
                  size: const Size(stickDiameter, stickDiameter),
                  painter: _AerospaceGimbalPainter(),
                ),

                // Axis Labels
                Positioned(
                  top: 3,
                  child: Text(
                    upLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  bottom: 3,
                  child: Text(
                    downLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  left: 4,
                  child: Text(
                    leftLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 6.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  right: 4,
                  child: Text(
                    rightLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 6.5, fontWeight: FontWeight.bold),
                  ),
                ),

                // Interactive Gimbal Thumb Knob
                Transform.translate(
                  offset: Offset(
                    position.dx.clamp(-32.0, 32.0),
                    position.dy.clamp(-32.0, 32.0),
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          knobColor,
                          knobColor.withValues(alpha: 0.8),
                          const Color(0xFF13171E),
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: knobColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Altitude Limited Section
  Widget _buildAltitudeSection(VehicleState vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Altitude limited',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
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
                const thumbWidth = 22.0;
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

          // Value Readout (e.g. 200 ML)
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
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, bracketLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for Aerospace Gimbal Crosshair Radar
class _AerospaceGimbalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final crosshairPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;

    // Crosshairs
    canvas.drawLine(Offset(10, center.dy), Offset(size.width - 10, center.dy), crosshairPaint);
    canvas.drawLine(Offset(center.dx, 10), Offset(center.dx, size.height - 10), crosshairPaint);

    // Concentric Deflection Rings
    final ringPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Inner 33% deflection ring
    canvas.drawCircle(center, size.width * 0.18, ringPaint);
    // Mid 66% deflection ring
    ringPaint.color = Colors.white12;
    canvas.drawCircle(center, size.width * 0.32, ringPaint);
    // Outer boundary ring
    ringPaint.color = Colors.white24;
    ringPaint.strokeWidth = 1.0;
    canvas.drawCircle(center, size.width * 0.44, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for Tall Vertical Throttle Slider Ladder
class _ThrottleFaderTrackPainter extends CustomPainter {
  final int tickCount;
  final double topMargin;
  final double bottomMargin;

  const _ThrottleFaderTrackPainter({
    this.tickCount = 24,
    this.topMargin = 14.0,
    this.bottomMargin = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final topY = topMargin;
    final bottomY = size.height - bottomMargin;
    final trackHeight = bottomY - topY;

    // Header Markers: '-' on Left, '+' on Right
    final headerPaint = Paint()
      ..color = Colors.white60
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Left '-'
    canvas.drawLine(Offset(centerX - 18, topY - 4), Offset(centerX - 8, topY - 4), headerPaint);

    // Right '+'
    canvas.drawLine(Offset(centerX + 8, topY - 4), Offset(centerX + 18, topY - 4), headerPaint);
    canvas.drawLine(Offset(centerX + 13, topY - 9), Offset(centerX + 13, topY + 1), headerPaint);

    // Center Vertical Slot Channel
    final slotPaint = Paint()
      ..color = const Color(0xFF080A0D)
      ..style = PaintingStyle.fill;
    final slotBorder = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final slotRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(centerX - 3.0, topY - 2, centerX + 3.0, bottomY + 2),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(slotRect, slotPaint);
    canvas.drawRRect(slotRect, slotBorder);

    // Vertical Center Guide Wire
    final guideWirePaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(centerX, topY), Offset(centerX, bottomY), guideWirePaint);

    // Graduated Ladder Tick Marks on Left and Right
    final tickPaint = Paint()..strokeCap = StrokeCap.square;

    for (int i = 0; i <= tickCount; i++) {
      final y = topY + (i / tickCount) * trackHeight;
      final isMajor = (i % 4 == 0);
      final isMid = (i % 2 == 0);
      final tickLen = isMajor ? 9.5 : (isMid ? 6.0 : 3.5);

      tickPaint.color = isMajor ? Colors.white60 : (isMid ? Colors.white24 : Colors.white10);
      tickPaint.strokeWidth = isMajor ? 1.2 : 0.8;

      // Left tick
      canvas.drawLine(Offset(centerX - 5.0 - tickLen, y), Offset(centerX - 5.0, y), tickPaint);
      // Right tick
      canvas.drawLine(Offset(centerX + 5.0, y), Offset(centerX + 5.0 + tickLen, y), tickPaint);
    }

    // Bottom Base Ticks
    canvas.drawLine(Offset(centerX - 18, bottomY + 5), Offset(centerX - 8, bottomY + 5), headerPaint);
    canvas.drawLine(Offset(centerX + 8, bottomY + 5), Offset(centerX + 18, bottomY + 5), headerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
