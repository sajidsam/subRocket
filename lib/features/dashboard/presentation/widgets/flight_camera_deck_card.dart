import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/mavlink_service.dart';

class FlightCameraDeckCard extends StatefulWidget {
  const FlightCameraDeckCard({super.key});

  @override
  State<FlightCameraDeckCard> createState() => _FlightCameraDeckCardState();
}

class _FlightCameraDeckCardState extends State<FlightCameraDeckCard> {
  bool _isVideoMode = true;
  String _selectedFrameLine = '1280 : 720';
  bool _awbActive = true;
  bool _dispActive = true;

  int _selectedIso = 600;
  final List<int> _isoOptions = [100, 200, 400, 600, 800, 1600, 3200];

  double _selectedShutter = 180.0;
  final List<double> _shutterOptions = [50.0, 100.0, 180.0, 250.0, 500.0, 1000.0];

  final List<String> _frameLines = [
    '1920 : 1080',
    '1280 : 720',
    '854 : 480',
    '640 : 360',
  ];

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section 1: Video/Photo Switcher & Tactical Mini Map
          SizedBox(
            width: 145,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Segmented Button: Video / Photo
                Container(
                  height: 28,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: GcsColors.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GcsColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => setState(() => _isVideoMode = true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isVideoMode ? GcsColors.cardSurfaceLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam,
                                  size: 13,
                                  color: _isVideoMode ? Colors.white : GcsColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Video',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _isVideoMode ? Colors.white : GcsColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => setState(() => _isVideoMode = false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isVideoMode ? GcsColors.cardSurfaceLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 12,
                                  color: !_isVideoMode ? Colors.white : GcsColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Photo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: !_isVideoMode ? Colors.white : GcsColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Tactical Mini Map Box
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1318),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GcsColors.border, width: 1),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: vehicle.currentLocation ?? const LatLng(40.7128, -74.0060),
                              initialZoom: 13.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.rocketcontroller.gcs',
                              ),
                              // Dark Overlay for Tactical Radar Style
                              Container(
                                color: const Color(0xFF0A0F14).withValues(alpha: 0.78),
                              ),
                              // Marker Layer
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: vehicle.currentLocation ?? const LatLng(40.7128, -74.0060),
                                    width: 20,
                                    height: 20,
                                    child: Transform.rotate(
                                      angle: vehicle.yaw * (pi / 180.0),
                                      child: const Icon(
                                        Icons.navigation,
                                        color: GcsColors.cyanAccent,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Subtle Map Grid & Label Overlay
                          Positioned(
                            top: 6,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'New York',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 6,
                            child: Text(
                              'BROOKLYN',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Section 2: VU Meter Bars & Telemetry Matrix (Speed, Height, Flight Time, Lens, ISO, Shutter)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Audio / Signal Meters
                Row(
                  children: [
                    _buildVuMeter('1', 0.75),
                    const SizedBox(width: 12),
                    _buildVuMeter('2', 0.60),
                  ],
                ),
                const SizedBox(height: 10),

                // 2-Column Telemetry Grid
                Expanded(
                  child: Row(
                    children: [
                      // Column 1
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTelemetryItem(
                              'SPEED',
                              vehicle.groundspeed > 0
                                  ? '${(vehicle.groundspeed * 3.6).toStringAsFixed(0)} km/h'
                                  : '20 km/h',
                            ),
                            _buildTelemetryItem(
                              'HEIGHT',
                              vehicle.altitudeAgl > 0
                                  ? '${vehicle.altitudeAgl.toStringAsFixed(0)} m'
                                  : '80 m',
                            ),
                            _buildTelemetryItem(
                              'FLIGHT TIME',
                              vehicle.flightDuration.inSeconds > 0
                                  ? '${(vehicle.flightDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(vehicle.flightDuration.inSeconds % 60).toString().padLeft(2, '0')}'
                                  : '05:43',
                            ),
                          ],
                        ),
                      ),

                      // Column 2
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTelemetryItem('LENS', '25 mm'),
                            InkWell(
                              onTap: () {
                                final currentIndex = _isoOptions.indexOf(_selectedIso);
                                setState(() {
                                  _selectedIso = _isoOptions[(currentIndex + 1) % _isoOptions.length];
                                });
                              },
                              child: _buildTelemetryItem('ISO', '$_selectedIso'),
                            ),
                            InkWell(
                              onTap: () {
                                final currentIndex = _shutterOptions.indexOf(_selectedShutter);
                                setState(() {
                                  _selectedShutter = _shutterOptions[(currentIndex + 1) % _shutterOptions.length];
                                });
                              },
                              child: _buildTelemetryItem('SHUTTER', _selectedShutter.toStringAsFixed(1)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Section 3: FRAME LINE Resolution Selector
          SizedBox(
            width: 85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'FRAME LINE',
                  style: TextStyle(
                    color: GcsColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                ..._frameLines.map((line) {
                  final isSelected = _selectedFrameLine == line;
                  return InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => setState(() => _selectedFrameLine = line),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Text(
                        line,
                        style: TextStyle(
                          color: isSelected ? Colors.white : GcsColors.textMuted,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Section 4: AWB/DISP Buttons & Tactical Jog Wheel / D-Pad
          SizedBox(
            width: 110,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // AWB and DISP Round Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRoundPillButton(
                      label: 'AWB',
                      isActive: _awbActive,
                      onTap: () => setState(() => _awbActive = !_awbActive),
                    ),
                    const SizedBox(width: 10),
                    _buildRoundPillButton(
                      label: 'DISP',
                      isActive: _dispActive,
                      onTap: () => setState(() => _dispActive = !_dispActive),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Large Gunmetal Jog Wheel / D-Pad
                _buildJogWheel(mavlink, vehicle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVuMeter(String channel, double fillRatio) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          channel,
          style: const TextStyle(
            color: GcsColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 50,
          height: 6,
          decoration: BoxDecoration(
            color: GcsColors.surfaceDark,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: GcsColors.borderSubtle, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillRatio,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF64748B),
                      Color(0xFF94A3B8),
                      Color(0xFFCBD5E1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GcsColors.textMuted,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildRoundPillButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 20,
        decoration: BoxDecoration(
          color: isActive ? GcsColors.cardSurfaceLight : GcsColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? GcsColors.borderLight : GcsColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : GcsColors.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJogWheel(MavlinkService mavlink, VehicleState vehicle) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF282F3B),
            Color(0xFF1E232C),
            Color(0xFF14171D),
          ],
        ),
        border: Border.all(color: GcsColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Up Button (Disp/menu)
          Positioned(
            top: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => mavlink.setThrottle((vehicle.throttlePercent + 5).clamp(0, 100).toDouble()),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 14),
                  Text(
                    'Disp/menu',
                    style: TextStyle(color: Colors.white60, fontSize: 6, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Down Button (mode)
          Positioned(
            bottom: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => mavlink.setThrottle((vehicle.throttlePercent - 5).clamp(0, 100).toDouble()),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'mode',
                    style: TextStyle(color: Colors.white60, fontSize: 6, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),

          // Left Button (<)
          Positioned(
            left: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => mavlink.manualControl(pitch: 0, roll: -200, throttle: 500, yaw: 0),
              child: const Icon(Icons.keyboard_arrow_left, color: Colors.white70, size: 16),
            ),
          ),

          // Right Button (>)
          Positioned(
            right: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => mavlink.manualControl(pitch: 0, roll: 200, throttle: 500, yaw: 0),
              child: const Icon(Icons.keyboard_arrow_right, color: Colors.white70, size: 16),
            ),
          ),

          // Center OK Button
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (vehicle.isArmed) {
                mavlink.emergencyStop();
              } else {
                mavlink.armVehicle();
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF181C23),
                border: Border.all(color: GcsColors.borderLight, width: 1),
              ),
              child: const Center(
                child: Icon(
                  Icons.circle,
                  color: Colors.white70,
                  size: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
