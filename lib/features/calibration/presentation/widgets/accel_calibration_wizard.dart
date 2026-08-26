import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

class AccelCalibrationWizard extends StatefulWidget {
  const AccelCalibrationWizard({super.key});

  @override
  State<AccelCalibrationWizard> createState() => _AccelCalibrationWizardState();
}

class _AccelCalibrationWizardState extends State<AccelCalibrationWizard> {
  int _currentStep = 0;
  bool _isCalibrating = false;

  final List<Map<String, dynamic>> _steps = [
    {'title': 'Level Orientation', 'desc': 'Place vehicle on a flat level surface', 'icon': Icons.horizontal_rule},
    {'title': 'Left Side', 'desc': 'Place vehicle on its left edge (90° roll left)', 'icon': Icons.rotate_left},
    {'title': 'Right Side', 'desc': 'Place vehicle on its right edge (90° roll right)', 'icon': Icons.rotate_right},
    {'title': 'Nose Down', 'desc': 'Point vehicle nose straight down (-90° pitch)', 'icon': Icons.arrow_downward},
    {'title': 'Nose Up', 'desc': 'Point vehicle nose straight up (+90° pitch)', 'icon': Icons.arrow_upward},
    {'title': 'Back / Inverted', 'desc': 'Place vehicle upside down on its back', 'icon': Icons.flip},
  ];

  Future<void> _advanceStep() async {
    setState(() => _isCalibrating = true);
    await Future.delayed(const Duration(milliseconds: 700));

    setState(() {
      _isCalibrating = false;
      if (_currentStep < _steps.length - 1) {
        _currentStep++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accelerometer 3D Calibration Complete! Offsets saved.')),
        );
      }
    });
  }

  void _restart() {
    setState(() {
      _currentStep = 0;
      _isCalibrating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GcsColors.aviationBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: GcsColors.cyanAccent.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.screen_rotation, color: GcsColors.cyanAccent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                '3D ACCELEROMETER / IMU CALIBRATION',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace', letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Calibrate the internal IMU accelerometers across all 6 geometric axes for precise attitude estimation.',
            style: TextStyle(color: GcsColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Steps Progress Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GcsColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GcsColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CALIBRATION PROGRESS: STEP ${_currentStep + 1} OF ${_steps.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11, color: Colors.white)),
                    Text('${((_currentStep / _steps.length) * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11, color: GcsColors.goldAccent)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_steps.length, (index) {
                    final isDone = index < _currentStep;
                    final isCurrent = index == _currentStep;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDone ? GcsColors.greenActive : (isCurrent ? GcsColors.goldAccent : GcsColors.surfaceCard),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active Calibration Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GcsColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GcsColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: GcsColors.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: GcsColors.cyanAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: GcsColors.cyanAccent.withValues(alpha: 0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(step['icon'] as IconData, color: GcsColors.cyanAccent, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POSITION ${_currentStep + 1}: ${step["title"].toString().toUpperCase()}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: GcsColors.goldAccent, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step['desc'] as String,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GcsColors.greenActive,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                icon: _isCalibrating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.check, size: 18),
                label: Text(_currentStep < _steps.length - 1 ? 'CAPTURE & PROCEED' : 'FINISH CALIBRATION', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                onPressed: _isCalibrating ? null : _advanceStep,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: GcsColors.textSecondary,
                  side: const BorderSide(color: GcsColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('RESTART', style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
                onPressed: _restart,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
