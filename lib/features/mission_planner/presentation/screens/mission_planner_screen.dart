import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/flight_mode.dart';
import '../../../../core/models/mission_command.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/services/mavlink_service.dart';
import '../widgets/agri_map_toolbar.dart';
import '../widgets/agri_survey_dashboard.dart';
import '../widgets/agri_task_sidebar.dart';
import '../widgets/agri_theme_constants.dart';
import '../widgets/geofence_editor.dart';
import '../widgets/mission_altitude_chart.dart';

class MissionPlannerScreen extends StatefulWidget {
  const MissionPlannerScreen({super.key});

  @override
  State<MissionPlannerScreen> createState() => _MissionPlannerScreenState();
}

class _MissionPlannerScreenState extends State<MissionPlannerScreen> {
  final MapController _mapController = MapController();
  final List<MissionItem> _localPlan = [];

  bool _isSatelliteMap = true;
  bool _showAltitudeChart = false;

  @override
  void initState() {
    super.initState();
    final vehicle = context.read<VehicleState>();
    if (vehicle.missionItems.isNotEmpty) {
      _localPlan.addAll(vehicle.missionItems);
    } else {
      // Default survey grid pattern around Dhaka / Home
      final home = vehicle.homeLocation;
      _localPlan.addAll([
        MissionItem(seq: 1, command: MissionCommandType.takeoff, position: home, altitude: 20.0, speed: 10.0),
        MissionItem(seq: 2, command: MissionCommandType.waypoint, position: LatLng(home.latitude + 0.002, home.longitude - 0.002), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 3, command: MissionCommandType.waypoint, position: LatLng(home.latitude + 0.002, home.longitude + 0.002), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 4, command: MissionCommandType.waypoint, position: LatLng(home.latitude + 0.004, home.longitude + 0.002), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 5, command: MissionCommandType.waypoint, position: LatLng(home.latitude + 0.004, home.longitude - 0.002), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 6, command: MissionCommandType.rtl, position: home, altitude: 25.0),
      ]);
    }
  }

  double _calculateTotalDistance() {
    if (_localPlan.length < 2) return 0.0;
    double total = 0.0;
    const dist = Distance();
    for (int i = 0; i < _localPlan.length - 1; i++) {
      total += dist.as(LengthUnit.Meter, _localPlan[i].position, _localPlan[i + 1].position);
    }
    return total;
  }

