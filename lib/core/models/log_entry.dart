class TelemetryFrame {
  final DateTime timestamp;
  final double altitude;
  final double groundspeed;
  final double airspeed;
  final double verticalSpeed;
  final double pitch;
  final double roll;
  final double yaw;
  final double batteryVoltage;
  final double batteryCurrent;
  final int batteryRemaining;
  final double lat;
  final double lon;
  final int throttlePercent;
  final String flightMode;
  final bool isArmed;
  final double vibeX;
  final double vibeY;
  final double vibeZ;

  TelemetryFrame({
    required this.timestamp,
    required this.altitude,
    required this.groundspeed,
    required this.airspeed,
    required this.verticalSpeed,
    required this.pitch,
    required this.roll,
    required this.yaw,
    required this.batteryVoltage,
    required this.batteryCurrent,
    required this.batteryRemaining,
    required this.lat,
    required this.lon,
    required this.throttlePercent,
    required this.flightMode,
    required this.isArmed,
    this.vibeX = 0.0,
    this.vibeY = 0.0,
    this.vibeZ = 0.0,
  });

  Map<String, dynamic> toJson() => {
    't': timestamp.millisecondsSinceEpoch,
    'alt': altitude,
    'gs': groundspeed,
    'as': airspeed,
    'vs': verticalSpeed,
    'p': pitch,
    'r': roll,
    'y': yaw,
    'bv': batteryVoltage,
    'bc': batteryCurrent,
    'br': batteryRemaining,
    'lat': lat,
    'lon': lon,
    'thr': throttlePercent,
    'mode': flightMode,
    'arm': isArmed,
    'vx': vibeX,
    'vy': vibeY,
    'vz': vibeZ,
  };

  factory TelemetryFrame.fromJson(Map<String, dynamic> json) {
    return TelemetryFrame(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['t'] as int? ?? 0),
      altitude: (json['alt'] as num?)?.toDouble() ?? 0.0,
      groundspeed: (json['gs'] as num?)?.toDouble() ?? 0.0,
      airspeed: (json['as'] as num?)?.toDouble() ?? 0.0,
      verticalSpeed: (json['vs'] as num?)?.toDouble() ?? 0.0,
      pitch: (json['p'] as num?)?.toDouble() ?? 0.0,
      roll: (json['r'] as num?)?.toDouble() ?? 0.0,
      yaw: (json['y'] as num?)?.toDouble() ?? 0.0,
      batteryVoltage: (json['bv'] as num?)?.toDouble() ?? 0.0,
      batteryCurrent: (json['bc'] as num?)?.toDouble() ?? 0.0,
      batteryRemaining: (json['br'] as int?) ?? 0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      throttlePercent: (json['thr'] as int?) ?? 0,
      flightMode: (json['mode'] as String?) ?? 'STABILIZE',
      isArmed: (json['arm'] as bool?) ?? false,
      vibeX: (json['vx'] as num?)?.toDouble() ?? 0.0,
      vibeY: (json['vy'] as num?)?.toDouble() ?? 0.0,
      vibeZ: (json['vz'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FlightLogSession {
  final String id;
  final String title;
  final DateTime startTime;
  DateTime endTime;
  double maxAltitude;
  double maxSpeed;
  double totalDistance;
  final List<TelemetryFrame> frames;

  FlightLogSession({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.maxAltitude = 0.0,
    this.maxSpeed = 0.0,
    this.totalDistance = 0.0,
    List<TelemetryFrame>? frames,
  }) : frames = frames ?? [];

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'start': startTime.millisecondsSinceEpoch,
    'end': endTime.millisecondsSinceEpoch,
    'maxAlt': maxAltitude,
    'maxSpeed': maxSpeed,
    'dist': totalDistance,
    'frames': frames.map((f) => f.toJson()).toList(),
  };

  factory FlightLogSession.fromJson(Map<String, dynamic> json) {
    return FlightLogSession(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Flight Session',
      startTime: DateTime.fromMillisecondsSinceEpoch(json['start'] as int? ?? 0),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['end'] as int? ?? 0),
      maxAltitude: (json['maxAlt'] as num?)?.toDouble() ?? 0.0,
      maxSpeed: (json['maxSpeed'] as num?)?.toDouble() ?? 0.0,
      totalDistance: (json['dist'] as num?)?.toDouble() ?? 0.0,
      frames: (json['frames'] as List<dynamic>?)
              ?.map((f) => TelemetryFrame.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
