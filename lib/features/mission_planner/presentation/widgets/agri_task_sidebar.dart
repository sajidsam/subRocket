import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/flight_mode.dart';
import '../../../../core/models/mission_command.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/services/mavlink_service.dart';
import 'agri_theme_constants.dart';

class AgriTaskSidebar extends StatefulWidget {
  final List<MissionItem> waypoints;
  final ValueChanged<List<MissionItem>> onWaypointsChanged;
  final VoidCallback onAddTakeoff;
  final VoidCallback onAddRtl;
  final VoidCallback onClearMission;
  final VoidCallback onDownloadFromFc;

  const AgriTaskSidebar({
    super.key,
    required this.waypoints,
    required this.onWaypointsChanged,
    required this.onAddTakeoff,
    required this.onAddRtl,
    required this.onClearMission,
    required this.onDownloadFromFc,
  });

  @override
  State<AgriTaskSidebar> createState() => _AgriTaskSidebarState();
}

class _AgriTaskSidebarState extends State<AgriTaskSidebar> {
  int _selectedTabIndex = 0; // 0 = Route (Waypoints), 1 = Task (Flight Config)

  // Universal drone mission parameter state
  String _selectedTemplate = 'Waypoint Navigation';
  String _selectedTriggerMode = 'Distance Trigger';
  double _cruiseSpeed = 12.00; // m/s
  double _targetAltitude = 20.00; // m AGL
  double _rtlAltitude = 25.00; // m
  double _trackSpacing = 15.00; // m
  double _triggerInterval = 12.00; // m

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();
    final mavlink = context.watch<MavlinkService>();

