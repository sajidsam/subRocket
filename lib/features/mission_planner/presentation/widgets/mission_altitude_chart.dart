import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/models/mission_command.dart';
import 'agri_theme_constants.dart';

class MissionAltitudeChart extends StatelessWidget {
  final List<MissionItem> waypoints;
  final VoidCallback? onClose;

  const MissionAltitudeChart({
    super.key,
    required this.waypoints,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (waypoints.isEmpty) {
      return Container(
        height: 110,
        alignment: Alignment.center,
        decoration: AgriDecorations.cardBox(
          color: AgriColors.cardBackground,
          radius: 8,
          borderColor: AgriColors.border,
        ),
        child: const Text(
          'Add waypoints on map to preview altitude profile',
          style: TextStyle(color: AgriColors.textMuted, fontSize: 11),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < waypoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), waypoints[i].altitude));
    }

    final maxAlt = waypoints.map((w) => w.altitude).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AgriDecorations.cardBox(
        color: AgriColors.cardBackground.withValues(alpha: 0.95),
        radius: 8,
        borderColor: AgriColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.show_chart, color: AgriColors.orangePrimary, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'MISSION ALTITUDE PROFILE (AGL)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AgriColors.textWhite,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'MAX: ${maxAlt.toStringAsFixed(0)} m',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AgriColors.orangeLight,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (onClose != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(4),
                      child: const Icon(Icons.close, size: 14, color: AgriColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (v) => const FlLine(color: AgriColors.borderSubtle, strokeWidth: 1),
                  getDrawingVerticalLine: (v) => const FlLine(color: AgriColors.borderSubtle, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 16,
                      getTitlesWidget: (val, meta) => Text(
                        'WP${val.toInt() + 1}',
                        style: const TextStyle(color: AgriColors.textSecondary, fontSize: 8, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}m',
                        style: const TextStyle(color: AgriColors.textSecondary, fontSize: 8, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AgriColors.orangePrimary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.0,
                        color: AgriColors.orangePrimary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.black,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AgriColors.orangePrimary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
