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
  final bool isDispActive;
  final VoidCallback? onToggleDisp;
  final VoidCallback? onToggleSwap;

  const FlightCameraDeckCard({
    super.key,
    this.isSwapped = false,
    this.isDispActive = true,
    this.onToggleDisp,
    this.onToggleSwap,
  });

  @override
  State<FlightCameraDeckCard> createState() => _FlightCameraDeckCardState();
}

class _FlightCameraDeckCardState extends State<FlightCameraDeckCard> with SingleTickerProviderStateMixin {
  bool _isVideoMode = true;
  String _selectedFrameLine = '1280 : 720';
  bool _awbActive = true;
  bool _internalDispActive = true;
  bool get _dispActive => widget.onToggleDisp != null ? widget.isDispActive : _internalDispActive;

  // Slider: Resolution px (px values: 2 to 14 px)
  double _resolutionPx = 8.0;
  final List<double> _resolutionSteps = [2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0];

  // 3-Segment Selector (ISO / HDR / DVR)
  String _selectedMode = 'HDR';

  // Precision Rotary Knob Dial (Image 1 reference)
  double _knobValue = 0.65;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availWidth = constraints.maxWidth;
        final bool isCompact = availWidth < 680;
        final double section1Width = isCompact ? 140.0 : 170.0;
        final double section2Width = isCompact ? 190.0 : 250.0;
        final double section3Width = isCompact ? 75.0 : 92.0;
        final double gap = isCompact ? 6.0 : 10.0;
        final double gapResToFrame = isCompact ? 14.0 : 24.0;

        return Container(
          decoration: BoxDecoration(
            color: GcsColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GcsColors.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section 1: Video/Photo Switcher & Tactical Mini Map / Mini Camera View
              SizedBox(
                width: section1Width,
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
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: GcsColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(5),
                              onTap: () => setState(() => _isVideoMode = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isVideoMode ? GcsColors.cardSurfaceLight : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.videocam,
                                      size: 13,
                                      color: _isVideoMode ? Colors.white : GcsColors.textMuted,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Video',
                                      style: TextStyle(
                                        fontSize: 10.5,
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
                              borderRadius: BorderRadius.circular(5),
                              onTap: () => setState(() => _isVideoMode = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isVideoMode ? GcsColors.cardSurfaceLight : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 12,
                                      color: !_isVideoMode ? Colors.white : GcsColors.textMuted,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Photo',
                                      style: TextStyle(
                                        fontSize: 10.5,
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
                    const SizedBox(height: 5),

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

              SizedBox(width: gap),

              // Section 2: Resolution px Slider (250px) + ISO / HDR / DVR Mode Bar
              SizedBox(
                width: section2Width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Resolution px Slider Section
                    _buildResolutionPxSection(),

                    // ISO / HDR / DVR Mode Tab Bar
                    _buildModeTabBar(),
                  ],
                ),
              ),

              // Increased gap between Resolution px and FRAME LINE
              SizedBox(width: gapResToFrame),

              // Section 3: FRAME LINE Resolution Selector
              SizedBox(
                width: section3Width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'FRAME LINE',
                      style: TextStyle(
                        color: GcsColors.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                              fontSize: 10.5,
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

              // Spacer to right-align ZOOM and D-Pad controls completely to the far right
              const Spacer(),

              // Section 4 & 5: Hardware Camera Controls (ZOOM Dial on LEFT, D-Pad on RIGHT)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ZOOM Rotary Dial Knob (2x Size: 100px on LEFT)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header offset matching AWB/DISP height (28 + 14) so circles align perfectly
                      const SizedBox(height: 42),
                      _RotaryKnobDial(
                        value: _knobValue,
                        size: const Size(100, 100),
                        label: 'ZOOM',
                        onChanged: (val) {
                          setState(() => _knobValue = val);
                          final targetZoom = 10.0 + val * 8.0;
                          try {
                            _miniMapController.move(_miniMapController.camera.center, targetZoom);
                          } catch (_) {}
                        },
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // D-Pad + AWB/DISP unit (2x Size: 100px on RIGHT)
                  _CameraDpadControl(
                    awbActive: _awbActive,
                    dispActive: _dispActive,
                    onToggleAwb: () => setState(() => _awbActive = !_awbActive),
                    onToggleDisp: () {
                      if (widget.onToggleDisp != null) {
                        widget.onToggleDisp!();
                      } else {
                        setState(() => _internalDispActive = !_internalDispActive);
                      }
                    },
                  ),
                ],
              ),

              // 20px spacing to shift D-Pad and controls left from right edge
              const SizedBox(width: 20),
            ],
          ),
        );
      },
    );
  }

