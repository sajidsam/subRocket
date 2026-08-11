import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_state.dart';
import '../theme/gcs_theme.dart';

class HudPrimaryFlightDisplay extends StatelessWidget {
  final double width;
  final double height;

  const HudPrimaryFlightDisplay({
    super.key,
    this.width = 320,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GcsColors.border, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Artificial Horizon (Pitch & Roll)
            CustomPaint(
              size: Size(width, height),
              painter: HorizonPainter(
                rollDeg: vehicle.roll,
                pitchDeg: vehicle.pitch,
              ),
            ),

            // 2. Fixed Aircraft Reticle
            CustomPaint(
              size: Size(width, height),
              painter: AircraftReticlePainter(),
            ),

            // 3. Left Speed Tape
            Positioned(
              left: 0,
              top: 0,
              bottom: 30,
              child: SpeedTape(speed: vehicle.groundspeed),
            ),

            // 4. Right Altitude & VSI Tape
            Positioned(
              right: 0,
              top: 0,
              bottom: 30,
              child: AltitudeTape(
                altitude: vehicle.altitudeAgl,
                vsi: vehicle.climbRate,
              ),
            ),

            // 5. Bottom Heading / Compass Tape
            Positioned(
              left: 45,
              right: 45,
              bottom: 0,
              child: HeadingTape(
                heading: vehicle.yaw,
                targetBearing: vehicle.targetBearing,
              ),
            ),

            // 6. Top Flight Mode & Arm Status Overlay
            Positioned(
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: vehicle.isArmed ? GcsColors.alertRed : Colors.white24),
                ),
                child: Text(
                  '${vehicle.mode.name} | ${vehicle.isArmed ? "ARMED" : "DISARMED"}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: vehicle.isArmed ? GcsColors.alertRed : GcsColors.cyanAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HorizonPainter extends CustomPainter {
  final double rollDeg;
  final double pitchDeg;

  HorizonPainter({required this.rollDeg, required this.pitchDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rollRad = rollDeg * (pi / 180.0);
    final pitchPixels = pitchDeg * 3.2; // 3.2px per degree

    canvas.save();
    // Rotate canvas by roll angle around center
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rollRad);
    canvas.translate(-center.dx, -center.dy);

    // Draw Sky
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0277BD), Color(0xFF29B6F6)],
      ).createShader(Rect.fromLTWH(-size.width, -size.height * 2 + pitchPixels, size.width * 3, size.height * 2));

    canvas.drawRect(
      Rect.fromLTWH(-size.width, -size.height * 2 + pitchPixels + center.dy, size.width * 3, size.height * 2),
      skyPaint,
    );

