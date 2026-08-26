import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import 'agri_theme_constants.dart';

class AgriHeaderBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;
  final String activeTab;
  final ValueChanged<String> onTabSelected;
  final double totalAreaHa;

  const AgriHeaderBar({
    super.key,
    required this.onOpenDrawer,
    this.activeTab = 'Overview',
    required this.onTabSelected,
    this.totalAreaHa = 0.0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<AgriHeaderBar> createState() => _AgriHeaderBarState();
}

class _AgriHeaderBarState extends State<AgriHeaderBar> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: AgriColors.headerBackground,
        border: Border(
          bottom: BorderSide(color: AgriColors.border, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Drawer menu toggle & Logo
          InkWell(
            onTap: widget.onOpenDrawer,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AgriColors.orangeSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AgriColors.orangePrimary.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(
                      Icons.blur_on_rounded,
                      color: AgriColors.orangePrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'AG.',
                          style: TextStyle(
                            color: AgriColors.orangePrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Drone',
                          style: TextStyle(
                            color: AgriColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Navigation Tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildNavTab(
                    icon: Icons.sports_esports_outlined,
                    label: 'Controller',
                    isActive: widget.activeTab == 'Controller',
                    onTap: () => widget.onTabSelected('Controller'),
                  ),
                  const SizedBox(width: 6),
                  _buildNavTab(
                    icon: Icons.remove_red_eye_outlined,
                    label: 'Overview',
                    isActive: widget.activeTab == 'Overview',
                    onTap: () => widget.onTabSelected('Overview'),
                  ),
                  const SizedBox(width: 6),
                  _buildNavTab(
                    icon: Icons.electric_bolt_outlined,
                    label: 'Routes',
                    isActive: widget.activeTab == 'Routes',
                    onTap: () => widget.onTabSelected('Routes'),
                  ),
                  const SizedBox(width: 6),
                  _buildNavTab(
                    icon: Icons.hub_outlined,
                    label: 'All drones',
                    isActive: widget.activeTab == 'All drones',
                    onTap: () => widget.onTabSelected('All drones'),
                  ),
                  const SizedBox(width: 6),
                  _buildNavTab(
                    icon: Icons.map_outlined,
                    label: 'Map view',
                    isActive: widget.activeTab == 'Map view',
                    onTap: () => widget.onTabSelected('Map view'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Right metrics & Telemetry chips
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Area Metric
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.crop_free, size: 14, color: AgriColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    widget.totalAreaHa > 0
                        ? '${(widget.totalAreaHa * 0.01).toStringAsFixed(1)} km²'
                        : '243.4 km²',
                    style: const TextStyle(
                      color: AgriColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Weather Metric
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.cloud_outlined, size: 15, color: AgriColors.textSecondary),
                  SizedBox(width: 5),
                  Text(
                    'Rain, 36 °C',
                    style: TextStyle(
                      color: AgriColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Ongoing Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AgriColors.cardElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: vehicle.isArmed
                        ? AgriColors.greenActive.withValues(alpha: 0.6)
                        : AgriColors.yellowAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: vehicle.isArmed ? AgriColors.greenActive : AgriColors.yellowAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vehicle.isArmed ? 'Active • 100%' : 'Ongoing • 0%',
                      style: TextStyle(
                        color: vehicle.isArmed ? AgriColors.greenActive : AgriColors.yellowAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.flight,
                      size: 13,
                      color: vehicle.isArmed ? AgriColors.greenActive : AgriColors.yellowAmber,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Digital Clock
              Text(
                _formatTime(_currentTime),
                style: const TextStyle(
                  color: AgriColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AgriColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AgriColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