  // Resolution px Slider Section (beside the map)
  Widget _buildResolutionPxSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Resolution px',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 3),
        _RulerSlider(
          value: _resolutionPx,
          min: 2.0,
          max: 14.0,
          unit: 'px',
          onChanged: (val) {
            setState(() => _resolutionPx = val);
          },
        ),
        const SizedBox(height: 2),
        _ScaleLabelsRow(
          steps: _resolutionSteps,
          currentVal: _resolutionPx,
          unit: 'px',
          onSelect: (val) {
            setState(() => _resolutionPx = val);
          },
        ),
      ],
    );
  }

  // Bottom 3-Segment Button Bar: ISO / HDR / DVR
  Widget _buildModeTabBar() {
    return Container(
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF13171E),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          _buildModeTab('ISO'),
          _buildModeTab('HDR'),
          _buildModeTab('DVR'),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label) {
    final isSelected = _selectedMode == label;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: () => setState(() => _selectedMode = label),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFA7B35) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFA7B35).withValues(alpha: 0.35),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF9AA4B2),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundPillButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 22,
        decoration: BoxDecoration(
          color: isActive ? GcsColors.cardSurfaceLight : GcsColors.surfaceDark,
          borderRadius: BorderRadius.circular(11),
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
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMapFeed(VehicleState vehicle, LatLng currentPos) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Clean Mini OpenStreetMap (Interactive with Pinch/Pan/Scroll Zoom)
        FlutterMap(
          mapController: _miniMapController,
          options: MapOptions(
            initialCenter: currentPos,
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
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

        // 3. Mini Telemetry Info (Top-Left)
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
            child: const Text(
              'CAM LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
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

// Interactive Ruler Slider Track with Orange Handle & Readout
class _RulerSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _RulerSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF13171E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          // Slider Track with Ticks & Sliding Handle
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                const thumbWidth = 20.0;
                final availableWidth = trackWidth - thumbWidth;
                final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);
                final thumbLeft = ratio * availableWidth;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    final newRatio = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                    final newVal = min + newRatio * (max - min);
                    onChanged(newVal);
                  },
                  onTapDown: (details) {
                    final newRatio = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                    final newVal = min + newRatio * (max - min);
                    onChanged(newVal);
                  },
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Ruler Ticks
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RulerTicksPainter(tickCount: 12),
                        ),
                      ),

                      // Orange Thumb Handle
                      Positioned(
                        left: thumbLeft,
                        top: 2,
                        bottom: 2,
                        child: Container(
                          width: thumbWidth,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFA7B35),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFA7B35).withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 1.2, height: 11, color: const Color(0xFF1E222A)),
                                const SizedBox(width: 2.0),
                                Container(width: 1.2, height: 11, color: const Color(0xFF1E222A)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Divider
          Container(width: 1, height: 18, color: Colors.white24),

          // Value Readout (e.g. 8 px)
          Container(
            width: 48,
            alignment: Alignment.center,
            child: Text(
              '${value.round()} $unit',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Scale Labels Row with Teal Dot and Stepped Values
class _ScaleLabelsRow extends StatelessWidget {
  final List<double> steps;
  final double currentVal;
  final String unit;
  final ValueChanged<double> onSelect;

  const _ScaleLabelsRow({
    required this.steps,
    required this.currentVal,
    required this.unit,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          // Teal Dot
          Container(
            width: 4.0,
            height: 4.0,
            decoration: const BoxDecoration(
              color: Color(0xFF20DFB3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),

          // Stepped Scale Labels with Dashes
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: steps.map((step) {
                final isCurrent = (currentVal - step).abs() < 1.0;
                final isEdge = step == steps.first || step == steps.last;
                final text = isEdge ? '${step.toInt()}$unit' : '${step.toInt()}';
                return InkWell(
                  onTap: () => onSelect(step),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isCurrent ? Colors.white : const Color(0xFF8896A6),
                      fontSize: 7.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter for Ruler Tick Marks inside Slider Track
class _RulerTicksPainter extends CustomPainter {
  final int tickCount;

  _RulerTicksPainter({required this.tickCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    final step = size.width / (tickCount + 1);
    for (int i = 1; i <= tickCount; i++) {
      final x = i * step;
      canvas.drawLine(
        Offset(x, size.height * 0.3),
        Offset(x, size.height * 0.7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

// Precision Hardware-style Rotary Knob Dial (2x Size reference)
class _RotaryKnobDial extends StatelessWidget {
  final double value;
  final String label;
  final Size size;
  final ValueChanged<double> onChanged;

  const _RotaryKnobDial({
    required this.value,
    required this.label,
    this.size = const Size(100, 100),
    required this.onChanged,
  });

  void _handleGesture(Offset localPos, Size dialSize) {
    final center = Offset(dialSize.width / 2, dialSize.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    // Angle in degrees [0, 360)
    double deg = atan2(dy, dx) * 180.0 / pi;
    if (deg < 0) deg += 360.0;

    // Start at 135 deg (bottom-left), 270 deg sweep clockwise to 45 deg (bottom-right)
    double sweepDeg = deg - 135.0;
    if (sweepDeg < 0) sweepDeg += 360.0;

    if (sweepDeg <= 270.0) {
      onChanged((sweepDeg / 270.0).clamp(0.0, 1.0));
    } else {
      if (sweepDeg < 315.0) {
        onChanged(1.0);
      } else {
        onChanged(0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _handleGesture(details.localPosition, size),
          onPanUpdate: (details) => _handleGesture(details.localPosition, size),
          onTapDown: (details) => _handleGesture(details.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _RotaryKnobPainter(value: value),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: GcsColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _RotaryKnobPainter extends CustomPainter {
  final double value;

  _RotaryKnobPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const startAngle = 135.0 * (pi / 180.0);
    const totalSweep = 270.0 * (pi / 180.0);
    final currentAngle = startAngle + totalSweep * value.clamp(0.0, 1.0);

    // 1. Straight Radial Gauge Tick Marks around Knob (no outer circle or dot marks)
    const int tickCount = 28;
    final bezelRadius = radius - 10.5;
    final innerTickRadius = bezelRadius + 2.5;
    final outerTickRadius = innerTickRadius + 5.5;

    for (int i = 0; i < tickCount; i++) {
      final double t = i / (tickCount - 1);
      final double angle = startAngle + t * totalSweep;
      final bool isLit = t <= value;
      final bool isMajor = (i % 5 == 0);

      final p1 = center + Offset(cos(angle) * innerTickRadius, sin(angle) * innerTickRadius);
      final p2 = center + Offset(
        cos(angle) * (outerTickRadius + (isMajor ? 2.5 : 0.0)),
        sin(angle) * (outerTickRadius + (isMajor ? 2.5 : 0.0)),
      );

      if (isLit) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = isMajor ? 3.5 : 2.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawLine(p1, p2, glowPaint);
      }

      final tickPaint = Paint()
        ..color = isLit ? Colors.white : const Color(0xFF3F4655)
        ..strokeWidth = isMajor ? 1.8 : 1.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);
    }

    // 2. Outer Bezel / Collar of Rotary Knob
    final bezelRect = Rect.fromCircle(center: center, radius: bezelRadius);

    // Drop shadow
    canvas.drawShadow(
      Path()..addOval(bezelRect),
      Colors.black,
      6.0,
      false,
    );

    // Bezel gradient fill
    final bezelPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF333844), Color(0xFF181B22)],
        stops: [0.75, 1.0],
      ).createShader(bezelRect);
    canvas.drawCircle(center, bezelRadius, bezelPaint);

    // Bezel border
    final bezelBorderPaint = Paint()
      ..color = const Color(0xFF3F4655)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, bezelRadius, bezelBorderPaint);

    // 3. Inner Rotary Knob Cap (Cylindrical Metallic Disc)
    final capRadius = bezelRadius - 5.0;
    final capRect = Rect.fromCircle(center: center, radius: capRadius);

    final capPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4D5464),
          Color(0xFF2C313C),
          Color(0xFF16181E),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(capRect);
    canvas.drawCircle(center, capRadius, capPaint);

    // Cap inner border highlight
    final capBorderPaint = Paint()
      ..color = const Color(0xFF5A6375).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, capRadius, capBorderPaint);

    // 4. Indicator Pip (Glowing White Dot on Knob)
    final pipRadius = capRadius * 0.62;
    final pipPos = center + Offset(cos(currentAngle) * pipRadius, sin(currentAngle) * pipRadius);

    // Pip glow
    final pipGlowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(pipPos, 5.0, pipGlowPaint);

    // Pip solid white dot
    final pipCorePaint = Paint()..color = Colors.white;
    canvas.drawCircle(pipPos, 2.6, pipCorePaint);
  }

  @override
  bool shouldRepaint(covariant _RotaryKnobPainter oldDelegate) => oldDelegate.value != value;
}

// Integrated AWB / DISP & 4-Way Directional D-Pad Control (2x Size Reference match)
class _CameraDpadControl extends StatelessWidget {
  final bool awbActive;
  final bool dispActive;
  final VoidCallback onToggleAwb;
  final VoidCallback onToggleDisp;
  final Function(String direction)? onDirection;
  final VoidCallback? onCenterTap;

  const _CameraDpadControl({
    required this.awbActive,
    required this.dispActive,
    required this.onToggleAwb,
    required this.onToggleDisp,
    this.onDirection,
    this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    const double dpadSize = 100.0;

    return SizedBox(
      width: dpadSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Row: AWB & DISP rectangular flat buttons side by side
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: onToggleAwb,
                    child: Container(
                      decoration: BoxDecoration(
                        color: awbActive ? const Color(0xFF383E4B) : const Color(0xFF22252C),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: awbActive ? Colors.white38 : Colors.white12,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'AWB',
                        style: TextStyle(
                          color: awbActive ? Colors.white : GcsColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: onToggleDisp,
                    child: Container(
                      decoration: BoxDecoration(
                        color: dispActive ? const Color(0xFF383E4B) : const Color(0xFF22252C),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: dispActive ? Colors.white38 : Colors.white12,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'DISP',
                        style: TextStyle(
                          color: dispActive ? Colors.white : GcsColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bottom: 2x Circular 4-Way D-Pad with Center Disc Button
          SizedBox(
            width: dpadSize,
            height: dpadSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer D-Pad circular body (flat matte dark, no extra shading)
                Container(
                  width: dpadSize,
                  height: dpadSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22262E),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF333842), width: 1.5),
                  ),
                ),

                // Up arrow (2x size: 26px icon)
                Positioned(
                  top: 3,
                  left: 24,
                  right: 24,
                  height: 32,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onDirection?.call('UP'),
                    child: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                // Down arrow (2x size: 26px icon)
                Positioned(
                  bottom: 3,
                  left: 24,
                  right: 24,
                  height: 32,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onDirection?.call('DOWN'),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                // Left arrow (2x size: 26px icon)
                Positioned(
                  left: 3,
                  top: 24,
                  bottom: 24,
                  width: 32,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onDirection?.call('LEFT'),
                    child: const Icon(
                      Icons.keyboard_arrow_left,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                // Right arrow (2x size: 26px icon)
                Positioned(
                  right: 3,
                  top: 24,
                  bottom: 24,
                  width: 32,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onDirection?.call('RIGHT'),
                    child: const Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                // Center circular button (2x size: 38px)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onCenterTap,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF333842), width: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
