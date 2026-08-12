import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import 'tactical_compass_card.dart';

class CameraViewfinderCard extends StatefulWidget {
  final bool isSwapped;
  final VoidCallback? onToggleSwap;

  const CameraViewfinderCard({
    super.key,
    this.isSwapped = false,
    this.onToggleSwap,
  });

  @override
  State<CameraViewfinderCard> createState() => _CameraViewfinderCardState();
}

class _CameraViewfinderCardState extends State<CameraViewfinderCard> with SingleTickerProviderStateMixin {
  bool _isHdrActive = true;
  bool _isPaused = false;
  bool _isRecording = true;
  int _recordSeconds = 129; // 02:09 initial
  Timer? _recordTimer;
  double _levelValue = 0.5;
  String _levelUnit = 'KT';

  late AnimationController _animController;
  final MapController _primaryMapController = MapController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && !_isPaused) {
        setState(() {
          _recordSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final LatLng currentPos = vehicle.currentLocation ?? vehicle.homeLocation;

    if (widget.isSwapped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _primaryMapController.move(currentPos, _primaryMapController.camera.zoom);
          } catch (_) {}
        }
      });
      return _buildPrimaryMapView(vehicle, currentPos);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: GcsColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GcsColors.border, width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Realistic Mountain Landscape Camera Feed Background
            CustomPaint(
              painter: MountainLandscapePainter(animation: _animController),
            ),

            // 2. Rule of Thirds Grid Overlay
            CustomPaint(
              painter: ViewfinderGridPainter(),
            ),

            // 3. Center Artificial Horizon / Reticle
            Center(
              child: Transform.rotate(
                angle: vehicle.roll * (pi / 180.0),
                child: Transform.translate(
                  offset: Offset(0, (vehicle.pitch * 1.5).clamp(-60.0, 60.0)),
                  child: const ArtificialHorizonReticle(),
                ),
              ),
            ),

            // 4. Top-Left HUD Telemetry Overlay
            Positioned(
              top: 14,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HDR Pill Button
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _isHdrActive = !_isHdrActive),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isHdrActive
                            ? GcsColors.cardSurfaceLight.withValues(alpha: 0.85)
                            : Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isHdrActive ? Colors.white54 : GcsColors.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'HDR',
                        style: TextStyle(
                          color: _isHdrActive ? Colors.white : GcsColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4K . 19.67FPS Text in Warm Gold
                  const Text(
                    '4K . 19.67FPS',
                    style: TextStyle(
                      color: GcsColors.goldAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // LEVEL Slider & KT Pill
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LEVEL',
                            style: TextStyle(
                              color: GcsColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 60,
                            height: 12,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 1.5,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 6),
                                activeTrackColor: Colors.white70,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: _levelValue,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (val) => setState(() => _levelValue = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // KT Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Text(
                      _levelUnit,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Multi-Channel RGBY Dots Matrix
                  Row(
                    children: [
                      _buildChannelDot(GcsColors.channelRed, 'R'),
                      const SizedBox(width: 8),
                      _buildChannelDot(GcsColors.channelGreen, 'G'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildChannelDot(GcsColors.channelBlue, 'B'),
                      const SizedBox(width: 8),
                      _buildChannelDot(GcsColors.channelYellow, 'Y'),
                    ],
                  ),
                ],
              ),
            ),

            // 5. Bottom-Left Histogram Box [H2.85]
            Positioned(
              bottom: 14,
              left: 16,
              child: Container(
                width: 76,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'H2.85',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 68,
                      height: 26,
                      child: CustomPaint(
                        painter: _HistogramPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Top-Right Controls (Pause & Record Timer)
            Positioned(
              top: 14,
              right: 16,
              child: Row(
                children: [
                  // Pause / Play Button
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _isPaused = !_isPaused),
                    child: Container(
                      width: 32,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: GcsColors.borderLight, width: 1),
                      ),
                      child: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white70,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Record Timer Pill
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _isRecording = !_isRecording),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: GcsColors.borderLight, width: 1),
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _isRecording
                                      ? GcsColors.goldAccent.withValues(
                                          alpha: _isPaused ? 0.3 : (0.5 + 0.5 * sin(_animController.value * 2 * pi).abs()),
                                        )
                                      : GcsColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTimer(_recordSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 7. Bottom-Right (3rd Column, 3rd Row): Tactical Compass Overlay on Camera Feed
            const Positioned(
              bottom: 12,
              right: 14,
              width: 145,
              height: 145,
              child: TacticalCompassCard(isOverlay: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryMapView(VehicleState vehicle, LatLng currentPos) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: GcsColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GcsColors.border, width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full OpenStreetMap View (No Dark Shade)
            FlutterMap(
              mapController: _primaryMapController,
              options: MapOptions(
                initialCenter: currentPos,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.rocketcontroller.gcs',
                ),
                MarkerLayer(
                  markers: [
                    // Home Marker
                    Marker(
                      point: vehicle.homeLocation,
                      width: 32,
                      height: 32,
                      child: const Icon(
                        Icons.home,
                        color: GcsColors.goldAccent,
                        size: 28,
                      ),
                    ),
                    // Real-Time Drone Marker
                    Marker(
                      point: currentPos,
                      width: 44,
                      height: 44,
                      child: Transform.rotate(
                        angle: vehicle.yaw * (pi / 180.0),
                        child: const Icon(
                          Icons.navigation,
                          color: GcsColors.cyanAccent,
                          size: 38,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 2. Top-Left HUD Telemetry Overlay on Map
            Positioned(
              top: 14,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: GcsColors.channelGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.gpsFix.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SATS: ${vehicle.satellitesVisible}',
                          style: const TextStyle(
                            color: GcsColors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentPos.latitude.toStringAsFixed(6)}° N, ${currentPos.longitude.toStringAsFixed(6)}° E',
                      style: const TextStyle(
                        color: GcsColors.goldAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Top-Right Swap / Toggle Return Button
            Positioned(
              top: 14,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.onToggleSwap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GcsColors.goldAccent, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: GcsColors.goldAccent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sync, color: GcsColors.goldAccent, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'CAMERA VIEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Bottom-Right: Tactical Compass Overlay
            const Positioned(
              bottom: 12,
              right: 14,
              width: 145,
              height: 145,
              child: TacticalCompassCard(isOverlay: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Center Artificial Horizon Reticle (Clean Aircraft Symbol)
class ArtificialHorizonReticle extends StatelessWidget {
  const ArtificialHorizonReticle({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 40),
      painter: _ReticlePainter(),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Left Wing Line
    canvas.drawLine(
      Offset(center.dx - 48, center.dy),
      Offset(center.dx - 12, center.dy),
      paint,
    );

    // Right Wing Line
    canvas.drawLine(
      Offset(center.dx + 12, center.dy),
      Offset(center.dx + 48, center.dy),
      paint,
    );

    // Center Circle & Dot
    canvas.drawCircle(center, 7.0, paint);
    canvas.drawCircle(
      center,
      1.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Viewfinder Grid Overlay (Rule of Thirds Dotted Lines)
class ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical Lines (1/3 and 2/3)
    final v1 = size.width / 3;
    final v2 = size.width * 2 / 3;
    canvas.drawLine(Offset(v1, 0), Offset(v1, size.height), paint);
    canvas.drawLine(Offset(v2, 0), Offset(v2, size.height), paint);

    // Horizontal Lines (1/3 and 2/3)
    final h1 = size.height / 3;
    final h2 = size.height * 2 / 3;
    canvas.drawLine(Offset(0, h1), Offset(size.width, h1), paint);
    canvas.drawLine(Offset(0, h2), Offset(size.width, h2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Dynamic Live Histogram Waveform Monitor Painter
class _HistogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.15, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height * 0.25);
    path.lineTo(size.width * 0.45, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.15);
    path.lineTo(size.width * 0.75, size.height * 0.4);
    path.lineTo(size.width * 0.9, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.65);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Alpine Mountain View Background Painter
class MountainLandscapePainter extends CustomPainter {
  final Animation<double> animation;

  MountainLandscapePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Sky Gradient with soft daylight glow
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF9AB2C5), // Crisp sky blue
        const Color(0xFFC7D7E2), // Pale misty horizon
        const Color(0xFF8294A2), // Soft mountain haze
      ],
      stops: const [0.0, 0.45, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = skyGradient.createShader(rect));

    // Far Distant Mountains
    final farMountainPath = Path();
    farMountainPath.moveTo(0, size.height * 0.6);
    farMountainPath.lineTo(size.width * 0.2, size.height * 0.42);
    farMountainPath.lineTo(size.width * 0.4, size.height * 0.48);
    farMountainPath.lineTo(size.width * 0.55, size.height * 0.38);
    farMountainPath.lineTo(size.width * 0.75, size.height * 0.45);
    farMountainPath.lineTo(size.width, size.height * 0.55);
    farMountainPath.lineTo(size.width, size.height);
    farMountainPath.lineTo(0, size.height);
    farMountainPath.close();

    canvas.drawPath(
      farMountainPath,
      Paint()
        ..color = const Color(0xFF6B7F91).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );

    // Dramatic Sharp Alpine Ridge Peak (Right side & Valley)
    final ridgePath = Path();
    ridgePath.moveTo(size.width * 0.35, size.height);
    ridgePath.lineTo(size.width * 0.45, size.height * 0.55);
    ridgePath.lineTo(size.width * 0.58, size.height * 0.65);
    ridgePath.lineTo(size.width * 0.68, size.height * 0.36); // Sharp peak
    ridgePath.lineTo(size.width * 0.74, size.height * 0.42);
    ridgePath.lineTo(size.width * 0.82, size.height * 0.28); // Highest peak
    ridgePath.lineTo(size.width * 0.92, size.height * 0.45);
    ridgePath.lineTo(size.width, size.height * 0.38);
    ridgePath.lineTo(size.width, size.height);
    ridgePath.close();

    final ridgeGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF8B7765), // Sunlit rock
        const Color(0xFF4A423B), // Shadowed crag
        const Color(0xFF2C2723), // Deep ravine
      ],
    );
    canvas.drawPath(
      ridgePath,
      Paint()
        ..shader = ridgeGradient.createShader(rect)
        ..style = PaintingStyle.fill,
    );

    // Left Foreground Crags
    final leftCrag = Path();
    leftCrag.moveTo(0, size.height);
    leftCrag.lineTo(0, size.height * 0.5);
    leftCrag.lineTo(size.width * 0.18, size.height * 0.62);
    leftCrag.lineTo(size.width * 0.28, size.height * 0.75);
    leftCrag.lineTo(size.width * 0.4, size.height);
    leftCrag.close();

    canvas.drawPath(
      leftCrag,
      Paint()
        ..color = const Color(0xFF38322D)
        ..style = PaintingStyle.fill,
    );

    // Subtle lens vignette
    final vignette = RadialGradient(
      center: Alignment.center,
      radius: 1.1,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.4),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = vignette.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant MountainLandscapePainter oldDelegate) => false;
}
