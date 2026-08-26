import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/presentation/widgets/gcs_drawer.dart';
import '../../../../core/services/mavlink_service.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _hostController = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portController = TextEditingController(text: '14550');
  late TextEditingController _cameraUrlController;

  ConnectionProtocol _selectedProtocol = ConnectionProtocol.sitl;
  int _activeLinkTab = 0; // 0 = MAVLink Datalink, 1 = IP Camera Video Stream

  @override
  void initState() {
    super.initState();
    final vehicle = context.read<VehicleState>();
    _cameraUrlController = TextEditingController(text: vehicle.cameraStreamUrl);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _cameraUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mavlink = context.watch<MavlinkService>();
    final vehicle = context.watch<VehicleState>();

    return Scaffold(
      backgroundColor: GcsColors.frameBackground,
      drawer: const GcsDrawer(),
      appBar: AppBar(
        backgroundColor: GcsColors.surfaceDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: GcsColors.aviationBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: GcsColors.cyanAccent.withValues(alpha: 0.6)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cable, color: GcsColors.cyanAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'DATALINK CONSOLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                      color: GcsColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MAVLINK TELEMETRY & CAMERA VIDEO STREAM',
              style: TextStyle(
                fontSize: 11,
                color: GcsColors.textSecondary,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: GcsColors.background,
        child: Row(
          children: [
            // Left: Link Configuration Panel
            Container(
              width: 370,
              margin: const EdgeInsets.fromLTRB(8, 8, 4, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GcsColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GcsColors.border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Segmented Switch: MAVLink Datalink vs Camera Link
                  Container(
                    height: 36,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: GcsColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GcsColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => setState(() => _activeLinkTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _activeLinkTab == 0 ? GcsColors.aviationBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.sensors, size: 14, color: _activeLinkTab == 0 ? Colors.white : GcsColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'MAVLink Telemetry',
                                      style: TextStyle(
                                        color: _activeLinkTab == 0 ? Colors.white : GcsColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => setState(() => _activeLinkTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _activeLinkTab == 1 ? GcsColors.cyanAccent : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam, size: 14, color: _activeLinkTab == 1 ? Colors.black : GcsColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'IP Camera Link',
                                      style: TextStyle(
                                        color: _activeLinkTab == 1 ? Colors.black : GcsColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Active Tab Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: _activeLinkTab == 0
                          ? _buildMavlinkConfigTab(mavlink, vehicle)
                          : _buildCameraLinkConfigTab(vehicle),
                    ),
                  ),
                ],
              ),
            ),

            // Right: MAVLink Terminal & Message Stream
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GcsColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GcsColors.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.terminal, color: GcsColors.cyanAccent, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'MAVLINK PACKET CONSOLE & SYSTEM MESSAGES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: GcsColors.surfaceDark,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LOGS: ${vehicle.messageLog.length}',
                            style: const TextStyle(fontSize: 10, color: GcsColors.textSecondary, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: GcsColors.border),
                    const SizedBox(height: 8),

                    // Log items
                    Expanded(
                      child: vehicle.messageLog.isEmpty
                          ? const Center(
                              child: Text(
                                'No MAVLink messages received yet.\nConnect link to begin streaming.',
                                style: TextStyle(color: GcsColors.textMuted, fontFamily: 'monospace', fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: vehicle.messageLog.length,
                              itemBuilder: (context, index) {
                                final msg = vehicle.messageLog[index];
                                Color sevColor = GcsColors.textPrimary;
                                if (msg.severity == SeverityLevel.warning) sevColor = GcsColors.warningOrange;
                                if (msg.severity == SeverityLevel.critical) sevColor = GcsColors.alertRed;
                                if (msg.severity == SeverityLevel.notice) sevColor = GcsColors.cyanAccent;

                                final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}:${msg.timestamp.second.toString().padLeft(2, '0')}';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '[$timeStr]',
                                        style: const TextStyle(
                                          color: GcsColors.textMuted,
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '[${msg.severity.name.toUpperCase()}]',
                                        style: TextStyle(
                                          color: sevColor,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          msg.text,
                                          style: TextStyle(
                                            color: sevColor,
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                          ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMavlinkConfigTab(MavlinkService mavlink, VehicleState vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Icon(Icons.settings_input_composite, color: GcsColors.goldAccent, size: 16),
            SizedBox(width: 6),
            Text(
              'TELEMETRY PROTOCOL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Protocol Selector
        DropdownButtonFormField<ConnectionProtocol>(
          initialValue: _selectedProtocol,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'PROTOCOL',
            labelStyle: const TextStyle(color: GcsColors.textSecondary, fontFamily: 'monospace', fontSize: 11),
            isDense: true,
            fillColor: GcsColors.surfaceDark,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.cyanAccent, width: 1.5)),
          ),
          dropdownColor: GcsColors.surfaceCard,
          items: ConnectionProtocol.values.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedProtocol = val);
          },
        ),
        const SizedBox(height: 12),

        if (_selectedProtocol != ConnectionProtocol.sitl) ...[
          TextField(
            controller: _hostController,
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              labelText: 'IP / HOST',
              labelStyle: const TextStyle(color: GcsColors.textSecondary, fontFamily: 'monospace', fontSize: 11),
              isDense: true,
              fillColor: GcsColors.surfaceDark,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'monospace', color: GcsColors.goldAccent, fontWeight: FontWeight.bold, fontSize: 12),
            decoration: InputDecoration(
              labelText: 'PORT',
              labelStyle: const TextStyle(color: GcsColors.textSecondary, fontFamily: 'monospace', fontSize: 11),
              isDense: true,
              fillColor: GcsColors.surfaceDark,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Connect / Disconnect Buttons
        if (!vehicle.isConnected)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcsColors.greenActive,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.link, size: 16),
            label: const Text('CONNECT MAVLINK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            onPressed: () {
              final portNum = int.tryParse(_portController.text) ?? 14550;
              mavlink.connect(
                _selectedProtocol,
                host: _hostController.text,
                portNum: portNum,
              );
            },
          )
        else
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcsColors.alertRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.link_off, size: 16),
            label: const Text('DISCONNECT MAVLINK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            onPressed: () => mavlink.disconnect(),
          ),

        const SizedBox(height: 16),
        const Divider(color: GcsColors.border),
        const SizedBox(height: 10),

        // Link Metrics Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GcsColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GcsColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.sensors, color: GcsColors.cyanAccent, size: 15),
                  SizedBox(width: 6),
                  Text('DATALINK HEALTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace')),
                ],
              ),
              const SizedBox(height: 8),
              _buildMetricRow('STATUS', vehicle.isConnected ? 'ONLINE' : 'OFFLINE', vehicle.isConnected ? GcsColors.greenActive : GcsColors.alertRed),
              _buildMetricRow('TRANSPORT', vehicle.connectionType, GcsColors.cyanAccent),
              _buildMetricRow('PACKETS RX', '${vehicle.packetCount}', Colors.white),
              _buildMetricRow('PACKET LOSS', '${vehicle.droppedPackets}', vehicle.droppedPackets > 0 ? GcsColors.warningOrange : GcsColors.textSecondary),
              _buildMetricRow('LATENCY', '${vehicle.pingMs} ms', GcsColors.goldAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraLinkConfigTab(VehicleState vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Icon(Icons.videocam, color: GcsColors.cyanAccent, size: 16),
            SizedBox(width: 6),
            Text(
              'CAMERA STREAM SOURCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Radio selector
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  vehicle.updateCameraStream(
                    url: _cameraUrlController.text.trim(),
                    useSimulated: true,
                    isConnected: false,
                    status: 'Procedural Simulation',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: vehicle.isUsingSimulatedCamera ? GcsColors.aviationBlue.withValues(alpha: 0.3) : GcsColors.surfaceDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: vehicle.isUsingSimulatedCamera ? GcsColors.cyanAccent : GcsColors.border,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'SIMULATED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () {
                  vehicle.updateCameraStream(
                    url: _cameraUrlController.text.trim(),
                    useSimulated: false,
                    isConnected: false,
                    status: 'Connecting to IP Camera...',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: !vehicle.isUsingSimulatedCamera ? GcsColors.cyanAccent.withValues(alpha: 0.25) : GcsColors.surfaceDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: !vehicle.isUsingSimulatedCamera ? GcsColors.cyanAccent : GcsColors.border,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'IP WEBCAM (LIVE)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Stream URL input
        TextField(
          controller: _cameraUrlController,
          style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            labelText: 'IP WEBCAM STREAM URL',
            labelStyle: const TextStyle(color: GcsColors.textSecondary, fontFamily: 'monospace', fontSize: 11),
            hintText: 'http://192.168.0.105:8080/video',
            isDense: true,
            fillColor: GcsColors.surfaceDark,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.cyanAccent, width: 1.5)),
          ),
        ),
        const SizedBox(height: 8),

        // Presets
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildPresetChip('IP Webcam (:8080)', 'http://192.168.0.105:8080/video'),
            _buildPresetChip('Snapshot (:8080)', 'http://192.168.0.105:8080/shot.jpg'),
            _buildPresetChip('DroidCam (:4747)', 'http://192.168.0.105:4747/video'),
          ],
        ),
        const SizedBox(height: 14),

        // Connect / Disconnect Camera Button
        if (vehicle.isUsingSimulatedCamera)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcsColors.greenActive,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.videocam, size: 16),
            label: const Text('CONNECT CAMERA FEED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            onPressed: () {
              vehicle.updateCameraStream(
                url: _cameraUrlController.text.trim(),
                useSimulated: false,
                isConnected: false,
                status: 'CONNECTING...',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connecting to IP Camera: ${_cameraUrlController.text.trim()}')),
              );
            },
          )
        else
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcsColors.alertRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.videocam_off, size: 16),
            label: const Text('DISCONNECT CAMERA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            onPressed: () {
              vehicle.updateCameraStream(
                url: _cameraUrlController.text.trim(),
                useSimulated: true,
                isConnected: false,
                status: 'Procedural Simulation',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera stream disconnected. Reverted to static view.')),
              );
            },
          ),

        const SizedBox(height: 16),
        const Divider(color: GcsColors.border),
        const SizedBox(height: 10),

        // Camera Feed Status Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GcsColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GcsColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.videocam_outlined, color: GcsColors.cyanAccent, size: 15),
                  SizedBox(width: 6),
                  Text('VIDEO LINK HEALTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace')),
                ],
              ),
              const SizedBox(height: 8),
              _buildMetricRow('FEED MODE', vehicle.isUsingSimulatedCamera ? 'SIMULATION' : 'IP WEBCAM', vehicle.isUsingSimulatedCamera ? GcsColors.goldAccent : GcsColors.cyanAccent),
              _buildMetricRow('LINK STATUS', vehicle.isUsingSimulatedCamera ? 'STANDBY' : (vehicle.isCameraStreamConnected ? 'ONLINE' : 'CONNECTING'), vehicle.isCameraStreamConnected ? GcsColors.greenActive : GcsColors.warningOrange),
              _buildMetricRow('FPS RATE', vehicle.cameraFps > 0 ? '${vehicle.cameraFps.toStringAsFixed(0)} FPS' : '--', GcsColors.cyanAccent),
              _buildMetricRow('TARGET URL', vehicle.cameraStreamUrl, Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, String url) {
    return InkWell(
      onTap: () {
        setState(() {
          _cameraUrlController.text = url;
        });
      },
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

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: GcsColors.textSecondary, fontFamily: 'monospace')),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 10, color: valueColor, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
