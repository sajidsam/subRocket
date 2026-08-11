import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/log_entry.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/presentation/widgets/gcs_drawer.dart';
import '../../../../core/services/flight_logger_service.dart';

class FlightLogsScreen extends StatefulWidget {
  const FlightLogsScreen({super.key});

  @override
  State<FlightLogsScreen> createState() => _FlightLogsScreenState();
}

class _FlightLogsScreenState extends State<FlightLogsScreen> {
  int _selectedSessionIndex = 0;
  String _selectedPlot = 'ALTITUDE';

  @override
  Widget build(BuildContext context) {
    final logger = context.watch<FlightLoggerService>();
    final sessions = logger.recordedSessions;
    final activeSession = sessions.isNotEmpty && _selectedSessionIndex < sessions.length
        ? sessions[_selectedSessionIndex]
        : null;

    return Scaffold(
      drawer: const GcsDrawer(),
      appBar: AppBar(
        title: const Text('BLACKBOX FLIGHT LOGS & REPLAY'),
      ),
      body: Row(
        children: [
          // Left: Session List Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: GcsColors.surfaceDark,
              border: Border(right: BorderSide(color: GcsColors.border, width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  color: GcsColors.surfaceCard,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SESSIONS', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      Text('${sessions.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: GcsColors.cyanAccent, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      final isSelected = index == _selectedSessionIndex;
                      final dur = s.duration;
                      final durStr = '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s';

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: GcsColors.surfaceCard,
                        leading: Icon(Icons.description, color: isSelected ? GcsColors.cyanAccent : Colors.white38),
                        title: Text(
                          s.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: isSelected ? GcsColors.cyanAccent : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'Duration: $durStr | Max: ${s.maxAltitude.toStringAsFixed(0)}m',
                          style: const TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'monospace'),
                        ),
                        onTap: () => setState(() => _selectedSessionIndex = index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right: Replay Timeline & Multi-Variable Charts
          Expanded(
            child: activeSession == null
                ? const Center(child: Text('No recorded flight sessions found.', style: TextStyle(fontFamily: 'monospace')))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Overview Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard('MAX ALTITUDE', '${activeSession.maxAltitude.toStringAsFixed(1)} m', GcsColors.cyanAccent),
                            _buildStatCard('TOP SPEED', '${activeSession.maxSpeed.toStringAsFixed(1)} m/s', GcsColors.greenActive),
                            _buildStatCard('DISTANCE', '${activeSession.totalDistance.toStringAsFixed(0)} m', GcsColors.techAmber),
                            _buildStatCard('FRAMES', '${activeSession.frames.length}', Colors.white),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Interactive Replay Scrubber Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: GcsColors.surfaceCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: GcsColors.border),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          logger.isReplaying ? Icons.pause : Icons.play_arrow,
                                          color: GcsColors.cyanAccent,
                                        ),
                                        onPressed: () {
                                          if (logger.isReplaying) {
                                            logger.stopPlayback();
                                          } else {
                                            logger.startPlayback(activeSession);
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        logger.isReplaying ? 'REPLAYING SESSION' : 'PAUSED',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  // Speed multiplier buttons
                                  Row(
                                    children: [1.0, 2.0, 5.0, 10.0].map((speed) {
                                      final isSelected = logger.playbackSpeedMultiplier == speed;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            backgroundColor: isSelected ? GcsColors.cyanAccent : Colors.black45,
                                            foregroundColor: isSelected ? Colors.black : Colors.white70,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                          ),
                                          onPressed: () => logger.setPlaybackSpeed(speed),
                                          child: Text('${speed.toInt()}x', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              Slider(
                                value: activeSession.frames.isNotEmpty
                                    ? (logger.playbackIndex / (activeSession.frames.length - 1)).clamp(0.0, 1.0)
                                    : 0.0,
                                activeColor: GcsColors.cyanAccent,
                                onChanged: (val) => logger.seekPlayback(activeSession, val),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Metric Selector Tabs
                        Row(
                          children: ['ALTITUDE', 'GROUNDSPEED', 'BATTERY VOLTAGE', 'PITCH & ROLL'].map((m) {
                            final isSel = _selectedPlot == m;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(m, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isSel ? Colors.black : Colors.white)),
                                selected: isSel,
                                selectedColor: GcsColors.cyanAccent,
                                backgroundColor: GcsColors.surfaceCard,
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedPlot = m);
                                },
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),

                        // Main Telemetry Line Chart
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: GcsColors.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: GcsColors.border),
                            ),
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
                                borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _extractSessionSpots(activeSession),
                                    isCurved: true,
                                    color: GcsColors.cyanAccent,
                                    barWidth: 2.5,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: GcsColors.cyanAccent.withValues(alpha: 0.15),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GcsColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GcsColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: GcsColors.textSecondary, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  List<FlSpot> _extractSessionSpots(FlightLogSession session) {
    if (session.frames.isEmpty) return [const FlSpot(0, 0)];

    return session.frames.asMap().entries.map((e) {
      final f = e.value;
      double y = 0;
      switch (_selectedPlot) {
        case 'GROUNDSPEED':
          y = f.groundspeed;
          break;
        case 'BATTERY VOLTAGE':
          y = f.batteryVoltage;
          break;
        case 'PITCH & ROLL':
          y = f.pitch;
          break;
        case 'ALTITUDE':
        default:
          y = f.altitude;
      }
      return FlSpot(e.key.toDouble(), y);
    }).toList();
  }
}
