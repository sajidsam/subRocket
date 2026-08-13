import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../../../core/models/flight_mode.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/presentation/widgets/emergency_panel.dart';
import '../../../../core/presentation/widgets/gcs_drawer.dart';
import '../../../../core/presentation/widgets/hud_pfd.dart';
import '../../../../core/presentation/widgets/telemetry_strip.dart';
import '../../../../core/services/flight_logger_service.dart';
import '../../../../core/services/mavlink_service.dart';
import '../../../calibration/presentation/screens/calibration_screen.dart';
import '../../../datalink/presentation/screens/connection_screen.dart';
import '../../../flight_logs/presentation/screens/flight_logs_screen.dart';
import '../../../mission_planner/presentation/screens/mission_planner_screen.dart';
import '../../../parameters/presentation/screens/parameter_editor_screen.dart';
import '../widgets/camera_viewfinder_card.dart';
import '../widgets/drone_status_card.dart';
import '../widgets/flight_camera_deck_card.dart';
import '../widgets/jca_sidebar.dart';
import '../widgets/live_graph_widget.dart';
import '../widgets/quick_control_pad.dart';
import '../widgets/tactical_compass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FocusNode _focusNode = FocusNode();
  final MapController _targetMapController = MapController();
  final MapController _primaryMapController = MapController();
  double _currentMapZoom = 15.0;
  int _selectedNavIndex = 0;
  bool _isMapPrimary = false;
  bool _isCameraDispActive = true;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final mavlink = context.watch<MavlinkService>();

    return Scaffold(
      backgroundColor: GcsColors.frameBackground,
      drawer: const GcsDrawer(),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            // Space: Immediate Emergency Motor Kill
            if (event.logicalKey == LogicalKeyboardKey.space) {
              mavlink.emergencyStop();
              return KeyEventResult.handled;
            }
            // W / Up: Increase Throttle
            if (event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.arrowUp) {
              mavlink.setThrottle((vehicle.throttlePercent + 5).clamp(0, 100).toDouble());
              return KeyEventResult.handled;
            }
            // S / Down: Decrease Throttle
            if (event.logicalKey == LogicalKeyboardKey.keyS || event.logicalKey == LogicalKeyboardKey.arrowDown) {
              mavlink.setThrottle((vehicle.throttlePercent - 5).clamp(0, 100).toDouble());
              return KeyEventResult.handled;
            }
            // A / Left: Roll Left
            if (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              mavlink.manualControl(pitch: 0, roll: -200, throttle: 500, yaw: 0);
              return KeyEventResult.handled;
            }
            // D / Right: Roll Right
            if (event.logicalKey == LogicalKeyboardKey.keyD || event.logicalKey == LogicalKeyboardKey.arrowRight) {
              mavlink.manualControl(pitch: 0, roll: 200, throttle: 500, yaw: 0);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;

              return Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 1440,
                    maxHeight: 920,
                  ),
                  margin: EdgeInsets.all(isWide ? 10.0 : 4.0),
                  padding: EdgeInsets.all(isWide ? 8.0 : 4.0),
                  decoration: BoxDecoration(
                    color: GcsColors.background,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: GcsColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 1. Fixed JCA Navigation Sidebar (Persistent Shell)
                      JcaSidebar(
                        selectedIndex: _selectedNavIndex,
                        onDestinationSelected: (index) {
                          setState(() => _selectedNavIndex = index);
                        },
                      ),

                      const SizedBox(width: 8),

                      // 2. Dynamic Outlet Area (Swaps based on Sidebar Selection)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildOutletContent(_selectedNavIndex, vehicle, mavlink),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOutletContent(int index, VehicleState vehicle, MavlinkService mavlink) {
    switch (index) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('cockpit_home_view'),
          child: _buildCockpitHomeView(),
        );

      case 1:
        return KeyedSubtree(
          key: const ValueKey('target_tracking_view'),
          child: _buildTargetTrackingView(vehicle, mavlink),
        );

      case 2:
        return const KeyedSubtree(
          key: ValueKey('flight_logs_view'),
          child: FlightLogsScreen(),
        );

      case 3:
        return KeyedSubtree(
          key: const ValueKey('exposure_graphs_view'),
          child: _buildExposureAndGraphsView(),
        );

      case 4:
        return const KeyedSubtree(
          key: ValueKey('parameter_editor_view'),
          child: ParameterEditorScreen(),
        );

      case 5:
        return KeyedSubtree(
          key: const ValueKey('system_alerts_view'),
          child: _buildSystemAlertsView(vehicle),
        );

      case 6:
        return const KeyedSubtree(
          key: ValueKey('mission_planner_view'),
          child: MissionPlannerScreen(),
        );

      case 7:
        return const KeyedSubtree(
          key: ValueKey('connection_view'),
          child: ConnectionScreen(),
        );

      default:
        return KeyedSubtree(
          key: const ValueKey('default_cockpit_view'),
          child: _buildCockpitHomeView(),
        );
    }
  }

  // View 0: Primary Cockpit Home Layout (Exact Reference Match)
  Widget _buildCockpitHomeView() {
    return Row(
      key: const ValueKey('cockpit_home_view'),
      children: [
        // Left Main Zone: Camera Viewfinder (Top) + Flight Deck (Bottom)
        Expanded(
          flex: 66,
          child: Column(
            children: [
              // Zone A: Camera Viewfinder Card / Swappable Main Screen
              Expanded(
                flex: 58,
                child: CameraViewfinderCard(
                  isSwapped: _isMapPrimary,
                  isDispActive: _isCameraDispActive,
                  mapController: _primaryMapController,
                  currentZoom: _currentMapZoom,
                  onToggleSwap: () => setState(() => _isMapPrimary = !_isMapPrimary),
                ),
              ),
              const SizedBox(height: 8),
              // Zone B: Flight & Camera Deck Card (with Mini Map / Mini Camera View)
              Expanded(
                flex: 42,
                child: FlightCameraDeckCard(
                  isSwapped: _isMapPrimary,
                  isDispActive: _isCameraDispActive,
                  onToggleDisp: () => setState(() => _isCameraDispActive = !_isCameraDispActive),
                  onToggleSwap: () => setState(() => _isMapPrimary = !_isMapPrimary),
                  onZoomChanged: (zoom) {
                    _currentMapZoom = zoom;
                    try {
                      _primaryMapController.move(_primaryMapController.camera.center, zoom);
                    } catch (_) {}
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Right Zone: Drone Status Card (Full Height)
        const Expanded(
          flex: 34,
          child: DroneStatusCard(),
        ),
      ],
    );
  }

  // View 1: Tactical Target Tracking & Primary Flight Display
  Widget _buildTargetTrackingView(VehicleState vehicle, MavlinkService mavlink) {
    return Container(
      key: const ValueKey('target_tracking_view'),
      decoration: BoxDecoration(
        color: GcsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GcsColors.border),
      ),
      child: Stack(
        children: [
          // Tactical Map
          FlutterMap(
            mapController: _targetMapController,
            options: MapOptions(
              initialCenter: vehicle.currentLocation ?? vehicle.homeLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rocketcontroller.gcs',
              ),
              Container(color: Colors.black.withValues(alpha: 0.7)),
              MarkerLayer(
                markers: [
                  Marker(
                    point: vehicle.currentLocation ?? vehicle.homeLocation,
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

          // PFD Overlay on Left
          Positioned(
            top: 16,
            left: 16,
            child: SizedBox(
              width: 320,
              child: Column(
                children: const [
                  HudPrimaryFlightDisplay(width: 320, height: 260),
                  SizedBox(height: 10),
                  TelemetryStrip(),
                ],
              ),
            ),
          ),

          // Action bar & joystick on bottom
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              children: const [
                EmergencyActionPanel(),
                SizedBox(width: 12),
                QuickControlPad(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // View 3: Exposure Controls & Live Graphs
  Widget _buildExposureAndGraphsView() {
    return Container(
      key: const ValueKey('exposure_graphs_view'),
      decoration: BoxDecoration(
        color: GcsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GcsColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.wb_sunny, color: GcsColors.goldAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'CAMERA EXPOSURE & LIVE TELEMETRY TELEMETRY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: GcsColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GcsColors.border),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LIVE ATTITUDE & ACCEL PLOTS', style: TextStyle(color: GcsColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Consumer<FlightLoggerService>(
                            builder: (context, logger, child) {
                              final frames = logger.activeSession?.frames ?? [];
                              final spots = frames.isEmpty
                                  ? List.generate(20, (i) => FlSpot(i.toDouble(), sin(i * 0.3) * 10 + 20))
                                  : frames.take(50).toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.altitude)).toList();

                              return LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white10, strokeWidth: 1),
                                    getDrawingVerticalLine: (v) => const FlLine(color: Colors.white10, strokeWidth: 1),
                                  ),
                                  titlesData: const FlTitlesData(
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: GcsColors.cyanAccent,
                                      barWidth: 2.5,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: GcsColors.cyanAccent.withValues(alpha: 0.15),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 320,
                  child: Container(
                    decoration: BoxDecoration(
                      color: GcsColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GcsColors.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SENSOR TUNING', style: TextStyle(color: GcsColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildSettingToggle('Auto Exposure Bracketing', true),
                        _buildSettingToggle('Electronic Image Stabilization', true),
                        _buildSettingToggle('Dynamic HDR Tone Mapping', true),
                        _buildSettingToggle('Thermal False Color Overlay', false),
                        _buildSettingToggle('Night Vision Infrared Strobe', false),
                      ],
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

  Widget _buildSettingToggle(String title, bool initial) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Switch(
                value: initial,
                activeColor: GcsColors.aviationBlue,
                onChanged: (val) => setState(() => initial = val),
              ),
            ],
          ),
        );
      },
    );
  }

  // View 5: System Alerts & Warning Messages Log
  Widget _buildSystemAlertsView(VehicleState vehicle) {
    return Container(
      key: const ValueKey('system_alerts_view'),
      decoration: BoxDecoration(
        color: GcsColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GcsColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active, color: GcsColors.goldAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'SYSTEM FLIGHT LOGS & EVENT ALERTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GcsColors.cardSurfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${vehicle.messageLog.length} EVENTS RECORDED',
                  style: const TextStyle(color: GcsColors.goldAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: vehicle.messageLog.isEmpty
                ? const Center(
                    child: Text(
                      'No system warnings or notifications recorded.',
                      style: TextStyle(color: GcsColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: vehicle.messageLog.length,
                    separatorBuilder: (_, __) => const Divider(color: GcsColors.borderSubtle, height: 1),
                    itemBuilder: (context, index) {
                      final msg = vehicle.messageLog[index];
                      Color badgeColor;
                      switch (msg.severity) {
                        case SeverityLevel.critical:
                          badgeColor = GcsColors.alertRed;
                          break;
                        case SeverityLevel.warning:
                          badgeColor = GcsColors.warningOrange;
                          break;
                        case SeverityLevel.notice:
                          badgeColor = GcsColors.goldAccent;
                          break;
                        case SeverityLevel.info:
                        default:
                          badgeColor = GcsColors.aviationBlue;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}:${msg.timestamp.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: GcsColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                msg.text,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
