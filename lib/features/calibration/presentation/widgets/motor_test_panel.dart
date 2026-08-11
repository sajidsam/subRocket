import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

class MotorTestPanel extends StatefulWidget {
  const MotorTestPanel({super.key});

  @override
  State<MotorTestPanel> createState() => _MotorTestPanelState();
}

class _MotorTestPanelState extends State<MotorTestPanel> {
  bool _safetyUnlocked = false;
  double _testThrottle = 15.0; // percent
  int? _activeTestingMotor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESC & MOTOR TEST BENCH',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GcsColors.cyanAccent, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 6),
          const Text(
            'WARNING: Remove all propellers before testing motors to prevent accidental injury.',
            style: TextStyle(color: GcsColors.alertRed, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Safety Interlock Switch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GcsColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _safetyUnlocked ? GcsColors.alertRed : GcsColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _safetyUnlocked ? Icons.lock_open : Icons.lock,
                      color: _safetyUnlocked ? GcsColors.alertRed : Colors.white60,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SAFETY INTERLOCK SWITCH', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        Text(
                          _safetyUnlocked ? 'ARMED FOR MOTOR TEST' : 'LOCKED (PROPS REMOVED CONFIRMATION REQUIRED)',
                          style: TextStyle(color: _safetyUnlocked ? GcsColors.alertRed : Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _safetyUnlocked,
                  activeThumbColor: GcsColors.alertRed,
                  onChanged: (val) => setState(() => _safetyUnlocked = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Throttle Percent Slider
          Row(
            children: [
              const Text('TEST THROTTLE: ', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              Text('${_testThrottle.toInt()}%', style: const TextStyle(color: GcsColors.techAmber, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              Expanded(
                child: Slider(
                  value: _testThrottle,
                  min: 5.0,
                  max: 50.0,
                  divisions: 9,
                  activeColor: GcsColors.techAmber,
                  onChanged: _safetyUnlocked ? (v) => setState(() => _testThrottle = v) : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 8 Motors Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                final motorNum = index + 1;
                final isSpinning = _activeTestingMotor == motorNum;

                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSpinning ? GcsColors.greenActive : GcsColors.surfaceCard,
                    foregroundColor: isSpinning ? Colors.black : Colors.white,
                    side: BorderSide(color: isSpinning ? GcsColors.greenActive : GcsColors.border),
                  ),
                  icon: Icon(Icons.rotate_right, color: isSpinning ? Colors.black : GcsColors.cyanAccent),
                  label: Text('MOTOR $motorNum (${isSpinning ? "SPIN" : "TEST"})'),
                  onPressed: !_safetyUnlocked
                      ? null
                      : () async {
                          setState(() => _activeTestingMotor = motorNum);
                          await Future.delayed(const Duration(seconds: 2));
                          if (mounted) setState(() => _activeTestingMotor = null);
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
