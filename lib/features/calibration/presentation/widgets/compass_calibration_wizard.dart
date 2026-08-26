import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

class CompassCalibrationWizard extends StatefulWidget {
  const CompassCalibrationWizard({super.key});

  @override
  State<CompassCalibrationWizard> createState() => _CompassCalibrationWizardState();
}

class _CompassCalibrationWizardState extends State<CompassCalibrationWizard> {
  bool _isLive = false;
  double _progress = 0.0;
  Timer? _timer;
  final int _magOffsetX = 120;
  final int _magOffsetY = -85;
  final int _magOffsetZ = 240;
  double _fitnessScore = 0.85;

  void _toggleCalibration() {
    if (_isLive) {
      _timer?.cancel();
      setState(() => _isLive = false);
    } else {
      setState(() {
        _isLive = true;
        _progress = 0.0;
      });

      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_progress < 1.0) {
          setState(() {
            _progress += 0.02;
            _fitnessScore = 0.85 + (_progress * 0.12);
          });
        } else {
          _timer?.cancel();
          setState(() => _isLive = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compass Live Calibration Successful! Fitness: 0.97')),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  color: GcsColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: GcsColors.goldAccent.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.explore, color: GcsColors.goldAccent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'MAGNETOMETER / COMPASS CALIBRATION',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace', letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Rotate the vehicle 360 degrees along yaw, pitch, and roll axes to calculate hard and soft iron compensation offsets.',
            style: TextStyle(color: GcsColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Sphere Progress Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GcsColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GcsColors.border, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CALIBRATION PROGRESS:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11, color: Colors.white)),
                    Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: GcsColors.goldAccent, fontFamily: 'monospace', fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 12,
                    backgroundColor: GcsColors.surfaceCard,
                    color: _progress > 0.8 ? GcsColors.greenActive : GcsColors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 20),

                // Offset Readouts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOffsetTile('MAG_OFS_X', '$_magOffsetX mG', GcsColors.cyanAccent),
                    _buildOffsetTile('MAG_OFS_Y', '$_magOffsetY mG', GcsColors.cyanAccent),
                    _buildOffsetTile('MAG_OFS_Z', '$_magOffsetZ mG', GcsColors.cyanAccent),
                    _buildOffsetTile('FITNESS', _fitnessScore.toStringAsFixed(2), GcsColors.greenActive),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLive ? GcsColors.alertRed : GcsColors.goldAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: Icon(_isLive ? Icons.stop : Icons.play_arrow, size: 18),
            label: Text(_isLive ? 'CANCEL CALIBRATION' : 'START LIVE COMPASS CALIBRATION', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            onPressed: _toggleCalibration,
          ),
        ],
      ),
    );
  }

  Widget _buildOffsetTile(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GcsColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GcsColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: GcsColors.textSecondary, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
