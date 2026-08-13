import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/flight_mode.dart';
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
    final pitch = -(_rightStickPos.dy / 22.0).clamp(-1.0, 1.0);
    final roll = (_rightStickPos.dx / 22.0).clamp(-1.0, 1.0);

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Battery Telemetry Section (Exact Reference Image Match)
          _buildBatterySection(vehicle),

          const SizedBox(height: 4),

          // 2. ArduPilot / Drone Flight Telemetry Grid (GSPD, VSPD, ALT, RTH, GPS, MODE)
          _buildFlightTelemetryGrid(vehicle),

          const SizedBox(height: 6),

          // 3. Flight Control Deck (2x Bigger Redesigned Aerospace Speed Slider + Aerospace Gimbal)
          Expanded(
            child: _buildFlightControlDeck(mavlink, vehicle),
          ),

          const SizedBox(height: 6),

          // 4. Altitude Limit Slider Section
          _buildAltitudeSection(vehicle),
        ],
      ),
    );
  }

  // 1. Battery Section (Exact Reference Image Match)
  Widget _buildBatterySection(VehicleState vehicle) {
    final batteryPct = vehicle.batteryRemaining > 0 ? vehicle.batteryRemaining : 50;
    final mahCurrent = (batteryPct / 100 * 4366).toInt();

    return CustomPaint(
      painter: _CornerBracketsPainter(
        color: Colors.white70,
        bracketLength: 8.0,
        strokeWidth: 1.5,
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1E222A),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            // Tactical Orange Battery Cell
            _TacticalBatteryIcon(percent: batteryPct),
            const SizedBox(width: 8),
            Text(
              '$batteryPct%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            Text(
              '$mahCurrent / 4366 Mah',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: Colors.white24),
            const SizedBox(width: 12),
            const Text(
              '27°C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. ArduPilot / Drone Flight Telemetry Grid (GSPD, VSPD, ALT with pure white font)
  Widget _buildFlightTelemetryGrid(VehicleState vehicle) {
    final gspd = (vehicle.groundspeed > 0 ? vehicle.groundspeed : 12.4).toStringAsFixed(1);
    final vspd = '${vehicle.climbRate >= 0 ? '+' : ''}${vehicle.climbRate.toStringAsFixed(1)}';
    final alt = (vehicle.altitudeAgl > 0 ? vehicle.altitudeAgl : 45.2).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Flight Telemetry',
          style: TextStyle(
            color: GcsColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF13171F),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTelemCell('GSPD', '$gspd m/s', Colors.white)),
              Container(width: 1, height: 22, color: Colors.white12),
              Expanded(child: _buildTelemCell('VSPD', '$vspd m/s', Colors.white)),
              Container(width: 1, height: 22, color: Colors.white12),
              Expanded(child: _buildTelemCell('ALT', '$alt m', Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelemCell(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GcsColors.textMuted,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // 2. Flight Control Deck (2x Bigger Speed Throttle on Left, Pitch/Roll + ESTOP/RTH on Right)
  Widget _buildFlightControlDeck(MavlinkService mavlink, VehicleState vehicle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: 2x Bigger Aerospace Speed / Throttle Slider (utilizing vertical space)
        Expanded(
          child: _buildAerospaceSpeedSlider(mavlink, vehicle),
        ),

        // Subtle Technical Vertical Divider
        Container(
          width: 1,
          height: 280,
          color: Colors.white12,
        ),

        // Right Column: Pitch/Roll 3D Button in original position + ESTOP & RTH directly beneath
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAerospaceGimbal(
                title: 'PITCH / ROLL',
                position: _rightStickPos,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEstopButton(mavlink),
                  const SizedBox(width: 8),
                  _buildRthButton(mavlink, vehicle),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Emergency Stop (ESTOP) Button
  Widget _buildEstopButton(MavlinkService mavlink) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => mavlink.emergencyStop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF181B22),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFA7B35).withValues(alpha: 0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFA7B35).withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFA7B35), size: 13),
            SizedBox(width: 5),
            Text(
              'ESTOP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Return to Home (RTH) Button (vertically aligned with ESTOP under Pitch/Roll)
  Widget _buildRthButton(MavlinkService mavlink, VehicleState vehicle) {
    final isRtl = vehicle.mode == FlightMode.rtl;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        mavlink.setFlightMode(FlightMode.rtl);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isRtl ? const Color(0xFF2C3545) : const Color(0xFF181B22),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isRtl ? const Color(0xFF20DFB3) : Colors.white24,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isRtl
                  ? const Color(0xFF20DFB3).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_outlined,
              color: isRtl ? const Color(0xFF20DFB3) : Colors.white70,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              'RTH',
              style: TextStyle(
                color: isRtl ? const Color(0xFF20DFB3) : Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getThrottleStatusColor(double percent) {
    if (percent <= 0) {
      return const Color(0xFFFFC107); // Yellow when throttle is 0
    } else if (percent < 80) {
      return const Color(0xFF00E676); // Green when throttle is increasing / active
    } else {
      return const Color(0xFFFF3D00); // Red when throttle reaches / approaches max
    }
  }

  // 2x Bigger Monochrome Black & White Vertical Speed / Throttle Slider (30px reduced height, wider modern handle)
  Widget _buildAerospaceSpeedSlider(MavlinkService mavlink, VehicleState vehicle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final faderHeight = (constraints.maxHeight.isFinite && constraints.maxHeight > 200
            ? constraints.maxHeight - 30.0
            : 330.0).clamp(220.0, 420.0);
        const faderWidth = 126.0;
        const knobHeight = 36.0;
        const knobWidth = 64.0;
        const topMargin = 14.0;
        const bottomMargin = 14.0;
        const trackCenterX = 56.0;
        final availableTravel = faderHeight - topMargin - bottomMargin - knobHeight;

        final ratio = (_throttlePercent / 100.0).clamp(0.0, 1.0);
        final knobTop = (1.0 - ratio) * availableTravel + topMargin;
        final statusColor = _getThrottleStatusColor(_throttlePercent);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            final localY = details.localPosition.dy;
            final trackRatio = (1.0 - ((localY - topMargin - (knobHeight / 2)) / availableTravel)).clamp(0.0, 1.0);
            setState(() {
              _throttlePercent = (trackRatio * 100.0).roundToDouble();
            });
            _updateControls(context);
          },
          onTapDown: (details) {
            final localY = details.localPosition.dy;
            final trackRatio = (1.0 - ((localY - topMargin - (knobHeight / 2)) / availableTravel)).clamp(0.0, 1.0);
            setState(() {
              _throttlePercent = (trackRatio * 100.0).roundToDouble();
            });
            _updateControls(context);
          },
          child: SizedBox(
            width: faderWidth,
            height: faderHeight,
            child: Stack(
              children: [
                // Precision Monochrome Track with Right-side Ruler Scale
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AerospaceSpeedSliderTrackPainter(
                      throttlePercent: _throttlePercent,
                      topMargin: topMargin,
                      bottomMargin: bottomMargin,
                      centerX: trackCenterX,
                    ),
                  ),
                ),

                // Metallic Silver / White Fader Knob Handle with Status Circle LED Jewel
                Positioned(
                  left: trackCenterX - (knobWidth / 2),
                  top: knobTop,
                  child: _buildAerospaceFaderKnob(knobWidth, knobHeight, statusColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modern Ergonomic 3D Brushed Silver Fader Knob Handle (No glow, clean precision styling)
  Widget _buildAerospaceFaderKnob(double width, double height, Color statusColor) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF), // pure crisp silver/white top sheen
            Color(0xFFE5EBF4), // brushed satin silver
            Color(0xFFCAD4E2), // metallic body
            Color(0xFF98A6BA), // dark silver bottom edge
          ],
          stops: [0.0, 0.28, 0.72, 1.0],
        ),
        border: Border.all(color: const Color(0xFFBAC7D8), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left side crisp tactile grip ribs
          Positioned(
            left: 3.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 2.2, height: 4.5, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(1))),
                const SizedBox(height: 3),
                Container(width: 2.2, height: 4.5, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(1))),
              ],
            ),
          ),

          // Right side crisp tactile grip ribs
          Positioned(
            right: 3.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 2.2, height: 4.5, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(1))),
                const SizedBox(height: 3),
                Container(width: 2.2, height: 4.5, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(1))),
              ],
            ),
          ),

          // Center horizontal index groove line (precision dark graphite)
          Container(
            width: width * 0.52,
            height: 1.6,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          // Center Status LED Jewel Indicator (No blur glow, clean modern bezel)
          Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
            ),
            child: Center(
              child: Container(
                width: 2.2,
                height: 2.2,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3D Black Circular Tactile Joystick matching Image Reference (Pitch & Roll)
  Widget _buildAerospaceGimbal({
    required String title,
    required Offset position,
  }) {
    const double stickDiameter = 120.0;
    const double maxTravel = 22.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: GcsColors.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) {
            final center = const Offset(stickDiameter / 2, stickDiameter / 2);
            final delta = d.localPosition - center;
            final clamped = delta.distance > maxTravel
                ? delta * (maxTravel / delta.distance)
                : delta;
            setState(() {
              _rightStickPos = clamped;
              _updateControls(context);
            });
          },
          onPanUpdate: (d) {
            final center = const Offset(stickDiameter / 2, stickDiameter / 2);
            final delta = d.localPosition - center;
            final clamped = delta.distance > maxTravel
                ? delta * (maxTravel / delta.distance)
                : delta;
            setState(() {
              _rightStickPos = clamped;
              _updateControls(context);
            });
          },
          onPanEnd: (d) => setState(() {
            _rightStickPos = Offset.zero; // Full spring return to center
            _updateControls(context);
          }),
          onPanCancel: () => setState(() {
            _rightStickPos = Offset.zero;
            _updateControls(context);
          }),
          child: SizedBox(
            width: stickDiameter,
            height: stickDiameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. 3D Black Base Socket with 4 Outer White Chevron Arrows
                CustomPaint(
                  size: const Size(stickDiameter, stickDiameter),
                  painter: _TactileBlackPitchRollBasePainter(
                    offset: position,
                  ),
                ),

                // 2. Movable 3D Big Button (Draggable in all directions: Up, Down, Left, Right)
                Transform.translate(
                  offset: position,
                  child: _buildTactileBigButton(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3D Movable Tactile Big Button (Pitch & Roll Knob matching user reference)
  Widget _buildTactileBigButton() {
    const double buttonSize = 72.0;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        size: const Size(buttonSize, buttonSize),
        painter: _TactileBigButtonPainter(
          isDeflected: _rightStickPos != Offset.zero,
        ),
      ),
    );
  }

  // 3. Altitude Limit Section
  Widget _buildAltitudeSection(VehicleState vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Altitude limit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
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
        const SizedBox(height: 2),
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

// Interactive Ruler Slider Track with Orange Handle & Readout (Compact Size)
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
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF13171E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          // Slider Track with Ticks & Sliding Handle
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                const thumbWidth = 20.0;
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
                            borderRadius: BorderRadius.circular(3),
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
                                Container(width: 1.0, height: 10, color: const Color(0xFF1E222A)),
                                const SizedBox(width: 2.0),
                                Container(width: 1.0, height: 10, color: const Color(0xFF1E222A)),
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
          Container(width: 1, height: 18, color: Colors.white24),

          // Value Readout (e.g. 200 ML)
          Container(
            width: 58,
            alignment: Alignment.center,
            child: Text(
              '${value.round()} $unit',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
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

// Tactical Battery Cell Icon with terminal tip
class _TacticalBatteryIcon extends StatelessWidget {
  final int percent;

  const _TacticalBatteryIcon({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 12,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            width: 20,
            height: 12,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFA7B35), width: 1.4),
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.all(1.5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (percent / 100.0).clamp(0.1, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFA7B35),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 3.5,
            bottom: 3.5,
            width: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFA7B35),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(1),
                  bottomRight: Radius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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

// Custom Painter for 3D Black Circular Base Socket with 4 White Chevron Arrows
class _TactileBlackPitchRollBasePainter extends CustomPainter {
  final Offset offset;

  const _TactileBlackPitchRollBasePainter({this.offset = Offset.zero});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rOuterBezel = size.width * 0.40; // 48.0 on 120
    final rSocketCavity = size.width * 0.35; // 42.0 on 120
    final rArrow = size.width * 0.46; // 55.2 on 120

    // 1. Ambient Drop Shadow under outer bezel socket
    final ambientShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(center + const Offset(0, 3), rOuterBezel, ambientShadowPaint);

    // 2. Outer Bezel Socket Ring (smooth dark metallic socket rim)
    final bezelGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2C323E), // highlight rim top-left
        Color(0xFF1B1F27),
        Color(0xFF0F1116), // deep shadow bottom-right
      ],
      stops: [0.0, 0.45, 1.0],
    );
    final bezelPaint = Paint()
      ..shader = bezelGradient.createShader(Rect.fromCircle(center: center, radius: rOuterBezel));
    canvas.drawCircle(center, rOuterBezel, bezelPaint);

    // Outer bezel crisp stroke rim
    final bezelRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4A5568),
          Color(0xFF1E232B),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: rOuterBezel));
    canvas.drawCircle(center, rOuterBezel, bezelRimPaint);

    // 3. Recessed Socket Well / Cavity (dark deep pocket where the big button sits and moves)
    final cavityGradient = const RadialGradient(
      center: Alignment(0.0, 0.1),
      radius: 0.95,
      colors: [
        Color(0xFF050608),
        Color(0xFF0A0C10),
        Color(0xFF14171E),
      ],
      stops: [0.0, 0.6, 1.0],
    );
    final cavityPaint = Paint()
      ..shader = cavityGradient.createShader(Rect.fromCircle(center: center, radius: rSocketCavity));
    canvas.drawCircle(center, rSocketCavity, cavityPaint);

    // Inner cavity shadow stroke
    final cavityRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF050608);
    canvas.drawCircle(center, rSocketCavity, cavityRimPaint);

    // 4. Four Directional Chevron Arrows (White)
    final isUp = offset.dy < -4.0;
    final isDown = offset.dy > 4.0;
    final isLeft = offset.dx < -4.0;
    final isRight = offset.dx > 4.0;

    _drawChevron(canvas, Offset(center.dx, center.dy - rArrow), 0, isUp);
    _drawChevron(canvas, Offset(center.dx + rArrow, center.dy), pi / 2, isRight);
    _drawChevron(canvas, Offset(center.dx, center.dy + rArrow), pi, isDown);
    _drawChevron(canvas, Offset(center.dx - rArrow, center.dy), -pi / 2, isLeft);
  }

  void _drawChevron(Canvas canvas, Offset pos, double angle, bool isPressed) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    const halfW = 6.0;
    const halfH = 4.0;

    final path = Path()
      ..moveTo(-halfW, halfH)
      ..lineTo(0, -halfH)
      ..lineTo(halfW, halfH);

    if (isPressed) {
      // Pressed arrow glow
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawPath(path, glowPaint);
    }

    final arrowPaint = Paint()
      ..color = isPressed ? Colors.white : Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, arrowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TactileBlackPitchRollBasePainter oldDelegate) =>
      oldDelegate.offset != offset;
}

