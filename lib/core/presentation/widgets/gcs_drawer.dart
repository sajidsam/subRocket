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
      backgroundColor: GcsColors.cardBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: GcsColors.surfaceDark,
              border: Border(bottom: BorderSide(color: GcsColors.border, width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GcsColors.goldAccent, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: GcsColors.goldAccent.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SAFAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'SAFAR GCS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'AUTONOMOUS FLIGHT SUITE',
                          style: TextStyle(
                            color: GcsColors.goldAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GcsColors.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: GcsColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: vehicle.isConnected ? GcsColors.greenActive : GcsColors.alertRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (vehicle.isConnected ? GcsColors.greenActive : GcsColors.alertRed).withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${vehicle.connectionType} | SAFAR OS',
                        style: const TextStyle(color: GcsColors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildNavItem(
            context,
            icon: Icons.dashboard,
            title: 'Live Flight Cockpit',
            color: GcsColors.cyanAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.map_outlined,
            title: 'Mission Planner & Nav',
            color: GcsColors.goldAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionPlannerScreen()));
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.tune,
            title: 'Hardware Calibration & Tuning',
            color: GcsColors.cyanAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CalibrationScreen()));
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.settings_suggest_outlined,
            title: 'Flight Parameters Tree',
            color: GcsColors.greenActive,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ParameterEditorScreen()));
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.analytics_outlined,
            title: 'Blackbox Flight Logs',
            color: GcsColors.goldAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FlightLogsScreen()));
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.cable,
            title: 'Datalink & MAVLink Console',
            color: GcsColors.cyanAccent,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        hoverColor: GcsColors.surfaceCard,
        onTap: onTap,
      ),
    );
  }
}
