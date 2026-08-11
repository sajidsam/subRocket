import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/presentation/widgets/gcs_drawer.dart';
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
      drawer: const GcsDrawer(),
      appBar: AppBar(
        title: const Text('HARDWARE CALIBRATION & TUNING'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GcsColors.cyanAccent,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.screen_rotation), text: 'ACCEL (3D)'),
            Tab(icon: Icon(Icons.explore), text: 'COMPASS'),
            Tab(icon: Icon(Icons.settings_input_antenna), text: 'RADIO (RC)'),
            Tab(icon: Icon(Icons.rotate_right), text: 'MOTOR TEST'),
            Tab(icon: Icon(Icons.tune), text: 'PID TUNING'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AccelCalibrationWizard(),
          CompassCalibrationWizard(),
          RadioChannelsView(),
          MotorTestPanel(),
          PidTuningPanel(),
        ],
      ),
    );
  }
}
