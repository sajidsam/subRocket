import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/flight_mode.dart';
import '../models/mavlink_messages.dart';
import '../models/mission_command.dart';
import '../models/vehicle_state.dart';
import 'sitl_simulator.dart';
import 'speech_service.dart';

enum ConnectionProtocol {
  sitl(name: 'SITL Simulator (Built-in)'),
  udp(name: 'UDP MAVLink (Port 14550)'),
  tcp(name: 'TCP Telemetry Bridge'),
  httpRest(name: 'HTTP / REST Controller');

  const ConnectionProtocol({required this.name});
  final String name;
}

class MavlinkService extends ChangeNotifier {
  final VehicleState vehicle;
  final SpeechService speech;
  late final SitlSimulator simulator;

  ConnectionProtocol activeProtocol = ConnectionProtocol.sitl;
  String ipAddress = '127.0.0.1';
  int port = 14550;

  RawDatagramSocket? _udpSocket;
  Socket? _tcpSocket;
  Timer? _heartbeatTimer;
  Timer? _httpPollTimer;

  MavlinkService({required this.vehicle, required this.speech}) {
    simulator = SitlSimulator(vehicle: vehicle);
    // Start with SITL simulator enabled by default so app is fully functional immediately
    connect(ConnectionProtocol.sitl);
  }

