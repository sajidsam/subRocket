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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Battery Telemetry Section (Exact Reference Image Match)
          _buildBatterySection(vehicle),

          const SizedBox(height: 6),

          // 2. ArduPilot / Drone Flight Telemetry Grid (GSPD, VSPD, ALT, RTH, GPS, MODE)
          _buildFlightTelemetryGrid(vehicle),

          const SizedBox(height: 6),

          // 3. Flight Control Deck (3x Bigger Redesigned Aerospace Speed Slider + Aerospace Gimbal)
          _buildFlightControlDeck(mavlink, vehicle),

          const SizedBox(height: 6),

          // 4. Altitude Limited Slider Section
          _buildAltitudeSection(vehicle),
        ],
      ),
    );
  }

  // 1. Battery Section (Exact Reference Image Match)
  Widget _buildBatterySection(VehicleState vehicle) {
    final batteryPct = vehicle.batteryRemaining > 0 ? vehicle.batteryRemaining : 50;
    final mahCurrent = (batteryPct / 100 * 4366).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Battery',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        CustomPaint(
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
        ),
      ],
    );
  }

  // 2. ArduPilot / Drone Flight Telemetry Grid (Placed directly under Battery section)
  Widget _buildFlightTelemetryGrid(VehicleState vehicle) {
    final gspd = (vehicle.groundspeed > 0 ? vehicle.groundspeed : 12.4).toStringAsFixed(1);
    final vspd = '${vehicle.climbRate >= 0 ? '+' : ''}${vehicle.climbRate.toStringAsFixed(1)}';
    final alt = (vehicle.altitudeAgl > 0 ? vehicle.altitudeAgl : 45.2).toStringAsFixed(1);
    final rthDist = (vehicle.distanceToHome > 0 ? vehicle.distanceToHome : 184.0).toStringAsFixed(0);
    final sats = '${vehicle.satellitesVisible}';
    final modeName = vehicle.mode.name.toUpperCase();

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
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildTelemCell('GSPD', '$gspd m/s', const Color(0xFF20DFB3))),
                  Container(width: 1, height: 26, color: Colors.white12),
                  Expanded(child: _buildTelemCell('VSPD', '$vspd m/s', const Color(0xFFFA7B35))),
                  Container(width: 1, height: 26, color: Colors.white12),
                  Expanded(child: _buildTelemCell('ALT', '$alt m', Colors.white)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(color: Colors.white10, height: 1),
              ),
              Row(
                children: [
                  Expanded(child: _buildTelemCell('RTH', '$rthDist m', const Color(0xFFFFB74D))),
                  Container(width: 1, height: 26, color: Colors.white12),
                  Expanded(child: _buildTelemCell('GPS', '$sats Sats', const Color(0xFF64B5F6))),
                  Container(width: 1, height: 26, color: Colors.white12),
                  Expanded(child: _buildTelemCell('MODE', modeName, const Color(0xFF81C784))),
                ],
              ),
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

        const SizedBox(height: 8),

        // Controls Row: 3x Bigger Aerospace Speed Slider (Left) + Aerospace Gimbal (Right)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 3x Bigger Aerospace Vertical Speed / Throttle Slider
            _buildAerospaceSpeedSlider(mavlink, vehicle),

            // Subtle Technical Vertical Divider
            Container(
              width: 1,
              height: 220,
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

  // 3x Bigger Redesigned Aerospace Vertical Speed / Throttle Slider
  Widget _buildAerospaceSpeedSlider(MavlinkService mavlink, VehicleState vehicle) {
    const faderHeight = 220.0;
    const faderWidth = 76.0;
    const knobHeight = 32.0;
    const knobWidth = 56.0;
    const topMargin = 16.0;
    const bottomMargin = 16.0;
    const availableTravel = faderHeight - topMargin - bottomMargin - knobHeight;

    final ratio = (_throttlePercent / 100.0).clamp(0.0, 1.0);
    final knobTop = (1.0 - ratio) * availableTravel + topMargin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Live Speed / Throttle HUD Readout Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF13171F),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFA7B35).withValues(alpha: 0.5), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFA7B35),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'THR: ${_throttlePercent.toInt()}%',
                style: const TextStyle(
                  color: Color(0xFFFA7B35),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
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
              color: const Color(0xFF0F1218),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Precision Aerospace Track with Active Energy Fill & Ladder Steps
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AerospaceSpeedSliderTrackPainter(
                      throttlePercent: _throttlePercent,
                      topMargin: topMargin,
                      bottomMargin: bottomMargin,
                    ),
                  ),
                ),

                // Aerospace Fader Knob Handle
                Positioned(
                  top: knobTop,
                  child: _buildAerospaceFaderKnob(knobWidth, knobHeight),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Modern Aerospace Fader Knob Handle
  Widget _buildAerospaceFaderKnob(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2430),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF384355), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFFA7B35).withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left chevron indicator notch
          const Positioned(
            left: 3,
            child: Icon(Icons.arrow_right, color: Color(0xFFFA7B35), size: 14),
          ),
          // Right chevron indicator notch
          const Positioned(
            right: 3,
            child: Icon(Icons.arrow_left, color: Color(0xFFFA7B35), size: 14),
          ),
          // Center laser stripe
          Container(
            width: width * 0.45,
            height: 3.5,
            decoration: BoxDecoration(
              color: const Color(0xFFFA7B35),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFA7B35).withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          // Center white indicator pip
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
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

// Modern Aerospace Vertical Speed / Throttle Slider Track Painter
class _AerospaceSpeedSliderTrackPainter extends CustomPainter {
  final double throttlePercent;
  final double topMargin;
  final double bottomMargin;

  const _AerospaceSpeedSliderTrackPainter({
    required this.throttlePercent,
    this.topMargin = 16.0,
    this.bottomMargin = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final topY = topMargin;
    final bottomY = size.height - bottomMargin;
    final trackHeight = bottomY - topY;
    final ratio = (throttlePercent / 100.0).clamp(0.0, 1.0);
    final fillTopY = bottomY - ratio * trackHeight;

    // 1. Center Vertical Slot Background
    final slotRect = Rect.fromLTRB(centerX - 4.5, topY, centerX + 4.5, bottomY);
    final slotPaint = Paint()..color = const Color(0xFF080B10);
    canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(3)), slotPaint);

    // 2. Active Illuminated Gradient Energy Fill from 0% up to current level
    if (ratio > 0.01) {
      final fillRect = Rect.fromLTRB(centerX - 3.5, fillTopY, centerX + 3.5, bottomY);
      final fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFFE65100),
            Color(0xFFFA7B35),
            Color(0xFFFFB74D),
          ],
        ).createShader(fillRect);
      canvas.drawRRect(RRect.fromRectAndRadius(fillRect, const Radius.circular(2)), fillPaint);

      // Glow on top of fill
      final glowPaint = Paint()
        ..color = const Color(0xFFFA7B35).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(Offset(centerX, fillTopY), 4.0, glowPaint);
    }

    // 3. Slot Outline
    final slotBorderPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(3)), slotBorderPaint);

    // 4. Graduated Scale Ladder & Markings (0%, 25%, 50%, 75%, 100%)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const List<int> majorSteps = [100, 75, 50, 25, 0];

    for (final step in majorSteps) {
      final stepRatio = step / 100.0;
      final y = bottomY - stepRatio * trackHeight;
      final isMid = (step == 50);

      // Major tick lines
      final tickPaint = Paint()
        ..color = isMid
            ? const Color(0xFFFA7B35).withValues(alpha: 0.9)
            : (stepRatio <= ratio ? Colors.white70 : Colors.white24)
        ..strokeWidth = isMid ? 1.8 : 1.2;

      // Left tick
      canvas.drawLine(Offset(centerX - 14, y), Offset(centerX - 6, y), tickPaint);
      // Right tick
      canvas.drawLine(Offset(centerX + 6, y), Offset(centerX + 14, y), tickPaint);

      // Percentage label text on left
      textPainter.text = TextSpan(
        text: '$step',
        style: TextStyle(
          color: isMid
              ? const Color(0xFFFA7B35)
              : (stepRatio <= ratio ? Colors.white70 : const Color(0xFF555F70)),
          fontSize: 8.5,
          fontWeight: isMid ? FontWeight.w900 : FontWeight.w700,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX - 18 - textPainter.width, y - textPainter.height / 2));
    }

    // Intermediate Minor Ticks (20 subdivisions)
    final minorTickPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 20; i++) {
      if (i % 5 == 0) continue; // skip major
      final y = topY + (i / 20.0) * trackHeight;
      canvas.drawLine(Offset(centerX - 10, y), Offset(centerX - 6, y), minorTickPaint);
      canvas.drawLine(Offset(centerX + 6, y), Offset(centerX + 10, y), minorTickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AerospaceSpeedSliderTrackPainter oldDelegate) =>
      oldDelegate.throttlePercent != throttlePercent;
}
