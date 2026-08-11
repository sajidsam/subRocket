import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'flight_mode.dart';
import 'mission_command.dart';

enum GpsFixType {
  noGps(name: 'NO GPS', satellitesRequired: 0),
  fix2D(name: '2D FIX', satellitesRequired: 3),
  fix3D(name: '3D FIX', satellitesRequired: 4),
  dgps(name: 'DGPS', satellitesRequired: 6),
  rtkFloat(name: 'RTK FLOAT', satellitesRequired: 8),
  rtkFixed(name: 'RTK FIXED', satellitesRequired: 10);

  const GpsFixType({required this.name, required this.satellitesRequired});
  final String name;
  final int satellitesRequired;
}

enum SeverityLevel {
  info,
  notice,
  warning,
  critical,
}

class StatusMessage {
  final DateTime timestamp;
  final SeverityLevel severity;
  final String text;

  StatusMessage({
    required this.timestamp,
    required this.severity,
    required this.text,
  });
}

class VehicleState extends ChangeNotifier {
  // Connection & Datalink
  bool isConnected = false;
  String connectionType = 'SITL Simulator';
  int packetCount = 0;
  int droppedPackets = 0;
  int pingMs = 5;
  double bytesPerSec = 0.0;

  // Arm & Flight Mode
  bool isArmed = false;
  FlightMode mode = FlightMode.stabilize;
  DateTime? armTime;
  Duration flightDuration = Duration.zero;

  // Primary Flight Attitude
  double roll = 0.0; // degrees (-180 to 180)
  double pitch = 0.0; // degrees (-90 to 90)
  double yaw = 0.0; // degrees (0 to 360)
  double rollRate = 0.0; // deg/s
  double pitchRate = 0.0; // deg/s
  double yawRate = 0.0; // deg/s

  // Speeds & Altitude
  double groundspeed = 0.0; // m/s
  double airspeed = 0.0; // m/s
  double altitudeMsl = 0.0; // meters MSL
  double altitudeAgl = 0.0; // meters AGL (relative to home)
  double climbRate = 0.0; // m/s (Vertical Speed Indicator)
  int throttlePercent = 0; // % (0-100)

  // Navigation & GPS
  LatLng? currentLocation = const LatLng(23.8103, 90.4125);
  LatLng homeLocation = const LatLng(23.8103, 90.4125);
  GpsFixType gpsFix = GpsFixType.fix3D;
  int satellitesVisible = 14;
  double hdop = 0.8;
  double vdop = 1.1;
  double distanceToHome = 0.0;
  double distanceToNextWp = 0.0;
  int currentWaypointIndex = 0;
  double targetBearing = 0.0; // heading to current WP

  // Power & Battery
  double batteryVoltage = 15.8; // 4S LiPo typical
  double batteryCurrent = 12.4; // Amps
  int batteryRemaining = 88; // %
  double consumedMah = 450; // mAh consumed
  double cellVoltage = 3.95; // Volts per cell

  // Sensors & Health Diagnostics
  bool compassHealthy = true;
  bool imuHealthy = true;
  bool baroHealthy = true;
  bool gpsHealthy = true;
  bool ekfHealthy = true;
  double vibeX = 0.8;
  double vibeY = 0.7;
  double vibeZ = 1.2;

  // Radio / RC Channels (1-16) in PWM (1000 - 2000 us)
  List<int> rcChannels = List.filled(16, 1500);

  // Active Mission
  List<MissionItem> missionItems = [];
  bool isMissionActive = false;

  // Status message history
  final List<StatusMessage> messageLog = [];

  // Geofence settings
  double geofenceMaxAlt = 120.0; // meters
  double geofenceMaxRadius = 500.0; // meters
  bool geofenceEnabled = true;

  void addStatusMessage(String text, {SeverityLevel severity = SeverityLevel.info}) {
    messageLog.insert(0, StatusMessage(
      timestamp: DateTime.now(),
      severity: severity,
      text: text,
    ));
    if (messageLog.length > 200) {
      messageLog.removeLast();
    }
    notifyListeners();
  }

  void setFlightMode(FlightMode newMode) {
    if (mode == newMode) return;
    mode = newMode;
    addStatusMessage('Flight mode changed to ${newMode.name}', severity: SeverityLevel.info);
    notifyListeners();
  }

  void setArmed(bool armed) {
    if (isArmed == armed) return;
    isArmed = armed;
    if (armed) {
      armTime = DateTime.now();
      addStatusMessage('VEHICLE ARMED: Motors active', severity: SeverityLevel.warning);
    } else {
      armTime = null;
      flightDuration = Duration.zero;
      throttlePercent = 0;
      addStatusMessage('VEHICLE DISARMED', severity: SeverityLevel.notice);
    }
    notifyListeners();
  }

  void updateNavDistances() {
    if (currentLocation == null) return;
    const dist = Distance();
    distanceToHome = dist.as(LengthUnit.Meter, currentLocation!, homeLocation);

    if (missionItems.isNotEmpty && currentWaypointIndex < missionItems.length) {
      final targetWp = missionItems[currentWaypointIndex].position;
      distanceToNextWp = dist.as(LengthUnit.Meter, currentLocation!, targetWp);
      targetBearing = (dist.bearing(currentLocation!, targetWp) + 360) % 360;
    } else {
      distanceToNextWp = 0.0;
      targetBearing = 0.0;
    }
  }

  void notifyStateChanged() {
    notifyListeners();
  }

  void addMissionItem(MissionItem item) {
    missionItems.add(item);
    notifyListeners();
  }

  void updateGeofence({required bool enabled, required double maxAlt, required double maxRadius}) {
    geofenceEnabled = enabled;
    geofenceMaxAlt = maxAlt;
    geofenceMaxRadius = maxRadius;
    notifyListeners();
  }

  void setThrottle(int percent) {
    throttlePercent = percent.clamp(0, 100);
    notifyListeners();
  }
}
