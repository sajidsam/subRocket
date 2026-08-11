import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_state.dart';
import '../theme/gcs_theme.dart';

class TelemetryStrip extends StatelessWidget {
  const TelemetryStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GcsColors.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GcsColors.border, width: 1.5),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        children: [
          _buildMetric('GROUNDSPEED', '${vehicle.groundspeed.toStringAsFixed(1)} m/s', GcsColors.cyanAccent),
          _buildMetric('ALTITUDE (AGL)', '${vehicle.altitudeAgl.toStringAsFixed(1)} m', GcsColors.greenActive),
          _buildMetric('CLIMB RATE', '${vehicle.climbRate >= 0 ? "+" : ""}${vehicle.climbRate.toStringAsFixed(1)} m/s', Colors.white),
          _buildMetric('DIST TO HOME', '${vehicle.distanceToHome.toStringAsFixed(0)} m', GcsColors.techAmber),
          _buildMetric('DIST TO WP', vehicle.missionItems.isNotEmpty ? '${vehicle.distanceToNextWp.toStringAsFixed(0)} m' : 'N/A', GcsColors.skyBlue),
          _buildMetric('ROLL / PITCH', '${vehicle.roll.toStringAsFixed(0)}° / ${vehicle.pitch.toStringAsFixed(0)}°', Colors.white70),
          _buildMetric('THROTTLE', '${vehicle.throttlePercent}%', vehicle.throttlePercent > 75 ? GcsColors.warningOrange : GcsColors.cyanAccent),
          _buildMetric('FLIGHT TIME', _formatDuration(vehicle.flightDuration), Colors.white),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GcsColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: GcsColors.textSecondary, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
