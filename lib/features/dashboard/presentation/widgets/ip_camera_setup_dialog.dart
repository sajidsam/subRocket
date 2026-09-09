import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

class IpCameraSetupDialog extends StatefulWidget {
  const IpCameraSetupDialog({super.key});

  @override
  State<IpCameraSetupDialog> createState() => _IpCameraSetupDialogState();
}

class _IpCameraSetupDialogState extends State<IpCameraSetupDialog> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final vehicle = context.read<VehicleState>();
    _urlController = TextEditingController(text: vehicle.cameraStreamUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _applyQuickPreset(String preset) {
    setState(() {
      _urlController.text = preset;
      _urlController.selection = TextSelection.fromPosition(TextPosition(offset: preset.length));
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleState>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GcsColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GcsColors.aviationBlue.withValues(alpha: 0.8), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: GcsColors.aviationBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GcsColors.cyanAccent),
                  ),
                  child: const Icon(Icons.videocam_outlined, color: GcsColors.cyanAccent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'IP CAMERA STREAM LINK SETUP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Live Video Feed URL (MJPEG / HTTP Stream / Snapshot)',
                        style: TextStyle(fontSize: 10, color: GcsColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: GcsColors.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: GcsColors.border),
            const SizedBox(height: 12),

            // Stream URL Input Field
            const Text(
              'CAMERA STREAM / SNAPSHOT URL',
              style: TextStyle(
                color: GcsColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'http://10.10.60.95:8080/video',
                hintStyle: const TextStyle(color: GcsColors.textMuted, fontSize: 12),
                fillColor: GcsColors.surfaceDark,
                filled: true,
                isDense: true,
                prefixIcon: const Icon(Icons.link, color: GcsColors.cyanAccent, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.cyanAccent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Presets Wrap
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Presets: ', style: TextStyle(color: GcsColors.textSecondary, fontSize: 10)),
                _buildPresetChip('IP Webcam (:8080/video)', 'http://10.10.60.95:8080/video'),
                _buildPresetChip('Snapshot (:8080/shot.jpg)', 'http://10.10.60.95:8080/shot.jpg'),
                _buildPresetChip('DroidCam (:4747/video)', 'http://10.10.60.95:4747/video'),
                _buildPresetChip('ESP32-CAM (:81/stream)', 'http://10.10.60.95:81/stream'),
              ],
            ),
            const SizedBox(height: 14),

            // Helper tip
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GcsColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GcsColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: GcsColors.goldAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To stream from your phone: Install "IP Webcam" on Android, open the app, scroll to bottom and tap "Start server". Enter the IP address shown on your phone screen above (e.g. http://192.168.0.x:8080/video).',
                      style: TextStyle(color: GcsColors.textSecondary, fontSize: 10, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Current Status Readout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: GcsColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('LINK STATUS', style: TextStyle(color: GcsColors.textSecondary, fontSize: 10, fontFamily: 'monospace')),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: vehicle.isCameraStreamConnected ? GcsColors.greenActive : GcsColors.warningOrange,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vehicle.isCameraStreamConnected ? 'ONLINE (${vehicle.cameraFps.toStringAsFixed(0)} FPS)' : 'CONNECTING / STANDBY',
                        style: TextStyle(
                          color: vehicle.isCameraStreamConnected ? GcsColors.greenActive : GcsColors.warningOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GcsColors.textSecondary,
                    side: const BorderSide(color: GcsColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CLOSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GcsColors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.videocam, size: 16),
                  label: const Text('CONNECT & APPLY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    vehicle.updateCameraStream(
                      url: _urlController.text.trim(),
                      useSimulated: false,
                      isConnected: false,
                      status: 'Connecting to IP Camera...',
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connecting to Camera Stream: ${_urlController.text.trim()}'),
                        backgroundColor: GcsColors.cardSurfaceLight,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url) {
    return InkWell(
      onTap: () => _applyQuickPreset(url),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: GcsColors.surfaceDark,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: GcsColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(color: GcsColors.cyanAccent, fontSize: 9, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
