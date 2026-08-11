import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/models/mission_command.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

class MissionAltitudeChart extends StatelessWidget {
  final List<MissionItem> waypoints;

  const MissionAltitudeChart({super.key, required this.waypoints});

  @override
  Widget build(BuildContext context) {
    if (waypoints.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text('Add waypoints on map to preview altitude profile', style: TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < waypoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), waypoints[i].altitude));
    }

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GcsColors.surfaceDark,
        border: const Border(top: BorderSide(color: GcsColors.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MISSION ALTITUDE PROFILE (AGL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GcsColors.cyanAccent, fontFamily: 'monospace')),
              Text('Max Alt: ${waypoints.map((w) => w.altitude).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)} m', style: const TextStyle(fontSize: 10, color: Colors.white60, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white10, strokeWidth: 1),
                  getDrawingVerticalLine: (v) => const FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (val, meta) => Text('WP${val.toInt() + 1}', style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace')),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) => Text('${val.toInt()}m', style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace')),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: GcsColors.cyanAccent,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: GcsColors.cyanAccent.withValues(alpha: 0.15),
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
