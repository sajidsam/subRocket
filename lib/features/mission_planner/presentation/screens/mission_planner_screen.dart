import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/flight_mode.dart';
import '../../../../core/models/mission_command.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/presentation/widgets/gcs_drawer.dart';
import '../../../../core/services/mavlink_service.dart';
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

  @override
  void initState() {
    super.initState();
    final vehicle = context.read<VehicleState>();
    if (vehicle.missionItems.isNotEmpty) {
      _localPlan.addAll(vehicle.missionItems);
    } else {
      // Initialize with default 3-point search pattern around Dhaka / Home
      final home = vehicle.homeLocation;
      _localPlan.addAll([
        MissionItem(seq: 1, command: MissionCommandType.takeoff, position: home, altitude: 30.0, speed: 10.0),
        MissionItem(seq: 2, command: MissionCommandType.waypoint, position: LatLng(home.latitude + 0.003, home.longitude + 0.002), altitude: 60.0, speed: 15.0),
        MissionItem(seq: 3, command: MissionCommandType.waypoint, position: LatLng(home.latitude + 0.003, home.longitude - 0.002), altitude: 60.0, speed: 15.0),
        MissionItem(seq: 4, command: MissionCommandType.rtl, position: home, altitude: 50.0),
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

  void _addWaypoint(LatLng pos) {
    setState(() {
      final nextSeq = _localPlan.length + 1;
      _localPlan.add(
        MissionItem(
          seq: nextSeq,
          command: MissionCommandType.waypoint,
          position: pos,
          altitude: 50.0,
          speed: 15.0,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final mavlink = context.watch<MavlinkService>();
    final totalDistance = _calculateTotalDistance();

    return Scaffold(
      drawer: const GcsDrawer(),
      appBar: AppBar(
        title: const Text('ARDUPILOT AUTONOMOUS MISSION PLANNER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield),
            tooltip: 'Geofence Settings',
            onPressed: () => showDialog(context: context, builder: (_) => const GeofenceEditorDialog()),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download from FC',
            onPressed: () {
              setState(() {
                _localPlan.clear();
                _localPlan.addAll(vehicle.missionItems);
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waypoints downloaded from Flight Controller.')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Mission',
            onPressed: () => setState(() => _localPlan.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Interactive Map Layer
                Expanded(
                  flex: 3,
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
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.rocketcontroller.gcs',
                          ),

                          // Mission Waypoint Path Line
                          PolylineLayer(
                            polylines: [
                              if (_localPlan.isNotEmpty)
                                Polyline(
                                  points: _localPlan.map((w) => w.position).toList(),
                                  color: GcsColors.cyanAccent,
                                  strokeWidth: 4.0,
                                ),
                            ],
                          ),

                          // Waypoint Markers
                          MarkerLayer(
                            markers: [
                              // Home Marker
                              Marker(
                                point: vehicle.homeLocation,
                                width: 36,
                                height: 36,
                                child: Container(
                                  decoration: const BoxDecoration(color: GcsColors.techAmber, shape: BoxShape.circle),
                                  child: const Icon(Icons.home, color: Colors.black, size: 22),
                                ),
                              ),

                              // Waypoint number pins
                              ..._localPlan.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final wp = entry.value;
                                return Marker(
                                  point: wp.position,
                                  width: 32,
                                  height: 32,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: wp.command == MissionCommandType.takeoff
                                          ? GcsColors.greenActive
                                          : (wp.command == MissionCommandType.rtl ? GcsColors.warningOrange : GcsColors.cyanAccent),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // Active Vehicle Marker
                              if (vehicle.currentLocation != null)
                                Marker(
                                  point: vehicle.currentLocation!,
                                  width: 44,
                                  height: 44,
                                  child: Transform.rotate(
                                    angle: vehicle.yaw * (pi / 180.0),
                                    child: const Icon(Icons.navigation, color: GcsColors.alertRed, size: 38),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Map Tap Instruction Banner
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: GcsColors.border),
                          ),
                          child: const Text('TAP ON MAP TO ADD WAYPOINTS', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Waypoint Sequence Editor Table
                Container(
                  width: 380,
                  color: GcsColors.surfaceDark,
                  child: Column(
                    children: [
                      // Header Stats
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: GcsColors.surfaceCard,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'WAYPOINTS: ${_localPlan.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.white),
                            ),
                            Text(
                              'DIST: ${totalDistance.toStringAsFixed(0)} m',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: GcsColors.cyanAccent),
                            ),
                          ],
                        ),
                      ),

                      // Waypoint List
                      Expanded(
                        child: ListView.builder(
                          itemCount: _localPlan.length,
                          itemBuilder: (context, index) {
                            final wp = _localPlan[index];
                            return _buildWaypointEditorCard(index, wp);
                          },
                        ),
                      ),

                      // Bottom Sync & Start Actions
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: GcsColors.surfaceCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GcsColors.cyanAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.all(14),
                              ),
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('SYNC MISSION TO VEHICLE'),
                              onPressed: () {
                                mavlink.uploadMission(_localPlan);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mission uploaded to Flight Controller!')),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GcsColors.greenActive,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.all(14),
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('START AUTONOMOUS MISSION'),
                              onPressed: () {
                                mavlink.uploadMission(_localPlan);
                                if (!vehicle.isArmed) {
                                  mavlink.armDisarm(true);
                                }
                                mavlink.setFlightMode(FlightMode.auto);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Autonomous Mission Executing in AUTO Mode!')),
                                );
                              },
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

          // Bottom Altitude Profile Elevation Graph
          MissionAltitudeChart(waypoints: _localPlan),
        ],
      ),
    );
  }

  Widget _buildWaypointEditorCard(int index, MissionItem wp) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GcsColors.surfaceDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GcsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: GcsColors.cyanAccent,
                child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<MissionCommandType>(
                  value: wp.command,
                  isDense: true,
                  dropdownColor: GcsColors.surfaceCard,
                  underline: const SizedBox(),
                  items: MissionCommandType.values.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    );
                  }).toList(),
                  onChanged: (newCmd) {
                    if (newCmd != null) {
                      setState(() {
                        _localPlan[index] = wp.copyWith(command: newCmd);
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: GcsColors.alertRed),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _localPlan.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALT (m)', style: TextStyle(fontSize: 9, color: GcsColors.textSecondary, fontFamily: 'monospace')),
                    SizedBox(
                      height: 32,
                      child: TextFormField(
                        initialValue: wp.altitude.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) _localPlan[index] = wp.copyWith(altitude: parsed);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SPEED (m/s)', style: TextStyle(fontSize: 9, color: GcsColors.textSecondary, fontFamily: 'monospace')),
                    SizedBox(
                      height: 32,
                      child: TextFormField(
                        initialValue: wp.speed.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) _localPlan[index] = wp.copyWith(speed: parsed);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
