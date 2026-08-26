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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GcsColors.aviationBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: GcsColors.cyanAccent.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.rotate_right, color: GcsColors.cyanAccent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'ESC & MOTOR TEST BENCH',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace', letterSpacing: 1.0),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GcsColors.alertRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: GcsColors.alertRed.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: GcsColors.alertRed, size: 14),
                    SizedBox(width: 4),
                    Text('PROPS REMOVAL REQUIRED', style: TextStyle(color: GcsColors.alertRed, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Safety Interlock Switch Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GcsColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _safetyUnlocked ? GcsColors.alertRed : GcsColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _safetyUnlocked ? GcsColors.alertRed.withValues(alpha: 0.2) : GcsColors.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _safetyUnlocked ? Icons.lock_open : Icons.lock,
                        color: _safetyUnlocked ? GcsColors.alertRed : GcsColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SAFETY INTERLOCK SWITCH', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12, color: Colors.white)),
                        Text(
                          _safetyUnlocked ? 'ARMED FOR MOTOR TEST' : 'LOCKED (CONFIRM PROPELLERS ARE DETACHED)',
                          style: TextStyle(color: _safetyUnlocked ? GcsColors.alertRed : GcsColors.textSecondary, fontSize: 11),
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

          const SizedBox(height: 16),

          // Throttle Percent Slider Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: GcsColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GcsColors.border),
            ),
            child: Row(
              children: [
                const Text('TEST THROTTLE: ', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                Text('${_testThrottle.toInt()}%', style: const TextStyle(color: GcsColors.goldAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12)),
                const SizedBox(width: 10),
                Expanded(
                  child: Slider(
                    value: _testThrottle,
                    min: 5.0,
                    max: 50.0,
                    divisions: 9,
                    activeColor: GcsColors.goldAccent,
                    onChanged: _safetyUnlocked ? (v) => setState(() => _testThrottle = v) : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 8 Motors Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                final motorNum = index + 1;
                final isSpinning = _activeTestingMotor == motorNum;

                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSpinning ? GcsColors.greenActive : GcsColors.surfaceDark,
                    foregroundColor: isSpinning ? Colors.black : Colors.white,
                    side: BorderSide(color: isSpinning ? GcsColors.greenActive : GcsColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(Icons.rotate_right, color: isSpinning ? Colors.black : GcsColors.cyanAccent, size: 18),
                  label: Text('MOTOR $motorNum (${isSpinning ? "SPIN" : "TEST"})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
