import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/mavlink_service.dart';

class JcaSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const JcaSidebar({
    super.key,
    this.selectedIndex = 0,
    required this.onDestinationSelected,
  });

  @override
  State<JcaSidebar> createState() => _JcaSidebarState();
}

class _JcaSidebarState extends State<JcaSidebar> {
  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final mavlink = context.watch<MavlinkService>();

    return Container(
      width: 58,
      decoration: BoxDecoration(
        color: GcsColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GcsColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // JCA Brand Badge - clicking resets to Home Cockpit
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => widget.onDestinationSelected(0),
            child: Container(
              width: 38,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.selectedIndex == 0 ? GcsColors.goldAccent : GcsColors.borderLight,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'JCA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary Navigation Action Icons (Switching Outlet Views)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavIcon(
                    index: 0,
                    icon: Icons.hexagon_outlined,
                    tooltip: 'Cockpit View',
                    onTap: () => widget.onDestinationSelected(0),
                  ),
                  _buildNavIcon(
                    index: 1,
                    icon: Icons.gps_fixed,
                    tooltip: 'Target & Gimbal Tracking',
                    onTap: () => widget.onDestinationSelected(1),
                  ),
                  _buildNavIcon(
                    index: 2,
                    icon: Icons.photo_library_outlined,
                    tooltip: 'Flight Logs & Blackbox',
                    onTap: () => widget.onDestinationSelected(2),
                  ),
                  _buildNavIcon(
                    index: 3,
                    icon: Icons.wb_sunny_outlined,
                    tooltip: 'Camera & Lighting Controls',
                    onTap: () => widget.onDestinationSelected(3),
                  ),
                  _buildNavIcon(
                    index: 4,
                    icon: Icons.settings_outlined,
                    tooltip: 'Vehicle Parameters & Calibration',
                    onTap: () => widget.onDestinationSelected(4),
                  ),
                  _buildNavIcon(
                    index: 5,
                    icon: Icons.notifications_none_outlined,
                    badgeCount: vehicle.messageLog.length,
                    tooltip: 'System Alerts Log',
                    onTap: () => widget.onDestinationSelected(5),
                  ),
                  _buildNavIcon(
                    index: 6,
                    icon: Icons.flag_outlined,
                    tooltip: 'Mission Planner & Waypoints',
                    onTap: () => widget.onDestinationSelected(6),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Section: User Profile (Datalink) & Power Button
          const SizedBox(height: 8),
          Tooltip(
            message: 'Datalink & MAVLink Console',
            child: GestureDetector(
              onTap: () => widget.onDestinationSelected(7),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selectedIndex == 7 ? GcsColors.aviationBlue.withValues(alpha: 0.3) : GcsColors.cardSurfaceLight,
                  border: Border.all(
                    color: widget.selectedIndex == 7
                        ? GcsColors.aviationBlue
                        : (vehicle.isConnected ? GcsColors.greenActive : GcsColors.textMuted),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: widget.selectedIndex == 7 ? Colors.white : GcsColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 24,
            height: 1,
            color: GcsColors.border,
          ),
          const SizedBox(height: 10),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              Icons.power_settings_new,
              size: 20,
              color: vehicle.isArmed ? GcsColors.alertRed : GcsColors.textMuted,
            ),
            tooltip: vehicle.isArmed ? 'Disarm Motors' : 'Arm Vehicle Motors',
            onPressed: () {
              if (vehicle.isArmed) {
                mavlink.disarmVehicle();
              } else {
                mavlink.armVehicle();
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNavIcon({
    required int index,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? GcsColors.cardSurfaceLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? GcsColors.borderLight : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: isSelected ? GcsColors.textPrimary : GcsColors.textSecondary,
                ),
              ),
              if (badgeCount > 0 && index == 5)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: GcsColors.alertRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
