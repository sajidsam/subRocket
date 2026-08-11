import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

class TacticalCompassCard extends StatelessWidget {
  final bool isOverlay;

  const TacticalCompassCard({
    super.key,
    this.isOverlay = false,
  });

  String _formatCoordinate(LatLng? pos) {
    if (pos == null) {
      return "50°26'3\" N  30°28'50\" E";
    }
    final latDeg = pos.latitude.abs().floor();
    final latMin = ((pos.latitude.abs() - latDeg) * 60).floor();
    final latSec = ((((pos.latitude.abs() - latDeg) * 60) - latMin) * 60).toStringAsFixed(0);
    final latHem = pos.latitude >= 0 ? 'N' : 'S';

    final lngDeg = pos.longitude.abs().floor();
    final lngMin = ((pos.longitude.abs() - lngDeg) * 60).floor();
    final lngSec = ((((pos.longitude.abs() - lngDeg) * 60) - lngMin) * 60).toStringAsFixed(0);
    final lngHem = pos.longitude >= 0 ? 'E' : 'W';

    return "$latDeg°$latMin'$latSec\" $latHem  $lngDeg°$lngMin'$lngSec\" $lngHem";
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final heading = vehicle.yaw > 0 ? vehicle.yaw.toInt() : 83;

    return Container(
      decoration: BoxDecoration(
        color: isOverlay ? Colors.black.withValues(alpha: 0.65) : GcsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverlay ? Colors.white24 : GcsColors.border,
          width: 1,
        ),
        boxShadow: isOverlay
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isOverlay ? 8 : 14,
        vertical: isOverlay ? 6 : 10,
      ),
      child: Column(
        children: [
          // Top Heading Blue Pill Badge (83°)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isOverlay ? 8 : 12,
              vertical: isOverlay ? 2 : 3,
            ),
            decoration: BoxDecoration(
              color: GcsColors.aviationBlue,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: GcsColors.aviationBlue.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$heading°',
              style: TextStyle(
                color: Colors.white,
                fontSize: isOverlay ? 9.5 : 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ),

          SizedBox(height: isOverlay ? 3 : 6),

          // Tactical Compass Rose Custom Painter
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CustomPaint(
                  painter: _CompassDialPainter(
                    yaw: vehicle.yaw > 0 ? vehicle.yaw : 83.0,
                    isCompact: isOverlay,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isOverlay ? 2 : 4),

          // Bottom GPS Coordinates Readout
          Text(
            _formatCoordinate(vehicle.currentLocation),
            style: TextStyle(
              color: isOverlay ? Colors.white70 : GcsColors.textSecondary,
              fontSize: isOverlay ? 7.5 : 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: isOverlay ? 0.4 : 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  final double yaw;
  final bool isCompact;

  _CompassDialPainter({
    required this.yaw,
    this.isCompact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 3;

    final tickPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Outer Circle Ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = GcsColors.borderLight.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Inner Concentric Circle Ring
    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // Crosshair Lines
    canvas.drawLine(
      Offset(center.dx - radius * 0.75, center.dy),
      Offset(center.dx + radius * 0.75, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.75),
      Offset(center.dx, center.dy + radius * 0.75),
      crossPaint,
    );

    // Center Reference Point
    canvas.drawCircle(
      center,
      isCompact ? 1.5 : 2.0,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.fill,
    );

    // Graduation Degree Ticks and Labels (Every 30 degrees)
    const degreeLabels = {
      0: 'N',
      30: '30',
      60: '60',
      90: 'E',
      120: '120',
      150: '150',
      180: 'S',
      210: '210',
      240: '240',
      270: 'W',
      300: '300',
      330: '330',
    };

    final rotationRad = (yaw - 83.0) * (pi / 180.0);

    for (int deg = 0; deg < 360; deg += 10) {
      final rad = (deg - 90) * (pi / 180.0) - rotationRad;
      final isMajor = deg % 30 == 0;
      final isCardinal = deg % 90 == 0;
      final tickLength = isCardinal ? (isCompact ? 4.5 : 6.0) : (isMajor ? (isCompact ? 3.5 : 4.5) : (isCompact ? 2.0 : 2.5));

      final p1 = Offset(
        center.dx + (radius - tickLength) * cos(rad),
        center.dy + (radius - tickLength) * sin(rad),
      );
      final p2 = Offset(
        center.dx + radius * cos(rad),
        center.dy + radius * sin(rad),
      );

      canvas.drawLine(
        p1,
        p2,
        isMajor
            ? (Paint()
              ..color = isCardinal ? Colors.white : Colors.white60
              ..strokeWidth = isCardinal ? 1.4 : 1.0)
            : tickPaint,
      );

      // Draw Labels for 30 deg intervals
      if (isMajor) {
        final text = degreeLabels[deg] ?? '$deg';
        final isNorth = deg == 0;

        final labelRadius = radius * 0.82;
        final labelPos = Offset(
          center.dx + labelRadius * cos(rad),
          center.dy + labelRadius * sin(rad),
        );

        final textSpan = TextSpan(
          text: text,
          style: TextStyle(
            color: isNorth ? GcsColors.goldAccent : (isCardinal ? Colors.white : GcsColors.textMuted),
            fontSize: isCardinal ? (isCompact ? 8.0 : 9.5) : (isCompact ? 6.0 : 7.0),
            fontWeight: isCardinal ? FontWeight.w900 : FontWeight.w600,
            fontFamily: 'monospace',
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            labelPos.dx - textPainter.width / 2,
            labelPos.dy - textPainter.height / 2,
          ),
        );

        // North Orange Pointer Indicator
        if (isNorth) {
          final pointerRadius = radius * 0.94;
          final pointerPos = Offset(
            center.dx + pointerRadius * cos(rad),
            center.dy + pointerRadius * sin(rad),
          );

          final trianglePath = Path();
          trianglePath.moveTo(pointerPos.dx, pointerPos.dy - (isCompact ? 2.5 : 3.0));
          trianglePath.lineTo(pointerPos.dx - (isCompact ? 2.5 : 3.0), pointerPos.dy + (isCompact ? 2.5 : 3.0));
          trianglePath.lineTo(pointerPos.dx + (isCompact ? 2.5 : 3.0), pointerPos.dy + (isCompact ? 2.5 : 3.0));
          trianglePath.close();

          canvas.drawPath(
            trianglePath,
            Paint()
              ..color = GcsColors.goldAccent
              ..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.yaw != yaw || oldDelegate.isCompact != isCompact;
  }
}
