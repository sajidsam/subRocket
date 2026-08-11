import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flight_mode.dart';
import '../../models/vehicle_state.dart';
import '../../services/mavlink_service.dart';
import '../theme/gcs_theme.dart';

class GcsStatusBar extends StatelessWidget {
  const GcsStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final mavlink = context.watch<MavlinkService>();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: GcsColors.surfaceDark.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: GcsColors.border, width: 1.5)),
      ),
      child: Row(
        children: [
          // Drawer trigger button
          IconButton(
            icon: const Icon(Icons.menu, color: GcsColors.cyanAccent, size: 22),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Navigation Menu',
          ),
          const SizedBox(width: 8),

          // Flight Mode Dropdown
          _buildModeDropdown(context, vehicle, mavlink),
          const SizedBox(width: 8),

          // Arming Button
          _buildArmButton(context, vehicle, mavlink),
          const SizedBox(width: 12),

          // GPS Status
          _buildGpsBadge(vehicle),
          const SizedBox(width: 12),

          // Battery Meter
          _buildBatteryGauge(vehicle),
          const SizedBox(width: 12),

          // Datalink Status
          _buildDatalinkBadge(vehicle, mavlink),
          const SizedBox(width: 12),

          // Real-time STATUSTEXT Marquee
          Expanded(
            child: _buildStatusTicker(vehicle),
          ),
        ],
      ),
    );
  }

  Widget _buildModeDropdown(BuildContext context, VehicleState vehicle, MavlinkService mavlink) {
    return PopupMenuButton<FlightMode>(
      tooltip: 'Select Flight Mode',
      color: GcsColors.surfaceDark,
      onSelected: (mode) => mavlink.setFlightMode(mode),
      itemBuilder: (context) {
        return FlightMode.values.map((m) {
          return PopupMenuItem<FlightMode>(
            value: m,
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: m.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(m.name, style: TextStyle(color: m.color, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: vehicle.mode.color.withValues(alpha: 0.2),
          border: Border.all(color: vehicle.mode.color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight, color: vehicle.mode.color, size: 16),
            const SizedBox(width: 6),
            Text(
              vehicle.mode.name,
              style: TextStyle(
                color: vehicle.mode.color,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildArmButton(BuildContext context, VehicleState vehicle, MavlinkService mavlink) {
    final isArmed = vehicle.isArmed;
    return InkWell(
      onTap: () {
        if (!isArmed) {
          _showArmConfirmationDialog(context, mavlink);
        } else {
          mavlink.armDisarm(false);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isArmed ? GcsColors.alertRed.withValues(alpha: 0.25) : Colors.grey[800],
          border: Border.all(
            color: isArmed ? GcsColors.alertRed : Colors.white38,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isArmed ? Icons.power : Icons.power_off,
              color: isArmed ? GcsColors.alertRed : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isArmed ? 'ARMED' : 'DISARMED',
              style: TextStyle(
                color: isArmed ? GcsColors.alertRed : Colors.white70,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArmConfirmationDialog(BuildContext context, MavlinkService mavlink) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GcsColors.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.warning, color: GcsColors.warningOrange),
            SizedBox(width: 8),
            Text('ARM VEHICLE MOTORS?', style: TextStyle(fontFamily: 'monospace')),
          ],
        ),
        content: const Text(
          'Make sure the flight area is clear and all pre-arm checks pass before spinning motors.',
          style: TextStyle(fontFamily: 'monospace', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GcsColors.alertRed),
            onPressed: () {
              Navigator.pop(ctx);
              mavlink.armDisarm(true);
            },
            child: const Text('CONFIRM ARM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsBadge(VehicleState vehicle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GcsColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: GcsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.satellite_alt, color: GcsColors.cyanAccent, size: 14),
          const SizedBox(width: 4),
          Text(
            '${vehicle.gpsFix.name} (${vehicle.satellitesVisible})',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white),
          ),
          const SizedBox(width: 4),
          Text(
            'HDOP:${vehicle.hdop.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: GcsColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryGauge(VehicleState vehicle) {
    final pct = vehicle.batteryRemaining;
    final color = pct > 40 ? GcsColors.greenActive : (pct > 20 ? GcsColors.warningOrange : GcsColors.alertRed);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GcsColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: GcsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_charging_full, color: color, size: 15),
          const SizedBox(width: 4),
          Text(
            '${vehicle.batteryVoltage.toStringAsFixed(1)}V ($pct%)',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            '${vehicle.batteryCurrent.toStringAsFixed(1)}A',
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: GcsColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDatalinkBadge(VehicleState vehicle, MavlinkService mavlink) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GcsColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: GcsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            vehicle.isConnected ? Icons.wifi : Icons.wifi_off,
            color: vehicle.isConnected ? GcsColors.greenActive : GcsColors.alertRed,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            vehicle.isConnected ? '${vehicle.pingMs}ms' : 'DISCONNECTED',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: vehicle.isConnected ? Colors.white : GcsColors.alertRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTicker(VehicleState vehicle) {
    final latestMsg = vehicle.messageLog.isNotEmpty ? vehicle.messageLog.first : null;
    if (latestMsg == null) {
      return const Text(
        'STATUSTEXT: System Ready. Autopilot connected.',
        style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: GcsColors.textSecondary),
        overflow: TextOverflow.ellipsis,
      );
    }

    Color color;
    switch (latestMsg.severity) {
      case SeverityLevel.critical:
        color = GcsColors.alertRed;
        break;
      case SeverityLevel.warning:
        color = GcsColors.warningOrange;
        break;
      case SeverityLevel.notice:
        color = GcsColors.cyanAccent;
        break;
      case SeverityLevel.info:
        color = Colors.white70;
        break;
    }

    return Row(
      children: [
        Icon(Icons.terminal, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            latestMsg.text,
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: color, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
