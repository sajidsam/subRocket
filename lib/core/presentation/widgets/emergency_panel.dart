import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flight_mode.dart';
import '../../models/vehicle_state.dart';
import '../../services/mavlink_service.dart';
import '../theme/gcs_theme.dart';

class EmergencyActionPanel extends StatelessWidget {
  const EmergencyActionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final mavlink = context.watch<MavlinkService>();
    final vehicle = context.watch<VehicleState>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GcsColors.surfaceDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GcsColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Takeoff Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcsColors.greenActive,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.flight_takeoff, size: 15),
            label: const Text('TAKEOFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            onPressed: () {
              if (!vehicle.isArmed) {
                mavlink.armDisarm(true);
              }
              mavlink.setFlightMode(FlightMode.guided);
              mavlink.simulator.joyThrottle = 0.5; // initiate climb
              vehicle.addStatusMessage('TAKEOFF commanded: Climbing to safe altitude', severity: SeverityLevel.info);
            },
          ),
          const SizedBox(width: 6),

          // RTL Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcsColors.goldAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.home, size: 15),
            label: const Text('RTL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            onPressed: () => mavlink.setFlightMode(FlightMode.rtl),
          ),
          const SizedBox(width: 6),

          // Land Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcsColors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.flight_land, size: 15),
            label: const Text('LAND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            onPressed: () => mavlink.setFlightMode(FlightMode.land),
          ),
          const SizedBox(width: 6),

          // Loiter / Hold
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcsColors.surfaceCard,
              foregroundColor: Colors.white,
              side: const BorderSide(color: GcsColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.pause, size: 15),
            label: const Text('HOLD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            onPressed: () => mavlink.setFlightMode(FlightMode.loiter),
          ),
          const SizedBox(width: 8),

          // EMERGENCY MOTOR KILL
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcsColors.alertRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.dangerous, size: 15),
            label: const Text('MOTOR KILL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontFamily: 'monospace')),
            onPressed: () => mavlink.emergencyStop(),
          ),
        ],
      ),
    );
  }
}
