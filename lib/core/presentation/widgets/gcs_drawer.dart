import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/calibration/presentation/screens/calibration_screen.dart';
import '../../../features/datalink/presentation/screens/connection_screen.dart';
import '../../../features/flight_logs/presentation/screens/flight_logs_screen.dart';
import '../../../features/mission_planner/presentation/screens/mission_planner_screen.dart';
import '../../../features/parameters/presentation/screens/parameter_editor_screen.dart';
import '../../models/vehicle_state.dart';
import '../theme/gcs_theme.dart';

class GcsDrawer extends StatelessWidget {
  const GcsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();

    return Drawer(
      backgroundColor: GcsColors.surfaceDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: GcsColors.surfaceCard,
              border: Border(bottom: BorderSide(color: GcsColors.border, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rocket_launch, color: GcsColors.cyanAccent, size: 36),
                    SizedBox(width: 10),
                    Text(
                      'ROCKET GCS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: vehicle.isConnected ? GcsColors.greenActive : GcsColors.alertRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${vehicle.connectionType} | ArduPilot v4.5',
                      style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildNavItem(
            context,
            icon: Icons.dashboard,
            title: 'Live Flight Dashboard',
            color: GcsColors.cyanAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.map,
            title: 'Mission Planner & Nav',
            color: GcsColors.skyBlue,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionPlannerScreen()));
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.tune,
            title: 'Hardware Calibration & Tuning',
            color: GcsColors.techAmber,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CalibrationScreen()));
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.settings_suggest,
            title: 'Flight Parameters Tree',
            color: GcsColors.greenActive,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ParameterEditorScreen()));
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.analytics,
            title: 'Blackbox Flight Logs',
            color: Colors.purpleAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FlightLogsScreen()));
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.cable,
            title: 'Datalink & MAVLink Console',
            color: GcsColors.warningOrange,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      onTap: onTap,
    );
  }
}
