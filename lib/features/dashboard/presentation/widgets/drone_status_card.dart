import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/mavlink_service.dart';

class DroneStatusCard extends StatefulWidget {
  const DroneStatusCard({super.key});

  @override
  State<DroneStatusCard> createState() => _DroneStatusCardState();
}

class _DroneStatusCardState extends State<DroneStatusCard> {
  double _altitudeLimit = 270.0;
  double _gimbalTilt = 8.3;
  bool _hdrPlusActive = true;
  bool _nightModeActive = false;
  bool _gimbalLockActive = false;

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final mavlink = context.watch<MavlinkService>();

    return Container(
      decoration: BoxDecoration(
        color: GcsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GcsColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Drone Model Title + Live Feed Subtitle + Drone Graphic
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DJI Mavic pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'FHD high-Framerate Live Feed',
                      style: TextStyle(
                        color: GcsColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Drone Isometric Icon
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: GcsColors.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GcsColors.borderSubtle),
                ),
                child: const Center(
                  child: Icon(
                    Icons.flight,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Battery Status Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Battery status',
                style: TextStyle(
                  color: GcsColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                vehicle.batteryRemaining > 0 ? '${vehicle.batteryRemaining}%' : '75%',
                style: const TextStyle(
                  color: GcsColors.goldAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          const Text(
            '12 min ago',
            style: TextStyle(
              color: GcsColors.textMuted,
              fontSize: 9,
            ),
          ),

          const Spacer(),

          // Altitude Limited Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Altitude limited',
                style: TextStyle(
                  color: GcsColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_altitudeLimit.toStringAsFixed(0)} MI',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 14,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2.0,
                activeTrackColor: Colors.white60,
                inactiveTrackColor: GcsColors.borderLight,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8.0),
              ),
              child: Slider(
                value: _altitudeLimit,
                min: 50.0,
                max: 500.0,
                onChanged: (val) {
                  setState(() => _altitudeLimit = val);
                  vehicle.updateGeofence(
                    enabled: vehicle.geofenceEnabled,
                    maxAlt: val,
                    maxRadius: vehicle.geofenceMaxRadius,
                  );
                },
              ),
            ),
          ),

          const Spacer(),

          // Gimbal Tilt Slider Section
          Row(
            children: [
              // Gimbal Symbol (● O)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 1.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Gimbal Slider Track
              Expanded(
                child: SizedBox(
                  height: 14,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2.0,
                      activeTrackColor: Colors.white60,
                      inactiveTrackColor: GcsColors.borderLight,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 8.0),
                    ),
                    child: Slider(
                      value: _gimbalTilt,
                      min: 0.0,
                      max: 90.0,
                      onChanged: (val) {
                        setState(() => _gimbalTilt = val);
                        mavlink.manualControl(
                          pitch: 0,
                          roll: 0,
                          throttle: 500,
                          yaw: 0,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Gimbal Value
              Text(
                _gimbalTilt.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          const Spacer(),

          // Bottom 3 Quick Mode Action Buttons (HDR+, Night, Gimbal Lock)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundActionButton(
                icon: Icons.camera,
                label: 'HDR+',
                isActive: _hdrPlusActive,
                onTap: () => setState(() => _hdrPlusActive = !_hdrPlusActive),
              ),
              const SizedBox(width: 16),
              _buildRoundActionButton(
                icon: Icons.nightlight_round,
                isActive: _nightModeActive,
                onTap: () => setState(() => _nightModeActive = !_nightModeActive),
              ),
              const SizedBox(width: 16),
              _buildRoundActionButton(
                icon: Icons.filter_center_focus,
                isActive: _gimbalLockActive,
                onTap: () => setState(() => _gimbalLockActive = !_gimbalLockActive),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundActionButton({
    IconData? icon,
    String? label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? GcsColors.cardSurfaceLight : GcsColors.surfaceDark,
          border: Border.all(
            color: isActive ? GcsColors.borderLight : GcsColors.borderSubtle,
            width: 1.2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
          ],
        ),
        child: Center(
          child: label != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.circle_outlined,
                      size: 11,
                      color: isActive ? Colors.white : GcsColors.textMuted,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : GcsColors.textMuted,
                      ),
                    ),
                  ],
                )
              : Icon(
                  icon,
                  size: 16,
                  color: isActive ? Colors.white : GcsColors.textMuted,
                ),
        ),
      ),
    );
  }
}
