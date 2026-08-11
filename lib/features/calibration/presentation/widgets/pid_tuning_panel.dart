import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

class PidTuningPanel extends StatefulWidget {
  const PidTuningPanel({super.key});

  @override
  State<PidTuningPanel> createState() => _PidTuningPanelState();
}

class _PidTuningPanelState extends State<PidTuningPanel> {
  double _rollP = 0.135;
  double _rollI = 0.090;
  double _rollD = 0.0036;

  double _pitchP = 0.140;
  double _pitchI = 0.095;
  double _pitchD = 0.0038;

  double _yawP = 0.180;
  double _yawI = 0.020;
  double _yawD = 0.0000;

  List<FlSpot> _generateStepResponse(double p, double i, double d) {
    final spots = <FlSpot>[];
    double y = 0.0;
    double integral = 0.0;
    double lastError = 1.0;
    const dt = 0.02;

    for (int step = 0; step < 50; step++) {
      final t = step * dt;
      final target = t >= 0.1 ? 1.0 : 0.0;
      final error = target - y;
      integral += error * dt;
      final derivative = (error - lastError) / dt;
      lastError = error;

      final output = (p * error) + (i * integral) + (d * derivative);
      y += (output * 10.0 - y * 2.0) * dt;
      spots.add(FlSpot(t, y.clamp(-0.5, 1.8)));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: PID Gain Sliders
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ATTITUDE PID GAINS TUNING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GcsColors.cyanAccent, fontFamily: 'monospace')),
                  const SizedBox(height: 16),

                  _buildAxisGroup('ROLL RATE PID (ATC_RAT_RLL)', _rollP, _rollI, _rollD, (p, i, d) {
                    setState(() { _rollP = p; _rollI = i; _rollD = d; });
                  }),
                  const SizedBox(height: 16),

                  _buildAxisGroup('PITCH RATE PID (ATC_RAT_PIT)', _pitchP, _pitchI, _pitchD, (p, i, d) {
                    setState(() { _pitchP = p; _pitchI = i; _pitchD = d; });
                  }),
                  const SizedBox(height: 16),

                  _buildAxisGroup('YAW RATE PID (ATC_RAT_YAW)', _yawP, _yawI, _yawD, (p, i, d) {
                    setState(() { _yawP = p; _yawI = i; _yawD = d; });
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Right: Real-time Step Response Simulation Curve
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GcsColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GcsColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STEP-RESPONSE SIMULATION', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: GcsColors.greenActive)),
                  const SizedBox(height: 6),
                  const Text('Roll Attitude Dynamic Response (1.0 = target)', style: TextStyle(fontSize: 11, color: Colors.white60)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white12, strokeWidth: 1),
                          getDrawingVerticalLine: (v) => const FlLine(color: Colors.white12, strokeWidth: 1),
                        ),
                        titlesData: const FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
                        minY: 0,
                        maxY: 1.5,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateStepResponse(_rollP, _rollI, _rollD),
                            isCurved: true,
                            color: GcsColors.cyanAccent,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                          // Target line at 1.0
                          LineChartBarData(
                            spots: const [FlSpot(0, 1.0), FlSpot(1.0, 1.0)],
                            isCurved: false,
                            color: Colors.white38,
                            dashArray: [5, 5],
                            barWidth: 1.5,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
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

  Widget _buildAxisGroup(String title, double p, double i, double d, Function(double, double, double) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GcsColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GcsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white, fontFamily: 'monospace')),
          const SizedBox(height: 8),
          _buildSliderRow('P Gain', p, 0.01, 0.5, (v) => onChanged(v, i, d)),
          _buildSliderRow('I Gain', i, 0.01, 0.4, (v) => onChanged(p, v, d)),
          _buildSliderRow('D Gain', d, 0.000, 0.02, (v) => onChanged(p, i, v)),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double val, double min, double max, ValueChanged<double> onVal) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace'))),
        Expanded(
          child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            activeColor: GcsColors.cyanAccent,
            onChanged: onVal,
          ),
        ),
        SizedBox(width: 60, child: Text(val.toStringAsFixed(4), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GcsColors.techAmber, fontFamily: 'monospace'))),
      ],
    );
  }
}
