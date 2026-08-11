import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

class RadioChannelsView extends StatefulWidget {
  const RadioChannelsView({super.key});

  @override
  State<RadioChannelsView> createState() => _RadioChannelsViewState();
}

class _RadioChannelsViewState extends State<RadioChannelsView> {
  final List<int> _channelPwm = [1500, 1500, 1000, 1500, 1800, 1500, 1200, 1000];
  final List<String> _channelNames = [
    'CH 1: Roll (Aileron)',
    'CH 2: Pitch (Elevator)',
    'CH 3: Throttle',
    'CH 4: Yaw (Rudder)',
    'CH 5: Flight Mode Switch',
    'CH 6: Auxiliary / Tuning',
    'CH 7: Arm / Emergency Switch',
    'CH 8: Camera / Payload',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RADIO / RC TRANSMITTER CALIBRATION & MONITOR',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GcsColors.cyanAccent, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live PWM pulse widths (1000µs to 2000µs) mapped to standard 8-channel RC transmitter sticks and switches.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: _channelNames.length,
              itemBuilder: (context, index) {
                final pwm = _channelPwm[index];
                final fraction = ((pwm - 1000) / 1000.0).clamp(0.0, 1.0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: GcsColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GcsColors.border),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 220,
                        child: Text(
                          _channelNames[index],
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 16,
                            backgroundColor: Colors.white12,
                            color: index == 2 ? GcsColors.greenActive : GcsColors.cyanAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '$pwm µs',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GcsColors.techAmber, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