    return Container(
      width: 320,
      decoration: AgriDecorations.cardBox(
        color: AgriColors.cardBackground,
        radius: 0,
        borderColor: AgriColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Tab Bar: Route | Task (Flight Config)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AgriColors.headerBackground,
              border: Border(bottom: BorderSide(color: AgriColors.border)),
            ),
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AgriColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentTab(
                      title: 'Route',
                      isSelected: _selectedTabIndex == 0,
                      onTap: () => setState(() => _selectedTabIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentTab(
                      title: 'Task / Config',
                      isSelected: _selectedTabIndex == 1,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: _selectedTabIndex == 1
                ? _buildTaskContent(vehicle, mavlink)
                : _buildRouteContent(vehicle, mavlink),
          ),

          // Bottom Action Execution Buttons
          _buildBottomActionButtons(vehicle, mavlink),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? AgriColors.orangePrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AgriColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskContent(VehicleState vehicle, MavlinkService mavlink) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mission Profile Section
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Mission Profile Pattern',
                  style: TextStyle(
                    color: AgriColors.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.help_outline_rounded, size: 13, color: AgriColors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),

          // Profile Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AgriColors.stepperBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AgriColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTemplate,
                isExpanded: true,
                dropdownColor: AgriColors.cardElevated,
                icon: const Icon(Icons.keyboard_arrow_down, color: AgriColors.textSecondary, size: 18),
                items: [
                  'Waypoint Navigation',
                  'Area Survey Grid',
                  'Perimeter / Border Patrol',
                  'Linear Corridor Scan',
                  'Orbit / ROI Inspection',
                  'Autonomous Delivery Route',
                ].map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AgriColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedTemplate = val;
                      if (val == 'Area Survey Grid') {
                        _cruiseSpeed = 10.0;
                        _targetAltitude = 25.0;
                      } else if (val == 'Linear Corridor Scan') {
                        _cruiseSpeed = 15.0;
                        _targetAltitude = 30.0;
                      } else if (val == 'Perimeter / Border Patrol') {
                        _cruiseSpeed = 14.0;
                        _targetAltitude = 35.0;
                      }
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Cruise Flight Speed (m/s) Stepper Box
          _buildNumericStepperBox(
            label: 'Cruise Speed (m/s)',
            value: _cruiseSpeed,
            step: 1.0,
            decimals: 1,
            onChanged: (v) => setState(() => _cruiseSpeed = v.clamp(1.0, 50.0)),
          ),
          const SizedBox(height: 14),

          // Target Altitude AGL (m) Stepper Box
          _buildNumericStepperBox(
            label: 'Default Altitude AGL (m)',
            value: _targetAltitude,
            step: 5.0,
            decimals: 1,
            onChanged: (v) {
              setState(() => _targetAltitude = v.clamp(2.0, 500.0));
              // Update waypoints altitude if requested
              final updated = widget.waypoints.map((wp) {
                if (wp.command == MissionCommandType.waypoint) {
                  return wp.copyWith(altitude: _targetAltitude);
                }
                return wp;
              }).toList();
              widget.onWaypointsChanged(updated);
            },
          ),
          const SizedBox(height: 14),

          // RTL / Failsafe Altitude (m) Stepper Box
          _buildNumericStepperBox(
            label: 'RTL / Failsafe Altitude (m)',
            value: _rtlAltitude,
            step: 5.0,
            decimals: 1,
            onChanged: (v) => setState(() => _rtlAltitude = v.clamp(5.0, 500.0)),
          ),
          const SizedBox(height: 14),

          // Track / Grid Spacing (m) Stepper Box
          _buildNumericStepperBox(
            label: 'Track / Grid Spacing (m)',
            value: _trackSpacing,
            step: 1.0,
            decimals: 1,
            onChanged: (v) => setState(() => _trackSpacing = v.clamp(2.0, 100.0)),
          ),
          const SizedBox(height: 14),

          // Payload Trigger Mode Section
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Camera / Payload Trigger',
                  style: TextStyle(
                    color: AgriColors.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.camera_alt_outlined, size: 13, color: AgriColors.orangePrimary),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AgriColors.stepperBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AgriColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTriggerMode,
                isExpanded: true,
                dropdownColor: AgriColors.cardElevated,
                icon: const Icon(Icons.keyboard_arrow_down, color: AgriColors.textSecondary, size: 18),
                items: [
                  'Distance Trigger',
                  'Time Interval',
                  'Waypoint Action Only',
                  'Disabled / Manual',
                ].map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AgriColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTriggerMode = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Trigger Interval Stepper
          _buildNumericStepperBox(
            label: _selectedTriggerMode == 'Time Interval' ? 'Trigger Interval (sec)' : 'Trigger Interval (m)',
            value: _triggerInterval,
            step: 1.0,
            decimals: 1,
            onChanged: (v) => setState(() => _triggerInterval = v.clamp(1.0, 200.0)),
          ),
          const SizedBox(height: 12),

          // Sub-stats (Gimbal & Failsafe)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Gimbal: -90°', style: TextStyle(color: AgriColors.textSecondary, fontSize: 10)),
                Text('Failsafe: RTL', style: TextStyle(color: AgriColors.yellowAmber, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericStepperBox({
    required String label,
    required double value,
    required double step,
    required int decimals,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AgriColors.textWhite,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: AgriColors.stepperBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AgriColors.border),
          ),
          child: Row(
            children: [
              // Decrement Button
              InkWell(
                onTap: () => onChanged(value - step),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                child: Container(
                  width: 38,
                  height: double.infinity,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AgriColors.border)),
                  ),
                  child: const Text(
                    '−',
                    style: TextStyle(color: AgriColors.textSecondary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Value Center Readout
              Expanded(
                child: Center(
                  child: Text(
                    value.toStringAsFixed(decimals),
                    style: const TextStyle(
                      color: AgriColors.orangeLight,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),

              // Increment Button
              InkWell(
                onTap: () => onChanged(value + step),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                child: Container(
                  width: 38,
                  height: double.infinity,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AgriColors.border)),
                  ),
                  child: const Text(
                    '+',
                    style: TextStyle(color: AgriColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteContent(VehicleState vehicle, MavlinkService mavlink) {
    if (widget.waypoints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_location_alt_outlined, color: AgriColors.textMuted, size: 36),
              const SizedBox(height: 8),
              const Text(
                'No waypoints placed',
                style: TextStyle(color: AgriColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap on map to place waypoints',
                style: TextStyle(color: AgriColors.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AgriColors.cardElevated,
                      foregroundColor: AgriColors.orangePrimary,
                      side: const BorderSide(color: AgriColors.orangePrimary),
                    ),
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text('Download from FC', style: TextStyle(fontSize: 11)),
                    onPressed: widget.onDownloadFromFc,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AgriColors.cardElevated,
                      foregroundColor: AgriColors.greenActive,
                      side: const BorderSide(color: AgriColors.greenActive),
                    ),
                    icon: const Icon(Icons.flight_takeoff, size: 14),
                    label: const Text('Takeoff', style: TextStyle(fontSize: 11)),
                    onPressed: widget.onAddTakeoff,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Quick Action Bar for Waypoints
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: AgriColors.headerBackground,
            border: Border(bottom: BorderSide(color: AgriColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.waypoints.length} WAYPOINTS',
                style: const TextStyle(
                  color: AgriColors.orangePrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderMiniIcon(
                    icon: Icons.flight_takeoff,
                    color: AgriColors.greenActive,
                    tooltip: 'Add Takeoff Point',
                    onTap: widget.onAddTakeoff,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderMiniIcon(
                    icon: Icons.flight_land,
                    color: AgriColors.yellowAmber,
                    tooltip: 'Add RTL Point',
                    onTap: widget.onAddRtl,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderMiniIcon(
                    icon: Icons.download,
                    color: AgriColors.cyanAccent,
                    tooltip: 'Download from FC',
                    onTap: widget.onDownloadFromFc,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderMiniIcon(
                    icon: Icons.delete_sweep_outlined,
                    color: AgriColors.redAlert,
                    tooltip: 'Clear All Waypoints',
                    onTap: widget.onClearMission,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Waypoint Cards List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            itemCount: widget.waypoints.length,
            itemBuilder: (context, index) {
              final wp = widget.waypoints[index];
              return _buildWaypointCard(index, wp);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderMiniIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  Widget _buildWaypointCard(int index, MissionItem wp) {
    Color badgeColor = AgriColors.orangePrimary;
    if (wp.command == MissionCommandType.takeoff) badgeColor = AgriColors.greenActive;
    if (wp.command == MissionCommandType.rtl) badgeColor = AgriColors.yellowAmber;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AgriColors.stepperBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AgriColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Index Badge
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Command Selector
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MissionCommandType>(
                    value: wp.command,
                    isDense: true,
                    dropdownColor: AgriColors.cardElevated,
                    items: MissionCommandType.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          c.name.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AgriColors.textWhite),
                        ),
                      );
                    }).toList(),
                    onChanged: (newCmd) {
                      if (newCmd != null) {
                        final updated = List<MissionItem>.from(widget.waypoints);
                        updated[index] = wp.copyWith(command: newCmd);
                        widget.onWaypointsChanged(updated);
                      }
                    },
                  ),
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AgriColors.redAlert),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final updated = List<MissionItem>.from(widget.waypoints);
                  updated.removeAt(index);
                  widget.onWaypointsChanged(updated);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Alt & Speed fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALT (m)', style: TextStyle(fontSize: 8, color: AgriColors.textSecondary)),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 28,
                      child: TextFormField(
                        initialValue: wp.altitude.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 11, color: AgriColors.orangeLight, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          isDense: true,
                          fillColor: AgriColors.inputBackground,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AgriColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AgriColors.border)),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            final updated = List<MissionItem>.from(widget.waypoints);
                            updated[index] = wp.copyWith(altitude: parsed);
                            widget.onWaypointsChanged(updated);
                          }
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
                    const Text('SPEED (m/s)', style: TextStyle(fontSize: 8, color: AgriColors.textSecondary)),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 28,
                      child: TextFormField(
                        initialValue: wp.speed.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 11, color: AgriColors.cyanAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          isDense: true,
                          fillColor: AgriColors.inputBackground,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AgriColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AgriColors.border)),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            final updated = List<MissionItem>.from(widget.waypoints);
                            updated[index] = wp.copyWith(speed: parsed);
                            widget.onWaypointsChanged(updated);
                          }
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

  Widget _buildBottomActionButtons(VehicleState vehicle, MavlinkService mavlink) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AgriColors.headerBackground,
        border: Border(top: BorderSide(color: AgriColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upload / Sync mission
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AgriColors.textPrimary,
              side: const BorderSide(color: AgriColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.cloud_upload_outlined, size: 15, color: AgriColors.orangeLight),
            label: const Text('SYNC MISSION TO VEHICLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            onPressed: () {
              mavlink.uploadMission(widget.waypoints);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mission uploaded to Flight Controller!')),
              );
            },
          ),
          const SizedBox(height: 8),

          // Start Autonomous Mission Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AgriColors.orangePrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 3,
            ),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('START AUTONOMOUS MISSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            onPressed: () {
              mavlink.uploadMission(widget.waypoints);
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
    );
  }
}
