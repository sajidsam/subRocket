import 'package:latlong2/latlong.dart';

enum MissionCommandType {
  waypoint(id: 16, name: 'WAYPOINT', description: 'Fly to location at specified altitude and speed'),
  takeoff(id: 22, name: 'TAKEOFF', description: 'Takeoff from ground to target altitude'),
  land(id: 21, name: 'LAND', description: 'Land straight down or at target coordinates'),
  rtl(id: 20, name: 'RTL', description: 'Return to launch / Home coordinates and land'),
  loiterUnlim(id: 17, name: 'LOITER (UNLIM)', description: 'Hold position indefinitely until commanded'),
  loiterTime(id: 19, name: 'LOITER (TIME)', description: 'Hold position for specified seconds then resume'),
  loiterTurns(id: 18, name: 'LOITER (TURNS)', description: 'Orbit waypoint for N circles'),
  payloadRelease(id: 183, name: 'PAYLOAD / SERVO', description: 'Trigger servo relay / parachute / payload release'),
  changeSpeed(id: 178, name: 'CHANGE SPEED', description: 'Set new target flight speed in m/s');

  const MissionCommandType({
    required this.id,
    required this.name,
    required this.description,
  });

  final int id;
  final String name;
  final String description;
}

class MissionItem {
  final int seq;
  final MissionCommandType command;
  final LatLng position;
  final double altitude; // meters AGL
  final double speed; // m/s (0 = default cruise)
  final double delay; // seconds (hold time at waypoint)
  final double acceptanceRadius; // meters
  final double param1; // Custom parameter 1 (e.g. Servo ID or Takeoff Pitch)
  final double param2; // Custom parameter 2 (e.g. PWM value)

  MissionItem({
    required this.seq,
    required this.command,
    required this.position,
    this.altitude = 50.0,
    this.speed = 15.0,
    this.delay = 0.0,
    this.acceptanceRadius = 5.0,
    this.param1 = 0.0,
    this.param2 = 0.0,
  });

  MissionItem copyWith({
    int? seq,
    MissionCommandType? command,
    LatLng? position,
    double? altitude,
    double? speed,
    double? delay,
    double? acceptanceRadius,
    double? param1,
    double? param2,
  }) {
    return MissionItem(
      seq: seq ?? this.seq,
      command: command ?? this.command,
      position: position ?? this.position,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      delay: delay ?? this.delay,
      acceptanceRadius: acceptanceRadius ?? this.acceptanceRadius,
      param1: param1 ?? this.param1,
      param2: param2 ?? this.param2,
    );
  }

  Map<String, dynamic> toJson() => {
    'seq': seq,
    'command': command.name,
    'lat': position.latitude,
    'lng': position.longitude,
    'alt': altitude,
    'speed': speed,
    'delay': delay,
    'radius': acceptanceRadius,
    'param1': param1,
    'param2': param2,
  };

  factory MissionItem.fromJson(Map<String, dynamic> json) {
    return MissionItem(
      seq: json['seq'] ?? 0,
      command: MissionCommandType.values.firstWhere(
        (c) => c.name == json['command'],
        orElse: () => MissionCommandType.waypoint,
      ),
      position: LatLng(
        (json['lat'] as num?)?.toDouble() ?? 0.0,
        (json['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      altitude: (json['alt'] as num?)?.toDouble() ?? 50.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 15.0,
      delay: (json['delay'] as num?)?.toDouble() ?? 0.0,
      acceptanceRadius: (json['radius'] as num?)?.toDouble() ?? 5.0,
      param1: (json['param1'] as num?)?.toDouble() ?? 0.0,
      param2: (json['param2'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
