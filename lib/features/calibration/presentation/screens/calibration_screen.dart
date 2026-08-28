import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../widgets/accel_calibration_wizard.dart';
import '../widgets/compass_calibration_wizard.dart';
import '../widgets/motor_test_panel.dart';
import '../widgets/pid_tuning_panel.dart';
import '../widgets/radio_channels_view.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GcsColors.frameBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                  Icon(Icons.tune, color: GcsColors.cyanAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'CALIBRATION',
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
              'HARDWARE SENSORS, ESC & PID TUNING',
              style: TextStyle(
                fontSize: 11,
                color: GcsColors.textSecondary,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GcsColors.cyanAccent,
          indicatorWeight: 3,
          labelColor: GcsColors.cyanAccent,
          unselectedLabelColor: GcsColors.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.screen_rotation, size: 18), text: 'ACCEL (3D)'),
            Tab(icon: Icon(Icons.explore, size: 18), text: 'COMPASS'),
            Tab(icon: Icon(Icons.settings_input_antenna, size: 18), text: 'RADIO (RC)'),
            Tab(icon: Icon(Icons.rotate_right, size: 18), text: 'MOTOR TEST'),
            Tab(icon: Icon(Icons.tune, size: 18), text: 'PID TUNING'),
          ],
        ),
      ),
      body: Container(
        color: GcsColors.background,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: GcsColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GcsColors.border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: TabBarView(
            controller: _tabController,
            children: const [
              AccelCalibrationWizard(),
              CompassCalibrationWizard(),
              RadioChannelsView(),
              MotorTestPanel(),
              PidTuningPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
