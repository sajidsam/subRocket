import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

class GeofenceEditorDialog extends StatefulWidget {
  const GeofenceEditorDialog({super.key});

  @override
  State<GeofenceEditorDialog> createState() => _GeofenceEditorDialogState();
}

class _GeofenceEditorDialogState extends State<GeofenceEditorDialog> {
  late double _maxAlt;
  late double _maxRadius;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final vehicle = context.read<VehicleState>();
    _maxAlt = vehicle.geofenceMaxAlt;
    _maxRadius = vehicle.geofenceMaxRadius;
    _enabled = vehicle.geofenceEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: GcsColors.surfaceDark,
      title: const Row(
        children: [
          Icon(Icons.shield, color: GcsColors.cyanAccent),
          SizedBox(width: 8),
          Text('GEOFENCE & SAFETY LIMITS', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ENABLE GEOFENCE', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                Switch(
                  value: _enabled,
                  activeThumbColor: GcsColors.cyanAccent,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text('MAXIMUM ALTITUDE (AGL): ${_maxAlt.toInt()} m', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Slider(
              value: _maxAlt,
              min: 20.0,
              max: 500.0,
              divisions: 24,
              activeColor: GcsColors.cyanAccent,
              onChanged: _enabled ? (v) => setState(() => _maxAlt = v) : null,
            ),
            const SizedBox(height: 12),

            Text('MAXIMUM RADIUS FROM HOME: ${_maxRadius.toInt()} m', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Slider(
              value: _maxRadius,
              min: 50.0,
              max: 3000.0,
              divisions: 59,
              activeColor: GcsColors.techAmber,
              onChanged: _enabled ? (v) => setState(() => _maxRadius = v) : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: GcsColors.greenActive, foregroundColor: Colors.black),
          onPressed: () {
            final vehicle = context.read<VehicleState>();
            vehicle.updateGeofence(
              enabled: _enabled,
              maxAlt: _maxAlt,
              maxRadius: _maxRadius,
            );
            Navigator.pop(context);
          },
          child: const Text('APPLY LIMITS'),
        ),
      ],
    );
  }
}