  double _calculateEnclosedAreaHa() {
    if (_localPlan.length < 3) return 0.0;
    // Calculate bounding box area in hectares
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final wp in _localPlan) {
      if (wp.position.latitude < minLat) minLat = wp.position.latitude;
      if (wp.position.latitude > maxLat) maxLat = wp.position.latitude;
      if (wp.position.longitude < minLng) minLng = wp.position.longitude;
      if (wp.position.longitude > maxLng) maxLng = wp.position.longitude;
    }
    const dist = Distance();
    final widthM = dist.as(LengthUnit.Meter, LatLng(minLat, minLng), LatLng(minLat, maxLng));
    final heightM = dist.as(LengthUnit.Meter, LatLng(minLat, minLng), LatLng(maxLat, minLng));
    return (widthM * heightM) / 10000.0; // in Hectares
  }

  void _addWaypoint(LatLng pos) {
    setState(() {
      final nextSeq = _localPlan.length + 1;
      _localPlan.add(
        MissionItem(
          seq: nextSeq,
          command: MissionCommandType.waypoint,
          position: pos,
          altitude: 20.0,
          speed: 16.0,
        ),
      );
    });
  }

  void _generateAutoSurveyGrid() {
    final vehicle = context.read<VehicleState>();
    final center = vehicle.currentLocation ?? vehicle.homeLocation;
    const double stepLat = 0.0012;
    const double stepLng = 0.0035;

    setState(() {
      _localPlan.clear();
      _localPlan.addAll([
        MissionItem(seq: 1, command: MissionCommandType.takeoff, position: center, altitude: 15.0, speed: 10.0),
        MissionItem(seq: 2, command: MissionCommandType.waypoint, position: LatLng(center.latitude - stepLat, center.longitude - stepLng), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 3, command: MissionCommandType.waypoint, position: LatLng(center.latitude - stepLat, center.longitude + stepLng), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 4, command: MissionCommandType.waypoint, position: LatLng(center.latitude, center.longitude + stepLng), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 5, command: MissionCommandType.waypoint, position: LatLng(center.latitude, center.longitude - stepLng), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 6, command: MissionCommandType.waypoint, position: LatLng(center.latitude + stepLat, center.longitude - stepLng), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 7, command: MissionCommandType.waypoint, position: LatLng(center.latitude + stepLat, center.longitude + stepLng), altitude: 20.0, speed: 16.0),
        MissionItem(seq: 8, command: MissionCommandType.rtl, position: center, altitude: 25.0),
      ]);
    });

    _mapController.move(center, 16.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Autonomous survey grid pattern generated.')),
    );
  }

  void _centerOnHome() {
    final vehicle = context.read<VehicleState>();
    final target = vehicle.currentLocation ?? vehicle.homeLocation;
    _mapController.move(target, 16.0);
  }

  void _fitMissionBounds() {
    if (_localPlan.isEmpty) return;
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final wp in _localPlan) {
      if (wp.position.latitude < minLat) minLat = wp.position.latitude;
      if (wp.position.latitude > maxLat) maxLat = wp.position.latitude;
      if (wp.position.longitude < minLng) minLng = wp.position.longitude;
      if (wp.position.longitude > maxLng) maxLng = wp.position.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2.0, (minLng + maxLng) / 2.0);
    _mapController.move(center, 15.5);
  }

  void _uploadMissionToVehicle() {
    final mavlink = context.read<MavlinkService>();
    mavlink.uploadMission(_localPlan);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mission synchronized with Flight Controller!')),
    );
  }

  void _startAutonomousMission() {
    final vehicle = context.read<VehicleState>();
    final mavlink = context.read<MavlinkService>();
    mavlink.uploadMission(_localPlan);
    if (!vehicle.isArmed) {
      mavlink.armDisarm(true);
    }
    mavlink.setFlightMode(FlightMode.auto);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Autonomous Mission Executing in AUTO Mode!')),
    );
  }

  void _pauseMission() {
    final mavlink = context.read<MavlinkService>();
    mavlink.setFlightMode(FlightMode.loiter);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mission Paused. Vehicle in LOITER mode.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final totalDist = _calculateTotalDistance();
    final areaHa = _calculateEnclosedAreaHa();

    return Scaffold(
      backgroundColor: AgriColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Mission Parameters Dashboard (Battery, Sliders, Actions)
            AgriSurveyDashboard(
              routeNumber: 17,
              totalDistanceMeters: totalDist,
              waypointCount: _localPlan.length,
              calculatedAreaHa: areaHa,
              showAltitudeChart: _showAltitudeChart,
              onToggleAltitudeChart: () => setState(() => _showAltitudeChart = !_showAltitudeChart),
              onOpenGeofence: () => showDialog(context: context, builder: (_) => const GeofenceEditorDialog()),
              onResetProgress: () {
                setState(() => _localPlan.clear());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mission plan reset.')));
              },
              onToggleWaypointsView: () => setState(() => _showAltitudeChart = !_showAltitudeChart),
              onSaveAsDefault: _uploadMissionToVehicle,
              onStartMission: _startAutonomousMission,
              onPauseMission: _pauseMission,
            ),

            // 2. Main Center Split View: Map + Right Task/Route Sidebar
            Expanded(
              child: Row(
                children: [
                  // Left Interactive Map
                  Expanded(
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: vehicle.currentLocation ?? vehicle.homeLocation,
                            initialZoom: 15.0,
                            backgroundColor: Colors.black,
                            onTap: (tapPosition, point) => _addWaypoint(point),
                          ),
                          children: [
                            // Tile Provider (Satellite vs OpenStreetMap)
                            if (_isSatelliteMap)
                              TileLayer(
                                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                userAgentPackageName: 'com.rocketcontroller.gcs',
                                maxZoom: 19,
                              )
                            else
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.rocketcontroller.gcs',
                              ),

                            // Dark shading overlay for high contrast
                            Container(color: Colors.black.withValues(alpha: _isSatelliteMap ? 0.15 : 0.55)),

                            // Polyline Flight Path with Orange Glow
                            PolylineLayer(
                              polylines: [
                                if (_localPlan.isNotEmpty) ...[
                                  // Glow outline
                                  Polyline(
                                    points: _localPlan.map((w) => w.position).toList(),
                                    color: AgriColors.orangePrimary.withValues(alpha: 0.35),
                                    strokeWidth: 7.0,
                                  ),
                                  // Main Line
                                  Polyline(
                                    points: _localPlan.map((w) => w.position).toList(),
                                    color: AgriColors.orangePrimary,
                                    strokeWidth: 3.5,
                                  ),
                                ],
                              ],
                            ),

                            // Waypoint & Vehicle Markers
                            MarkerLayer(
                              markers: [
                                // Home Marker
                                Marker(
                                  point: vehicle.homeLocation,
                                  width: 36,
                                  height: 36,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AgriColors.yellowAmber,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black, width: 2),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black54, blurRadius: 6),
                                      ],
                                    ),
                                    child: const Icon(Icons.home_rounded, color: Colors.black, size: 20),
                                  ),
                                ),

                                // Waypoint Sequence Pin Markers
                                ..._localPlan.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final wp = entry.value;
                                  Color pinColor = AgriColors.orangePrimary;
                                  if (wp.command == MissionCommandType.takeoff) pinColor = AgriColors.greenActive;
                                  if (wp.command == MissionCommandType.rtl) pinColor = AgriColors.yellowAmber;

                                  return Marker(
                                    point: wp.position,
                                    width: 32,
                                    height: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: pinColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: pinColor.withValues(alpha: 0.6),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${idx + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                // Live Vehicle Marker with Yaw
                                if (vehicle.currentLocation != null)
                                  Marker(
                                    point: vehicle.currentLocation!,
                                    width: 44,
                                    height: 44,
                                    child: Transform.rotate(
                                      angle: vehicle.yaw * (pi / 180.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AgriColors.orangePrimary.withValues(alpha: 0.4),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.navigation_rounded,
                                          color: AgriColors.orangePrimary,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Map Top Instruction Badge
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AgriColors.headerBackground.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AgriColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.touch_app, color: AgriColors.orangePrimary, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'TAP MAP TO ADD WAYPOINTS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: AgriColors.textWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom-Right Floating Map Toolbar
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: AgriMapToolbar(
                            isSatellite: _isSatelliteMap,
                            onToggleMapType: () => setState(() => _isSatelliteMap = !_isSatelliteMap),
                            onCenterHome: _centerOnHome,
                            onGenerateSurveyGrid: _generateAutoSurveyGrid,
                            onToggleFullscreen: _fitMissionBounds,
                            onClearAll: () => setState(() => _localPlan.clear()),
                          ),
                        ),

                        // Collapsible Floating Altitude Chart
                        if (_showAltitudeChart)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 220,
                            child: MissionAltitudeChart(
                              waypoints: _localPlan,
                              onClose: () => setState(() => _showAltitudeChart = false),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Right Side Panel ("Route" & "Task / Config" tabs)
                  AgriTaskSidebar(
                    waypoints: _localPlan,
                    onWaypointsChanged: (updated) => setState(() {
                      _localPlan.clear();
                      _localPlan.addAll(updated);
                    }),
                    onAddTakeoff: () {
                      final home = vehicle.homeLocation;
                      setState(() {
                        _localPlan.insert(0, MissionItem(seq: 1, command: MissionCommandType.takeoff, position: home, altitude: 20.0, speed: 10.0));
                      });
                    },
                    onAddRtl: () {
                      final home = vehicle.homeLocation;
                      setState(() {
                        _localPlan.add(MissionItem(seq: _localPlan.length + 1, command: MissionCommandType.rtl, position: home, altitude: 25.0));
                      });
                    },
                    onClearMission: () => setState(() => _localPlan.clear()),
                    onDownloadFromFc: () {
                      setState(() {
                        _localPlan.clear();
                        _localPlan.addAll(vehicle.missionItems);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Waypoints downloaded from Flight Controller.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
