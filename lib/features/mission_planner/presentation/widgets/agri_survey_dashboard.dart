import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import 'agri_theme_constants.dart';

class AgriSurveyDashboard extends StatefulWidget {
  final int routeNumber;
  final double totalDistanceMeters;
  final int waypointCount;
  final double calculatedAreaHa;
  final bool showAltitudeChart;
  final VoidCallback onToggleAltitudeChart;
  final VoidCallback onOpenGeofence;
  final VoidCallback onResetProgress;
  final VoidCallback onToggleWaypointsView;
  final VoidCallback onSaveAsDefault;
  final VoidCallback onStartMission;
  final VoidCallback onPauseMission;

  const AgriSurveyDashboard({
    super.key,
    this.routeNumber = 17,
    required this.totalDistanceMeters,
    required this.waypointCount,
    required this.calculatedAreaHa,
    required this.showAltitudeChart,
    required this.onToggleAltitudeChart,
    required this.onOpenGeofence,
    required this.onResetProgress,
    required this.onToggleWaypointsView,
    required this.onSaveAsDefault,
    required this.onStartMission,
    required this.onPauseMission,
  });

  @override
  State<AgriSurveyDashboard> createState() => _AgriSurveyDashboardState();
}

class _AgriSurveyDashboardState extends State<AgriSurveyDashboard> {
  String _selectedPayload = 'RGB 4K';
  String _selectedAltRef = 'AGL';
  double _resolution = 2.5;
  double _latOverlap = 70;
  double _longOverlap = 65;
  bool _perpendicularLines = false;
  bool _reverseFlight = false;

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '--';
    final int min = seconds ~/ 60;
    final int sec = (seconds % 60).toInt();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();

