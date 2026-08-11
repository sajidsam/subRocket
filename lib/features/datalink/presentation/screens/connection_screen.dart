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
  ConnectionProtocol _selectedProtocol = ConnectionProtocol.sitl;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mavlink = context.watch<MavlinkService>();
    final vehicle = context.watch<VehicleState>();

    return Scaffold(
      drawer: const GcsDrawer(),
      appBar: AppBar(
        title: const Text('DATALINK & MAVLINK CONSOLE'),
      ),
      body: Row(
        children: [
          // Left: Connection Settings
          Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: GcsColors.surfaceDark,
              border: Border(right: BorderSide(color: GcsColors.border, width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'LINK CONFIGURATION',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                    color: GcsColors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 20),

                // Protocol Selector
                DropdownButtonFormField<ConnectionProtocol>(
                  initialValue: _selectedProtocol,
                  decoration: const InputDecoration(
                    labelText: 'PROTOCOL',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: GcsColors.surfaceCard,
                  items: ConnectionProtocol.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.name, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProtocol = val);
                  },
                ),
                const SizedBox(height: 16),

                if (_selectedProtocol != ConnectionProtocol.sitl) ...[
                  TextField(
                    controller: _hostController,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      labelText: 'IP / HOST',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      labelText: 'PORT',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Connect / Disconnect Buttons
                if (!vehicle.isConnected)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GcsColors.greenActive,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.link),
                    label: const Text('CONNECT LINK'),
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
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.link_off),
                    label: const Text('DISCONNECT LINK'),
                    onPressed: () => mavlink.disconnect(),
                  ),

                const SizedBox(height: 30),
                const Divider(color: GcsColors.border),
                const SizedBox(height: 16),

                // Link Metrics Card
                const Text('DATALINK HEALTH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 10),
                _buildMetricRow('STATUS', vehicle.isConnected ? 'ONLINE' : 'OFFLINE', vehicle.isConnected ? GcsColors.greenActive : GcsColors.alertRed),
                _buildMetricRow('TRANSPORT', vehicle.connectionType, GcsColors.cyanAccent),
                _buildMetricRow('PACKETS RX', '${vehicle.packetCount}', Colors.white),
                _buildMetricRow('PACKET LOSS', '${vehicle.droppedPackets}', vehicle.droppedPackets > 0 ? GcsColors.warningOrange : Colors.white70),
                _buildMetricRow('LATENCY', '${vehicle.pingMs} ms', GcsColors.techAmber),
              ],
            ),
          ),

          // Right: MAVLink Terminal & Message Stream
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MAVLINK MESSAGE CONSOLE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: GcsColors.cyanAccent,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear_all, size: 20, color: Colors.white60),
                        tooltip: 'Clear Console',
                        onPressed: () {
                          setState(() {
                            vehicle.messageLog.clear();
                          });
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GcsColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GcsColors.border),
                      ),
                      child: ListView.builder(
                        itemCount: vehicle.messageLog.length,
                        itemBuilder: (context, index) {
                          final msg = vehicle.messageLog[index];
                          final timeStr = '${msg.timestamp.hour.toString().padLeft(2, "0")}:${msg.timestamp.minute.toString().padLeft(2, "0")}:${msg.timestamp.second.toString().padLeft(2, "0")}';

                          Color color;
                          switch (msg.severity) {
                            case SeverityLevel.critical:
                              color = GcsColors.alertRed;
                              break;
                            case SeverityLevel.warning:
                              color = GcsColors.warningOrange;
                              break;
                            case SeverityLevel.notice:
                              color = GcsColors.cyanAccent;
                              break;
                            case SeverityLevel.info:
                              color = Colors.white70;
                              break;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('[$timeStr] ', style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
                                Text('[${msg.severity.name.toUpperCase()}] ', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                Expanded(
                                  child: Text(msg.text, style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace')),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: GcsColors.textSecondary, fontFamily: 'monospace')),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: valueColor, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