// Custom Painter for 3D Movable Big Tactile Button (Pitch & Roll Knob)
class _TactileBigButtonPainter extends CustomPainter {
  final bool isDeflected;

  const _TactileBigButtonPainter({this.isDeflected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rOuter = size.width / 2; // 36.0
    final rDish = size.width * 0.32; // 23.0 concave center depression

    // 1. Main Convex 3D Disc Surface (top-left metallic highlight to dark matte bottom-right)
    final discGradient = const RadialGradient(
      center: Alignment(-0.35, -0.35),
      radius: 0.95,
      colors: [
        Color(0xFF424B5D), // bright convex reflection
        Color(0xFF262C38),
        Color(0xFF161A22),
        Color(0xFF0C0E13), // deep black perimeter
      ],
      stops: [0.0, 0.35, 0.75, 1.0],
    );
    final discPaint = Paint()
      ..shader = discGradient.createShader(Rect.fromCircle(center: center, radius: rOuter));
    canvas.drawCircle(center, rOuter, discPaint);

    // Raised button outer bevel highlight rim
    final discRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF70819E), // crisp top-left highlight
          Color(0xFF2E3544),
          Color(0xFF090A0D), // dark bottom-right underside
        ],
      ).createShader(Rect.fromCircle(center: center, radius: rOuter));
    canvas.drawCircle(center, rOuter, discRimPaint);

    // 2. Subtle Concave Center Thumb Dish (Soft tactile scoop depression)
    final dishGradient = const RadialGradient(
      center: Alignment(0.30, 0.30),
      radius: 0.85,
      colors: [
        Color(0xFF28303C), // bottom-right reflection highlight
        Color(0xFF191D26),
        Color(0xFF11141B),
        Color(0xFF08090C), // top-left shadow
      ],
      stops: [0.0, 0.4, 0.75, 1.0],
    );
    final dishPaint = Paint()
      ..shader = dishGradient.createShader(Rect.fromCircle(center: center, radius: rDish));
    canvas.drawCircle(center, rDish, dishPaint);

    final dishRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF07080B),
          Color(0xFF1C212B),
          Color(0xFF3F4B5E),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: rDish));
    canvas.drawCircle(center, rDish, dishRimPaint);

    // 3. Center White Tactile Pip / Dot (Matching reference photo)
    final pipPaint = Paint()
      ..color = isDeflected ? Colors.white : Colors.white70
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.0, pipPaint);

    if (isDeflected) {
      // Glow around pip when active/dragged
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(center, 4.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TactileBigButtonPainter oldDelegate) =>
      oldDelegate.isDeflected != isDeflected;
}

