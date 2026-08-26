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
      backgroundColor: GcsColors.frameBackground,
      drawer: const GcsDrawer(),
      appBar: AppBar(
        backgroundColor: GcsColors.surfaceDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: GcsColors.aviationBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: GcsColors.cyanAccent.withValues(alpha: 0.6)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, color: GcsColors.cyanAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'BLACKBOX LOGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                      color: GcsColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'TELEMETRY REPLAY & MULTI-PARAM PLOTS',
              style: TextStyle(
                fontSize: 11,
                color: GcsColors.textSecondary,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: GcsColors.background,
        child: Row(
          children: [
            // Left: Session List Sidebar
            Container(
              width: 270,
              margin: const EdgeInsets.fromLTRB(8, 8, 4, 8),
              decoration: BoxDecoration(
                color: GcsColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GcsColors.border, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: const BoxDecoration(
                      color: GcsColors.surfaceCard,
                      border: Border(bottom: BorderSide(color: GcsColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.history, color: GcsColors.goldAccent, size: 18),
                            SizedBox(width: 6),
                            Text('RECORDED SESSIONS', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11, color: Colors.white)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GcsColors.cyanAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: GcsColors.cyanAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text('${sessions.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: GcsColors.cyanAccent, fontFamily: 'monospace', fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Text(
                              'No flight sessions found.',
                              style: TextStyle(color: GcsColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final s = sessions[index];
                              final isSelected = index == _selectedSessionIndex;
                              final dur = s.duration;
                              final durStr = '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s';

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected ? GcsColors.surfaceCard : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? GcsColors.cyanAccent : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.description_outlined,
                                    color: isSelected ? GcsColors.goldAccent : GcsColors.textMuted,
                                    size: 20,
                                  ),
                                  title: Text(
                                    s.title,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: isSelected ? Colors.white : GcsColors.textSecondary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Duration: $durStr | Max: ${s.maxAltitude.toStringAsFixed(0)}m',
                                    style: TextStyle(fontSize: 10, color: isSelected ? GcsColors.cyanAccent : GcsColors.textMuted, fontFamily: 'monospace'),
                                  ),
                                  onTap: () => setState(() => _selectedSessionIndex = index),
                                ),
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
                  ? Center(
                      child: Text(
                        'No recorded flight sessions found.',
                        style: TextStyle(fontFamily: 'monospace', color: GcsColors.textSecondary),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: GcsColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GcsColors.border, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Overview Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard('MAX ALTITUDE', '${activeSession.maxAltitude.toStringAsFixed(1)} m', GcsColors.cyanAccent),
                              _buildStatCard('TOP SPEED', '${activeSession.maxSpeed.toStringAsFixed(1)} m/s', GcsColors.greenActive),
                              _buildStatCard('DISTANCE', '${activeSession.totalDistance.toStringAsFixed(0)} m', GcsColors.goldAccent),
                              _buildStatCard('LOG FRAMES', '${activeSession.frames.length}', Colors.white),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Interactive Replay Scrubber Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: GcsColors.surfaceDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: GcsColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (logger.isReplaying) {
                                              logger.stopPlayback();
                                            } else {
                                              logger.startPlayback(activeSession);
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: logger.isReplaying ? GcsColors.alertRed.withValues(alpha: 0.2) : GcsColors.cyanAccent.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: logger.isReplaying ? GcsColors.alertRed : GcsColors.cyanAccent),
                                            ),
                                            child: Icon(
                                              logger.isReplaying ? Icons.pause : Icons.play_arrow,
                                              color: logger.isReplaying ? GcsColors.alertRed : GcsColors.cyanAccent,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          logger.isReplaying ? 'REPLAYING TELEMETRY' : 'SCRUBBER PAUSED',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11, color: logger.isReplaying ? GcsColors.greenActive : GcsColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    // Speed multiplier buttons
                                    Row(
                                      children: [1.0, 2.0, 5.0, 10.0].map((speed) {
                                        final isSelected = logger.playbackSpeedMultiplier == speed;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(4),
                                            onTap: () => logger.setPlaybackSpeed(speed),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isSelected ? GcsColors.goldAccent : GcsColors.surfaceCard,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: isSelected ? GcsColors.goldAccent : GcsColors.border),
                                              ),
                                              child: Text(
                                                '${speed.toInt()}x',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'monospace',
                                                  color: isSelected ? Colors.black : GcsColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Slider(
                                  value: activeSession.frames.isNotEmpty
                                      ? (logger.playbackIndex / (activeSession.frames.length - 1)).clamp(0.0, 1.0)
                                      : 0.0,
                                  activeColor: GcsColors.cyanAccent,
                                  inactiveColor: GcsColors.border,
                                  onChanged: (val) => logger.seekPlayback(activeSession, val),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Metric Selector Tabs
                          Row(
                            children: ['ALTITUDE', 'GROUNDSPEED', 'BATTERY VOLTAGE', 'PITCH & ROLL'].map((m) {
                              final isSel = _selectedPlot == m;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      fontFamily: 'monospace',
                                      color: isSel ? Colors.black : GcsColors.textSecondary,
                                    ),
                                  ),
                                  selected: isSel,
                                  selectedColor: GcsColors.cyanAccent,
                                  backgroundColor: GcsColors.surfaceDark,
                                  side: BorderSide(color: isSel ? GcsColors.cyanAccent : GcsColors.border),
                                  onSelected: (sel) {
                                    if (sel) setState(() => _selectedPlot = m);
                                  },
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 8),

                          // Main Telemetry Line Chart
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: GcsColors.surfaceDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: GcsColors.border),
                              ),
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    getDrawingHorizontalLine: (v) => const FlLine(color: Color(0x1FFFFFFF), strokeWidth: 1),
                                    getDrawingVerticalLine: (v) => const FlLine(color: Color(0x1FFFFFFF), strokeWidth: 1),
                                  ),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 36,
                                        getTitlesWidget: (v, m) => Text(
                                          v.toStringAsFixed(0),
                                          style: const TextStyle(color: GcsColors.textSecondary, fontSize: 9, fontFamily: 'monospace'),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 20,
                                        getTitlesWidget: (v, m) => Text(
                                          'f${v.toInt()}',
                                          style: const TextStyle(color: GcsColors.textSecondary, fontSize: 9, fontFamily: 'monospace'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
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
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GcsColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GcsColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: GcsColors.textSecondary, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace')),
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