    // Estimated speed in m/s (default 10 m/s or vehicle groundspeed)
    final double speed = vehicle.groundspeed > 1.0 ? vehicle.groundspeed : 10.0;
    final double estSeconds = widget.totalDistanceMeters > 0 ? (widget.totalDistanceMeters / speed) : 0;
    final int estPhotos = widget.totalDistanceMeters > 0 ? (widget.totalDistanceMeters / 12.0).ceil() : 0;
    const double photoInterval = 12.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AgriColors.background,
        border: Border(
          bottom: BorderSide(color: AgriColors.border, width: 1.0),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Left Telemetry & Quick Action Card
            _buildLeftRouteCard(vehicle),

            const SizedBox(width: 8),

            // 2. Middle Box 1: Payload & Resolution Config
            Expanded(
              flex: 12,
              child: _buildPayloadConfigCard(),
            ),

            const SizedBox(width: 8),

            // 3. Middle Box 2: Mission Coverage & Triggers
            Expanded(
              flex: 11,
              child: _buildMissionCoverageCard(estPhotos, photoInterval),
            ),

            const SizedBox(width: 8),

            // 4. Middle Box 3: Flight Metrics & Waypoints
            Expanded(
              flex: 11,
              child: _buildFlightMetricsCard(estSeconds),
            ),

            const SizedBox(width: 8),

            // 5. Right Toggle Switches and Action Buttons
            _buildRightActionControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftRouteCard(VehicleState vehicle) {
    final int capacityMah = 5000;
    final int currentMah = (capacityMah * (vehicle.batteryRemaining / 100)).toInt();

    return Container(
      width: 255,
      padding: const EdgeInsets.all(10),
      decoration: AgriDecorations.cardBox(
        color: AgriColors.cardBackground,
        radius: 8,
        borderColor: AgriColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Route Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AgriColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AgriColors.orangePrimary.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.route_outlined, color: AgriColors.orangePrimary, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission Plan #${widget.routeNumber}',
                      style: const TextStyle(
                        color: AgriColors.orangePrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Universal UAV Navigation',
                      style: TextStyle(
                        color: AgriColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Mini telemetry stats
          Row(
            children: [
              const Icon(Icons.speed, size: 12, color: AgriColors.textSecondary),
              const SizedBox(width: 3),
              Text(
                '${vehicle.groundspeed.toStringAsFixed(1)} m/s',
                style: const TextStyle(color: AgriColors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
              ),
              const Spacer(),
              Text(
                widget.calculatedAreaHa > 0
                    ? '${widget.calculatedAreaHa.toStringAsFixed(1)} ha'
                    : '0.0 ha',
                style: const TextStyle(color: AgriColors.textSecondary, fontSize: 10),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AgriColors.borderSubtle,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  vehicle.isArmed ? 'ARMED' : 'READY',
                  style: TextStyle(
                    color: vehicle.isArmed ? AgriColors.greenActive : AgriColors.yellowAmber,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Battery bar readout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AgriColors.inputBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AgriColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.battery_charging_full, color: AgriColors.orangePrimary, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$currentMah / $capacityMah mAh',
                    style: const TextStyle(
                      color: AgriColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${vehicle.batteryVoltage.toStringAsFixed(1)} V',
                  style: const TextStyle(
                    color: AgriColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${vehicle.batteryRemaining}%',
                  style: TextStyle(
                    color: vehicle.batteryRemaining > 30 ? AgriColors.greenActive : AgriColors.redAlert,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Quick Action Icons Grid (Altitude Chart, Geofence, Pause, Play)
          Row(
            children: [
              _buildMiniActionButton(
                icon: Icons.bar_chart_rounded,
                tooltip: 'Altitude Profile',
                isActive: widget.showAltitudeChart,
                onTap: widget.onToggleAltitudeChart,
              ),
              const SizedBox(width: 6),
              _buildMiniActionButton(
                icon: Icons.shield_outlined,
                tooltip: 'Geofence Settings',
                isActive: false,
                onTap: widget.onOpenGeofence,
              ),
              const SizedBox(width: 6),
              _buildMiniActionButton(
                icon: Icons.pause_rounded,
                tooltip: 'Pause Mission (Loiter)',
                isActive: false,
                onTap: widget.onPauseMission,
              ),
              const SizedBox(width: 6),
              _buildMiniActionButton(
                icon: Icons.play_arrow_rounded,
                tooltip: 'Start Mission (Auto)',
                isActive: true,
                activeColor: AgriColors.orangePrimary,
                onTap: widget.onStartMission,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    Color activeColor = AgriColors.orangePrimary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? activeColor.withValues(alpha: 0.15) : AgriColors.cardElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? activeColor : AgriColors.borderLight,
                width: 1.0,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : AgriColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // Middle Box 1: Payload & Resolution Config Card
  Widget _buildPayloadConfigCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AgriDecorations.cardBox(
        color: AgriColors.cardBackground,
        radius: 8,
        borderColor: AgriColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildParamRow(
            label: 'Payload',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildChoiceChip(
                  label: 'RGB 4K',
                  isSelected: _selectedPayload == 'RGB 4K',
                  onSelect: () => setState(() => _selectedPayload = 'RGB 4K'),
                ),
                const SizedBox(width: 3),
                _buildChoiceChip(
                  label: 'Thermal',
                  isSelected: _selectedPayload == 'Thermal',
                  onSelect: () => setState(() => _selectedPayload = 'Thermal'),
                ),
                const SizedBox(width: 3),
                _buildChoiceChip(
                  label: 'LiDAR',
                  isSelected: _selectedPayload == 'LiDAR',
                  onSelect: () => setState(() => _selectedPayload = 'LiDAR'),
                ),
              ],
            ),
          ),
          _buildParamRow(
            label: 'Alt Reference',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildChoiceChip(
                  label: 'AGL',
                  isSelected: _selectedAltRef == 'AGL',
                  onSelect: () => setState(() => _selectedAltRef = 'AGL'),
                ),
                const SizedBox(width: 3),
                _buildChoiceChip(
                  label: 'AMSL',
                  isSelected: _selectedAltRef == 'AMSL',
                  onSelect: () => setState(() => _selectedAltRef = 'AMSL'),
                ),
                const SizedBox(width: 3),
                _buildChoiceChip(
                  label: 'Terrain',
                  isSelected: _selectedAltRef == 'Terrain',
                  onSelect: () => setState(() => _selectedAltRef = 'Terrain'),
                ),
              ],
            ),
          ),
          _buildSliderParamRow(
            label: 'Resolution cm/px',
            value: _resolution,
            min: 0,
            max: 20,
            onChanged: (v) => setState(() => _resolution = v),
          ),
          _buildSliderParamRow(
            label: 'Side overlap %',
            value: _latOverlap,
            min: 0,
            max: 100,
            onChanged: (v) => setState(() => _latOverlap = v),
          ),
        ],
      ),
    );
  }

  // Middle Box 2: Mission Coverage & Triggers Card
  Widget _buildMissionCoverageCard(int estPhotos, double photoInterval) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AgriDecorations.cardBox(
        color: AgriColors.cardBackground,
        radius: 8,
        borderColor: AgriColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildParamRow(
            label: 'Mission Area',
            valueWidget: Text(
              widget.calculatedAreaHa > 0 ? '${widget.calculatedAreaHa.toStringAsFixed(2)} ha' : '-- ha',
              style: const TextStyle(color: AgriColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          _buildParamRow(
            label: 'Target Altitude',
            valueWidget: Text(
              widget.waypointCount > 0 ? '20.0 m / $_selectedAltRef' : '-- m / $_selectedAltRef',
              style: const TextStyle(color: AgriColors.textWhite, fontSize: 11),
            ),
          ),
          _buildParamRow(
            label: 'Trigger Count',
            valueWidget: Text(estPhotos > 0 ? '$estPhotos' : '--', style: const TextStyle(color: AgriColors.textWhite, fontSize: 11)),
          ),
          _buildParamRow(
            label: 'Trigger Interval',
            valueWidget: Text(widget.totalDistanceMeters > 0 ? '${photoInterval.toStringAsFixed(0)} m' : '-- m', style: const TextStyle(color: AgriColors.textWhite, fontSize: 11)),
          ),
          _buildSliderParamRow(
            label: 'Front overlap %',
            value: _longOverlap,
            min: 0,
            max: 100,
            onChanged: (v) => setState(() => _longOverlap = v),
          ),
        ],
      ),
    );
  }

  // Middle Box 3: Flight Metrics & Waypoints Card
  Widget _buildFlightMetricsCard(double estSeconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AgriDecorations.cardBox(
        color: AgriColors.cardBackground,
        radius: 8,
        borderColor: AgriColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildParamRow(
            label: 'Turn Mode',
            valueWidget: const Text('Coordinated', style: TextStyle(color: AgriColors.textWhite, fontSize: 11)),
          ),
          _buildParamRow(
            label: 'Est. Flight Time',
            valueWidget: Text(_formatDuration(estSeconds), style: const TextStyle(color: AgriColors.textWhite, fontSize: 11, fontFamily: 'monospace')),
          ),
          _buildParamRow(
            label: 'Est. Distance',
            valueWidget: Text(
              widget.totalDistanceMeters > 0
                  ? (widget.totalDistanceMeters >= 1000
                      ? '${(widget.totalDistanceMeters / 1000).toStringAsFixed(2)} km'
                      : '${widget.totalDistanceMeters.toStringAsFixed(0)} m')
                  : '--',
              style: const TextStyle(color: AgriColors.textWhite, fontSize: 11),
            ),
          ),
          _buildParamRow(
            label: 'Track Spacing',
            valueWidget: const Text('15.0 m', style: TextStyle(color: AgriColors.textWhite, fontSize: 11)),
          ),
          _buildParamRow(
            label: 'Waypoints',
            valueWidget: Text('${widget.waypointCount}', style: const TextStyle(color: AgriColors.orangePrimary, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow({required String label, required Widget valueWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AgriColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        valueWidget,
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AgriColors.orangePrimary : AgriColors.cardElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AgriColors.orangePrimary : AgriColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AgriColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSliderParamRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: AgriColors.textSecondary, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AgriColors.inputBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AgriColors.borderSubtle),
            ),
            child: Row(
              children: [
                // Active indicator pill
                Container(
                  width: 4,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AgriColors.orangePrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: AgriColors.orangePrimary,
                      inactiveTrackColor: AgriColors.borderLight,
                      thumbColor: AgriColors.orangePrimary,
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      onChanged: onChanged,
                    ),
                  ),
                ),
                Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: AgriColors.textWhite, fontSize: 9, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightActionControls() {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(8),
      decoration: AgriDecorations.cardBox(
        color: AgriColors.cardBackground,
        radius: 8,
        borderColor: AgriColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Crosshatch grid toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Crosshatch grid', style: TextStyle(color: AgriColors.textSecondary, fontSize: 9)),
              ),
              SizedBox(
                width: 34,
                height: 20,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch(
                    value: _perpendicularLines,
                    activeThumbColor: AgriColors.orangePrimary,
                    activeTrackColor: AgriColors.orangePrimary.withValues(alpha: 0.5),
                    inactiveTrackColor: AgriColors.cardElevated,
                    onChanged: (v) => setState(() => _perpendicularLines = v),
                  ),
                ),
              ),
            ],
          ),

          // Reverse route toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Reverse route', style: TextStyle(color: AgriColors.textSecondary, fontSize: 9)),
              ),
              SizedBox(
                width: 34,
                height: 20,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch(
                    value: _reverseFlight,
                    activeThumbColor: AgriColors.orangePrimary,
                    activeTrackColor: AgriColors.orangePrimary.withValues(alpha: 0.5),
                    inactiveTrackColor: AgriColors.cardElevated,
                    onChanged: (v) => setState(() => _reverseFlight = v),
                  ),
                ),
              ),
            ],
          ),

          // Reset plan outline button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AgriColors.textPrimary,
              side: const BorderSide(color: AgriColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: widget.onResetProgress,
            child: const Text('Reset plan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),

          // Show altitude profile outline button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AgriColors.textPrimary,
              side: const BorderSide(color: AgriColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: widget.onToggleWaypointsView,
            child: const Text('Altitude Profile', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),

          // Sync mission Solid Orange Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AgriColors.orangePrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 2,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: widget.onSaveAsDefault,
            child: const Text(
              'Sync to Vehicle',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
