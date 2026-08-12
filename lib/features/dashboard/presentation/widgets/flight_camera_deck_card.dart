import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/mavlink_service.dart';
import 'camera_viewfinder_card.dart';

class FlightCameraDeckCard extends StatefulWidget {
  final bool isSwapped;
  final VoidCallback? onToggleSwap;

  const FlightCameraDeckCard({
    super.key,
    this.isSwapped = false,
    this.onToggleSwap,
  });

  @override
  State<FlightCameraDeckCard> createState() => _FlightCameraDeckCardState();
}

class _FlightCameraDeckCardState extends State<FlightCameraDeckCard> with SingleTickerProviderStateMixin {
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

  late AnimationController _animController;
  final MapController _miniMapController = MapController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final mavlink = context.watch<MavlinkService>();
    final LatLng currentPos = vehicle.currentLocation ?? vehicle.homeLocation;

    if (!widget.isSwapped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _miniMapController.move(currentPos, _miniMapController.camera.zoom);
          } catch (_) {}
        }
      });
    }

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
          // Section 1: Video/Photo Switcher & Tactical Mini Map / Mini Camera View
          SizedBox(
            width: 195,
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

                // Tactical Mini Box: Live Map OR Mini Camera Feed (Swappable)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1318),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GcsColors.border, width: 1),
                      ),
                      child: widget.isSwapped
                          ? _buildMiniCameraFeed(vehicle)
                          : _buildMiniMapFeed(vehicle, currentPos),
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

  Widget _buildMiniMapFeed(VehicleState vehicle, LatLng currentPos) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Clean Mini OpenStreetMap (NO dark shade)
        FlutterMap(
          mapController: _miniMapController,
          options: MapOptions(
            initialCenter: currentPos,
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
            MarkerLayer(
              markers: [
                Marker(
                  point: currentPos,
                  width: 24,
                  height: 24,
                  child: Transform.rotate(
                    angle: vehicle.yaw * (pi / 180.0),
                    child: const Icon(
                      Icons.navigation,
                      color: GcsColors.cyanAccent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Real-Time Coordinates Badge (Top-Left)
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: Text(
              '${currentPos.latitude.toStringAsFixed(4)}, ${currentPos.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),

        // 3. Screen Toggle / Swap Button (Bottom-Right)
        Positioned(
          bottom: 5,
          right: 5,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: widget.onToggleSwap,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: GcsColors.goldAccent, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: GcsColors.goldAccent.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sync,
                  color: GcsColors.goldAccent,
                  size: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCameraFeed(VehicleState vehicle) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Live Mountain Landscape Background
        CustomPaint(
          painter: MountainLandscapePainter(animation: _animController),
        ),

        // 2. Mini Horizon Reticle
        Center(
          child: Transform.rotate(
            angle: vehicle.roll * (pi / 180.0),
            child: const _MiniHorizonReticle(),
          ),
        ),

        // 3. CAM LIVE Badge (Top-Left)
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: GcsColors.channelRed.withValues(alpha: 0.8), width: 0.8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: GcsColors.channelRed, size: 5),
                SizedBox(width: 3),
                Text(
                  'CAM LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Screen Toggle / Swap Button (Bottom-Right)
        Positioned(
          bottom: 5,
          right: 5,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: widget.onToggleSwap,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: GcsColors.goldAccent, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: GcsColors.goldAccent.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sync,
                  color: GcsColors.goldAccent,
                  size: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniHorizonReticle extends StatelessWidget {
  const _MiniHorizonReticle();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 20),
      painter: _MiniReticlePainter(),
    );
  }
}

class _MiniReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx - 5, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + 5, center.dy),
      Offset(center.dx + 20, center.dy),
      paint,
    );
    canvas.drawCircle(center, 3.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
