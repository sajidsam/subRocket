import 'package:flutter/material.dart';

enum FlightMode {
  manual(
    name: 'MANUAL',
    description: 'Direct manual RC/joystick control with no stabilization',
    color: Colors.amber,
    requiresGps: false,
    allowsManualThrottle: true,
  ),
  stabilize(
    name: 'STABILIZE',
    description: 'Self-leveling roll and pitch attitude stabilization',
    color: Colors.cyan,
    requiresGps: false,
    allowsManualThrottle: true,
  ),
  altHold(
    name: 'ALT_HOLD',
    description: 'Automatic altitude hold with manual roll/pitch control',
    color: Colors.blueAccent,
    requiresGps: false,
    allowsManualThrottle: false,
  ),
  loiter(
    name: 'LOITER',
    description: 'GPS position hold and altitude hold (automatic hover)',
    color: Colors.greenAccent,
    requiresGps: true,
    allowsManualThrottle: false,
  ),
  auto(
    name: 'AUTO',
    description: 'Autonomous mission execution following planned waypoints',
    color: Colors.purpleAccent,
    requiresGps: true,
    allowsManualThrottle: false,
  ),
  guided(
    name: 'GUIDED',
    description: 'Autonomous navigation to point-and-click target locations',
    color: Colors.deepPurpleAccent,
    requiresGps: true,
    allowsManualThrottle: false,
  ),
  rtl(
    name: 'RTL',
    description: 'Return to Launch (climbs to safe alt, returns home, and lands)',
    color: Colors.orangeAccent,
    requiresGps: true,
    allowsManualThrottle: false,
  ),
  land(
    name: 'LAND',
    description: 'Vertical descent and automated motor disarm on touchdown',
    color: Colors.tealAccent,
    requiresGps: false,
    allowsManualThrottle: false,
  ),
  posHold(
    name: 'POSHOLD',
    description: 'Manual flying with automatic braking and position holding',
    color: Colors.lightGreenAccent,
    requiresGps: true,
    allowsManualThrottle: true,
  ),
  acro(
    name: 'ACRO',
    description: 'Rate control for acrobatic high-agility maneuvers',
    color: Colors.pinkAccent,
    requiresGps: false,
    allowsManualThrottle: true,
  ),
  brake(
    name: 'BRAKE',
    description: 'Instant dynamic braking and position hold to stop motion',
    color: Colors.redAccent,
    requiresGps: true,
    allowsManualThrottle: false,
  ),
  emergencyStop(
    name: 'EMERGENCY STOP',
    description: 'Immediate motor kill / parachute deploy failsafe',
    color: Colors.red,
    requiresGps: false,
    allowsManualThrottle: false,
  );

  const FlightMode({
    required this.name,
    required this.description,
    required this.color,
    required this.requiresGps,
    required this.allowsManualThrottle,
  });

  final String name;
  final String description;
  final Color color;
  final bool requiresGps;
  final bool allowsManualThrottle;

  static FlightMode fromString(String modeStr) {
    return FlightMode.values.firstWhere(
      (m) => m.name.toLowerCase() == modeStr.toLowerCase() ||
             m.name.replaceAll('_', '').toLowerCase() == modeStr.replaceAll('_', '').toLowerCase(),
      orElse: () => FlightMode.stabilize,
    );
  }
}
