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
      backgroundColor: GcsColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GcsColors.border, width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: GcsColors.goldAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GcsColors.goldAccent.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.shield, color: GcsColors.goldAccent, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'GEOFENCE & SAFETY LIMITS',
            style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: GcsColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GcsColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ENABLE GEOFENCE', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  Switch(
                    value: _enabled,
                    activeThumbColor: GcsColors.cyanAccent,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MAXIMUM ALTITUDE (AGL)', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: GcsColors.textSecondary)),
                Text('${_maxAlt.toInt()} m', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: GcsColors.cyanAccent)),
              ],
            ),
            Slider(
              value: _maxAlt,
              min: 20.0,
              max: 500.0,
              divisions: 24,
              activeColor: GcsColors.cyanAccent,
              onChanged: _enabled ? (v) => setState(() => _maxAlt = v) : null,
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MAXIMUM RADIUS FROM HOME', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: GcsColors.textSecondary)),
                Text('${_maxRadius.toInt()} m', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: GcsColors.goldAccent)),
              ],
            ),
            Slider(
              value: _maxRadius,
              min: 50.0,
              max: 3000.0,
              divisions: 59,
              activeColor: GcsColors.goldAccent,
              onChanged: _enabled ? (v) => setState(() => _maxRadius = v) : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: GcsColors.textSecondary, fontFamily: 'monospace')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: GcsColors.greenActive,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () {
            final vehicle = context.read<VehicleState>();
            vehicle.updateGeofence(
              enabled: _enabled,
              maxAlt: _maxAlt,
              maxRadius: _maxRadius,
            );
            Navigator.pop(context);
          },
          child: const Text('APPLY LIMITS', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ),
      ],
    );
  }
}