    // Draw Ground
    final groundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4E342E), Color(0xFF3E2723)],
      ).createShader(Rect.fromLTWH(-size.width, pitchPixels + center.dy, size.width * 3, size.height * 2));

    canvas.drawRect(
      Rect.fromLTWH(-size.width, pitchPixels + center.dy, size.width * 3, size.height * 2),
      groundPaint,
    );

    // Horizon Line
    final horizonPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(-size.width, pitchPixels + center.dy),
      Offset(size.width * 2, pitchPixels + center.dy),
      horizonPaint,
    );

    // Pitch Ladder
    _drawPitchLadder(canvas, center, pitchPixels);

    canvas.restore();
  }

  void _drawPitchLadder(Canvas canvas, Offset center, double pitchPixels) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.5;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int deg = -90; deg <= 90; deg += 10) {
      if (deg == 0) continue;
      final y = center.dy + pitchPixels - (deg * 3.2);
      final isMajor = deg % 20 == 0;
      final width = isMajor ? 50.0 : 30.0;

      // Pitch rungs
      canvas.drawLine(Offset(center.dx - width / 2, y), Offset(center.dx + width / 2, y), linePaint);

      // Side ticks (pointing towards horizon)
      final tickDir = deg > 0 ? 5.0 : -5.0;
      canvas.drawLine(Offset(center.dx - width / 2, y), Offset(center.dx - width / 2, y + tickDir), linePaint);
      canvas.drawLine(Offset(center.dx + width / 2, y), Offset(center.dx + width / 2, y + tickDir), linePaint);

      if (isMajor) {
        textPainter.text = TextSpan(
          text: '${deg.abs()}',
          style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(center.dx - width / 2 - 18, y - 6));
        textPainter.paint(canvas, Offset(center.dx + width / 2 + 5, y - 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant HorizonPainter oldDelegate) {
    return oldDelegate.rollDeg != rollDeg || oldDelegate.pitchDeg != pitchDeg;
  }
}

class AircraftReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = GcsColors.techAmber
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Center yellow dot
    canvas.drawCircle(center, 3.5, Paint()..color = GcsColors.techAmber..style = PaintingStyle.fill);

    // Left reticle wing
    canvas.drawLine(Offset(center.dx - 45, center.dy), Offset(center.dx - 15, center.dy), paint);
    canvas.drawLine(Offset(center.dx - 15, center.dy), Offset(center.dx - 15, center.dy + 8), paint);

    // Right reticle wing
    canvas.drawLine(Offset(center.dx + 45, center.dy), Offset(center.dx + 15, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 15, center.dy), Offset(center.dx + 15, center.dy + 8), paint);

    // Top roll pointer
    final path = Path()
      ..moveTo(center.dx, 18)
      ..lineTo(center.dx - 6, 28)
      ..lineTo(center.dx + 6, 28)
      ..close();
    canvas.drawPath(path, Paint()..color = GcsColors.techAmber..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpeedTape extends StatelessWidget {
  final double speed;

  const SpeedTape({super.key, required this.speed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: const Border(right: BorderSide(color: Colors.white24, width: 1.5)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Current Speed Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: GcsColors.surfaceDark,
              border: Border.all(color: GcsColors.cyanAccent, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              speed.toStringAsFixed(1),
              style: const TextStyle(color: GcsColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          const Positioned(
            top: 4,
            child: Text('SPD m/s', style: TextStyle(color: Colors.white60, fontSize: 8, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}

class AltitudeTape extends StatelessWidget {
  final double altitude;
  final double vsi;

  const AltitudeTape({super.key, required this.altitude, required this.vsi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: const Border(left: BorderSide(color: Colors.white24, width: 1.5)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Current Altitude Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: GcsColors.surfaceDark,
              border: Border.all(color: GcsColors.greenActive, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              altitude.toStringAsFixed(1),
              style: const TextStyle(color: GcsColors.greenActive, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          const Positioned(
            top: 4,
            child: Text('ALT m', style: TextStyle(color: Colors.white60, fontSize: 8, fontFamily: 'monospace')),
          ),
          // Vertical Speed Indicator (VSI) readout at bottom
          Positioned(
            bottom: 4,
            child: Text(
              '${vsi >= 0 ? "+" : ""}${vsi.toStringAsFixed(1)}m/s',
              style: TextStyle(
                color: vsi > 0.5 ? GcsColors.greenActive : (vsi < -0.5 ? GcsColors.warningOrange : Colors.white60),
                fontSize: 8,
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

class HeadingTape extends StatelessWidget {
  final double heading;
  final double targetBearing;

  const HeadingTape({super.key, required this.heading, required this.targetBearing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: const Border(top: BorderSide(color: Colors.white24, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.navigation, color: GcsColors.techAmber, size: 14),
          const SizedBox(width: 6),
          Text(
            'HDG: ${heading.toInt().toString().padLeft(3, '0')}°',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
          ),
          if (targetBearing > 0) ...[
            const SizedBox(width: 8),
            Text(
              'WP: ${targetBearing.toInt().toString().padLeft(3, '0')}°',
              style: const TextStyle(color: GcsColors.cyanAccent, fontSize: 10, fontFamily: 'monospace'),
            ),
          ]
        ],
      ),
    );
  }
}