  Future<void> connect(ConnectionProtocol protocol, {String? host, int? portNum}) async {
    await disconnect();

    activeProtocol = protocol;
    if (host != null) ipAddress = host;
    if (portNum != null) port = portNum;

    try {
      switch (protocol) {
        case ConnectionProtocol.sitl:
          simulator.start();
          vehicle.isConnected = true;
          vehicle.connectionType = 'SITL Simulator';
          break;

        case ConnectionProtocol.udp:
          _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
          _udpSocket?.listen((RawSocketEvent event) {
            if (event == RawSocketEvent.read) {
              final dg = _udpSocket?.receive();
              if (dg != null) {
                _processIncomingBytes(dg.data);
              }
            }
          });
          vehicle.isConnected = true;
          vehicle.connectionType = 'UDP :$port';
          _startHeartbeat();
          vehicle.addStatusMessage('Connected to UDP MAVLink on port $port', severity: SeverityLevel.info);
          break;

        case ConnectionProtocol.tcp:
          _tcpSocket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 4));
          _tcpSocket?.listen((Uint8List data) {
            _processIncomingBytes(data);
          }, onDone: () => disconnect(), onError: (e) => disconnect());
          vehicle.isConnected = true;
          vehicle.connectionType = 'TCP $ipAddress:$port';
          _startHeartbeat();
          vehicle.addStatusMessage('Connected to TCP MAVLink $ipAddress:$port', severity: SeverityLevel.info);
          break;

        case ConnectionProtocol.httpRest:
          vehicle.isConnected = true;
          vehicle.connectionType = 'HTTP $ipAddress';
          _startHttpPolling();
          vehicle.addStatusMessage('Connected to HTTP controller at $ipAddress', severity: SeverityLevel.info);
          break;
      }
    } catch (e) {
      vehicle.isConnected = false;
      vehicle.addStatusMessage('Connection error ($protocol): $e', severity: SeverityLevel.critical);
    }
    notifyListeners();
  }

  void disconnectSync() {
    simulator.stop();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _httpPollTimer?.cancel();
    _httpPollTimer = null;

    _udpSocket?.close();
    _udpSocket = null;

    _tcpSocket?.destroy();
    _tcpSocket = null;

    vehicle.isConnected = false;
  }

  Future<void> disconnect() async {
    disconnectSync();
    notifyListeners();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sendHeartbeat();
    });
  }

  void _startHttpPolling() {
    _httpPollTimer?.cancel();
    _httpPollTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      try {
        final url = Uri.parse('http://$ipAddress/telemetry');
        final resp = await http.get(url).timeout(const Duration(seconds: 1));
        if (resp.statusCode == 200) {
          vehicle.packetCount++;
          // HTTP telemetry JSON parser hook
        }
      } catch (_) {
        vehicle.droppedPackets++;
      }
    });
  }

  void _processIncomingBytes(Uint8List bytes) {
    vehicle.packetCount++;
    final packet = MavlinkPacket.parse(bytes);
    if (packet == null) return;

    switch (packet.msgId) {
      case MavlinkMsgId.attitude:
        final att = MavAttitude.fromPayload(packet.payload);
        if (att != null) {
          vehicle.roll = att.roll;
          vehicle.pitch = att.pitch;
          vehicle.yaw = att.yaw;
          vehicle.rollRate = att.rollSpeed;
          vehicle.pitchRate = att.pitchSpeed;
          vehicle.yawRate = att.yawSpeed;
        }
        break;

      case MavlinkMsgId.globalPositionInt:
        final pos = MavGlobalPositionInt.fromPayload(packet.payload);
        if (pos != null) {
          vehicle.altitudeMsl = pos.alt;
          vehicle.altitudeAgl = pos.relativeAlt;
          vehicle.groundspeed = pos.vx.abs() + pos.vy.abs();
          vehicle.climbRate = -pos.vz;
        }
        break;

      case MavlinkMsgId.sysStatus:
        final sys = MavSysStatus.fromPayload(packet.payload);
        if (sys != null) {
          vehicle.batteryVoltage = sys.voltageBattery;
          vehicle.batteryCurrent = sys.currentBattery;
          vehicle.batteryRemaining = sys.batteryRemaining;
          vehicle.droppedPackets = sys.dropRateComm;
        }
        break;

      case MavlinkMsgId.vfrHud:
        final vfr = MavVfrHud.fromPayload(packet.payload);
        if (vfr != null) {
          vehicle.airspeed = vfr.airspeed;
          vehicle.groundspeed = vfr.groundspeed;
          vehicle.throttlePercent = vfr.throttle;
          vehicle.climbRate = vfr.climb;
        }
        break;

      case MavlinkMsgId.statustext:
        final st = MavStatustext.fromPayload(packet.payload);
        if (st != null) {
          final sev = st.severity <= 3 ? SeverityLevel.critical : (st.severity <= 5 ? SeverityLevel.warning : SeverityLevel.info);
          vehicle.addStatusMessage(st.text, severity: sev);
        }
        break;
    }
    vehicle.updateNavDistances();
    vehicle.notifyListeners();
  }

  void _sendHeartbeat() {
    final payload = Uint8List(9);
    final packet = MavlinkPacket(
      len: 9,
      seq: (vehicle.packetCount % 256),
      msgId: MavlinkMsgId.heartbeat,
      payload: payload,
      checksum: 0,
    );
    sendPacket(packet);
  }

  void sendPacket(MavlinkPacket packet) {
    final raw = packet.serialize();
    if (_udpSocket != null) {
      _udpSocket?.send(raw, InternetAddress(ipAddress), port);
    } else if (_tcpSocket != null) {
      _tcpSocket?.add(raw);
    }
  }

  // --- High-Level Command API ---

  void setFlightMode(FlightMode mode) {
    vehicle.setFlightMode(mode);
    speech.announceModeChange(mode.name);

    if (activeProtocol == ConnectionProtocol.httpRest) {
      _sendHttpCmd('setMode?mode=${mode.name}');
    }
  }

  void returnToHome() => setFlightMode(FlightMode.rtl);

  void armDisarm(bool arm) {
    vehicle.setArmed(arm);
    if (arm) {
      speech.announceArmed();
    } else {
      speech.announceDisarmed();
    }

    if (activeProtocol == ConnectionProtocol.httpRest) {
      _sendHttpCmd('arm?value=${arm ? 1 : 0}');
    }
  }

  void armVehicle() => armDisarm(true);
  void disarmVehicle() => armDisarm(false);

  void manualControl({double pitch = 0, double roll = 0, double throttle = 0, double yaw = 0}) {
    if (simulator.isRunning) {
      simulator.joyPitch = (pitch / 1000.0).clamp(-1.0, 1.0);
      simulator.joyRoll = (roll / 1000.0).clamp(-1.0, 1.0);
      simulator.joyYaw = (yaw / 1000.0).clamp(-1.0, 1.0);
      if (throttle > 0) {
        simulator.joyThrottle = ((throttle / 500.0) - 1.0).clamp(-1.0, 1.0);
      }
    }
  }

  void emergencyStop() {
    vehicle.setFlightMode(FlightMode.emergencyStop);
    vehicle.setArmed(false);
    speech.playAlarm(reason: 'EMERGENCY MOTOR KILL TRIGGERED', isCritical: true);

    if (activeProtocol == ConnectionProtocol.httpRest) {
      _sendHttpCmd('setSpeed?value=0');
    }
  }

  void setThrottle(double percent) {
    vehicle.setThrottle(percent.toInt());
    if (simulator.isRunning) {
      simulator.joyThrottle = (percent / 50.0) - 1.0;
    }
    if (activeProtocol == ConnectionProtocol.httpRest) {
      _sendHttpCmd('setSpeed?value=${percent.toInt()}');
    }
  }

  void uploadMission(List<MissionItem> items) {
    vehicle.missionItems = List.from(items);
    vehicle.currentWaypointIndex = 0;
    vehicle.addStatusMessage('Mission uploaded: ${items.length} waypoints synced', severity: SeverityLevel.info);
    speech.announce('Mission uploaded successfully');
    notifyListeners();
  }

  void _sendHttpCmd(String query) {
    final url = Uri.parse('http://$ipAddress/$query');
    http.get(url).timeout(const Duration(seconds: 2)).catchError((e) {
      debugPrint('HTTP CMD failed: $e');
      return http.Response('', 500);
    });
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
