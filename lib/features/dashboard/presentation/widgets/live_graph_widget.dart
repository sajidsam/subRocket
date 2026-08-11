import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/flight_logger_service.dart';

class LiveGraphOverlay extends StatefulWidget {
  const LiveGraphOverlay({super.key});

  @override
  State<LiveGraphOverlay> createState() => _LiveGraphOverlayState();
}

class _LiveGraphOverlayState extends State<LiveGraphOverlay> {
  bool _isExpanded = false;
  String _selectedMetric = 'ALTITUDE';

  @override
  Widget build(BuildContext context) {
    final logger = context.watch<FlightLoggerService>();
    final frames = logger.activeSession?.frames ?? [];

    return Positioned(
      bottom: 24,
      left: 360,
      child: Container(
        width: _isExpanded ? 480 : 200,
        height: _isExpanded ? 240 : 44,
        decoration: BoxDecoration(
          color: GcsColors.surfaceDark.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GcsColors.border, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header bar
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.show_chart, color: GcsColors.cyanAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _isExpanded ? 'LIVE TELEMETRY PLOT' : 'LIVE PLOT',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    if (_isExpanded)
                      DropdownButton<String>(
                        value: _selectedMetric,
                        dropdownColor: GcsColors.surfaceCard,
                        isDense: true,
                        underline: const SizedBox(),
                        items: ['ALTITUDE', 'SPEED', 'BATTERY', 'PITCH/ROLL'].map((m) {
                          return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedMetric = v);
                        },
                      ),
                    Icon(_isExpanded ? Icons.fullscreen_exit : Icons.open_in_full, size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),

            // Graph body when expanded
            if (_isExpanded)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white10, strokeWidth: 1),
                        getDrawingVerticalLine: (v) => const FlLine(color: Colors.white10, strokeWidth: 1),
                      ),
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _extractSpots(frames),
                          isCurved: true,
                          color: _getMetricColor(),
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _getMetricColor().withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _extractSpots(List dynamicFrames) {
    if (dynamicFrames.isEmpty) return [const FlSpot(0, 0)];
    final recent = dynamicFrames.length > 50 ? dynamicFrames.sublist(dynamicFrames.length - 50) : dynamicFrames;

    return recent.asMap().entries.map((e) {
      final f = e.value;
      double y = 0;
      switch (_selectedMetric) {
        case 'SPEED':
          y = f.groundspeed;
          break;
        case 'BATTERY':
          y = f.batteryVoltage;
          break;
        case 'PITCH/ROLL':
          y = f.pitch;
          break;
        case 'ALTITUDE':
        default:
          y = f.altitude;
      }
      return FlSpot(e.key.toDouble(), y);
    }).toList();
  }

  Color _getMetricColor() {
    switch (_selectedMetric) {
      case 'SPEED':
        return GcsColors.cyanAccent;
      case 'BATTERY':
        return GcsColors.greenActive;
      case 'PITCH/ROLL':
        return GcsColors.techAmber;
      case 'ALTITUDE':
      default:
        return GcsColors.warningOrange;
    }
  }
}
