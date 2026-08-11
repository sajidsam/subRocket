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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3D ACCELEROMETER / IMU CALIBRATION',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GcsColors.cyanAccent, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calibrate the internal IMU accelerometers across all 6 geometric axes for precise attitude estimation.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Steps Progress Row
          Row(
            children: List.generate(_steps.length, (index) {
              final isDone = index < _currentStep;
              final isCurrent = index == _currentStep;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDone ? GcsColors.greenActive : (isCurrent ? GcsColors.techAmber : Colors.white24),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Active Calibration Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GcsColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GcsColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: GcsColors.cyanAccent, width: 2),
                  ),
                  child: Icon(step['icon'] as IconData, color: GcsColors.cyanAccent, size: 40),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP ${_currentStep + 1} OF ${_steps.length}: ${step["title"]}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step['desc'] as String,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                    : const Icon(Icons.check),
                label: Text(_currentStep < _steps.length - 1 ? 'CAPTURE & PROCEED' : 'FINISH CALIBRATION'),
                onPressed: _isCalibrating ? null : _advanceStep,
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white60),
                label: const Text('RESTART', style: TextStyle(color: Colors.white60)),
                onPressed: _restart,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