// Monochrome Black & White Vertical Speed / Throttle Slider Track Painter with Right-side Scale
class _AerospaceSpeedSliderTrackPainter extends CustomPainter {
  final double throttlePercent;
  final double topMargin;
  final double bottomMargin;
  final double centerX;

  const _AerospaceSpeedSliderTrackPainter({
    required this.throttlePercent,
    this.topMargin = 16.0,
    this.bottomMargin = 16.0,
    this.centerX = 52.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final topY = topMargin;
    final bottomY = size.height - bottomMargin;
    final trackHeight = bottomY - topY;

    // 1. Vertical Slot Background (Clean rounded slot pill as in reference illustration)
    final slotRect = Rect.fromLTRB(centerX - 3.5, topY, centerX + 3.5, bottomY);
    final slotPaint = Paint()..color = const Color(0xFF08090C);
    canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(3.5)), slotPaint);

    // 2. Slot Outline (Crisp monochrome border, no glow)
    final slotBorderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(3.5)), slotBorderPaint);

    // 3. Graduated Scale Ruler Markings on the RIGHT SIDE ONLY
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const List<int> majorSteps = [100, 75, 50, 25, 0];

    // Major ticks & percentage labels on RIGHT
    for (final step in majorSteps) {
      final stepRatio = step / 100.0;
      final y = bottomY - stepRatio * trackHeight;

      // Major tick line on the right
      final tickPaint = Paint()
        ..color = Colors.white60
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(centerX + 8, y), Offset(centerX + 16, y), tickPaint);

      // Percentage number on the right side
      textPainter.text = TextSpan(
        text: '$step',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX + 20, y - textPainter.height / 2));
    }

    // Intermediate Minor Ticks (20 subdivisions) on RIGHT SIDE ONLY
    final minorTickPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 20; i++) {
      if (i % 5 == 0) continue; // skip major
      final y = topY + (i / 20.0) * trackHeight;
      canvas.drawLine(Offset(centerX + 8, y), Offset(centerX + 13, y), minorTickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AerospaceSpeedSliderTrackPainter oldDelegate) =>
      oldDelegate.throttlePercent != throttlePercent ||
      oldDelegate.centerX != centerX ||
      oldDelegate.topMargin != topMargin ||
      oldDelegate.bottomMargin != bottomMargin;
}
