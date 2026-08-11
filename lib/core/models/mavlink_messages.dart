import 'dart:convert';
import 'dart:typed_data';

/// MAVLink message IDs
class MavlinkMsgId {
  static const int heartbeat = 0;
  static const int sysStatus = 1;
  static const int paramRequestList = 21;
  static const int paramValue = 22;
  static const int paramSet = 23;
  static const int gpsRawInt = 24;
  static const int attitude = 30;
  static const int globalPositionInt = 33;
  static const int missionItem = 39;
  static const int missionRequest = 40;
  static const int missionSetCurrent = 41;
  static const int missionCurrent = 42;
  static const int missionCount = 44;
  static const int missionClearAll = 45;
  static const int missionAck = 47;
  static const int vfrHud = 74;
  static const int commandLong = 76;
  static const int commandAck = 77;
  static const int statustext = 253;
}

/// MAVLink command IDs (MAV_CMD)
class MavCmd {
  static const int navWaypoint = 16;
  static const int navReturnToLaunch = 20;
  static const int navLand = 21;
  static const int navTakeoff = 22;
  static const int navLoiterUnlim = 17;
  static const int navLoiterTurns = 18;
  static const int navLoiterTime = 19;
  static const int componentArmDisarm = 400;
  static const int doSetMode = 176;
  static const int doSetServo = 183;
  static const int doChangeSpeed = 178;
  static const int preflightRebootShutdown = 246;
  static const int preflightCalibration = 241;
  static const int doMotorTest = 209;
}

/// Generic MAVLink Packet Representation
class MavlinkPacket {
  final int magic; // 0xFD for MAVLink v2, 0xFE for MAVLink v1
  final int len;
  final int incompatFlags;
  final int compatFlags;
  final int seq;
  final int sysId;
  final int compId;
  final int msgId;
  final Uint8List payload;
  final int checksum;

  MavlinkPacket({
    this.magic = 0xFD,
    required this.len,
    this.incompatFlags = 0,
    this.compatFlags = 0,
    required this.seq,
    this.sysId = 255, // GCS default sysId
    this.compId = 190, // GCS default compId
    required this.msgId,
    required this.payload,
    required this.checksum,
  });

  /// Parse MAVLink v2 or v1 frame
  static MavlinkPacket? parse(Uint8List bytes) {
    if (bytes.length < 8) return null;

    final magic = bytes[0];
    if (magic == 0xFD) {
      // MAVLink v2 frame: [STX=0xFD, LEN, INC_FLAGS, COMP_FLAGS, SEQ, SYSID, COMPID, MSGID (3 bytes), PAYLOAD, CHECKSUM (2 bytes)]
      if (bytes.length < 12) return null;
      final len = bytes[1];
      if (bytes.length < 12 + len) return null;

      final incompatFlags = bytes[2];
      final compatFlags = bytes[3];
      final seq = bytes[4];
      final sysId = bytes[5];
      final compId = bytes[6];
      final msgId = bytes[7] | (bytes[8] << 8) | (bytes[9] << 16);
      final payload = bytes.sublist(10, 10 + len);
      final checksum = bytes[10 + len] | (bytes[10 + len + 1] << 8);

      return MavlinkPacket(
        magic: magic,
        len: len,
        incompatFlags: incompatFlags,
        compatFlags: compatFlags,
        seq: seq,
        sysId: sysId,
        compId: compId,
        msgId: msgId,
        payload: payload,
        checksum: checksum,
      );
    } else if (magic == 0xFE) {
      // MAVLink v1 frame: [STX=0xFE, LEN, SEQ, SYSID, COMPID, MSGID (1 byte), PAYLOAD, CHECKSUM (2 bytes)]
      if (bytes.length < 8) return null;
      final len = bytes[1];
      if (bytes.length < 8 + len) return null;

      final seq = bytes[2];
      final sysId = bytes[3];
      final compId = bytes[4];
      final msgId = bytes[5];
      final payload = bytes.sublist(6, 6 + len);
      final checksum = bytes[6 + len] | (bytes[6 + len + 1] << 8);

      return MavlinkPacket(
        magic: magic,
        len: len,
        seq: seq,
        sysId: sysId,
        compId: compId,
        msgId: msgId,
        payload: payload,
        checksum: checksum,
      );
    }
    return null;
  }

  /// Serialize packet to Uint8List with CRC-16-MCRF4XX / X.25
  Uint8List serialize() {
    final buffer = BytesBuilder();
    buffer.addByte(0xFD); // MAVLink v2 STX
    buffer.addByte(payload.length);
    buffer.addByte(incompatFlags);
    buffer.addByte(compatFlags);
    buffer.addByte(seq & 0xFF);
    buffer.addByte(sysId & 0xFF);
    buffer.addByte(compId & 0xFF);
    buffer.addByte(msgId & 0xFF);
    buffer.addByte((msgId >> 8) & 0xFF);
    buffer.addByte((msgId >> 16) & 0xFF);
    buffer.add(payload);

    final rawHeaderAndPayload = buffer.toBytes().sublist(1); // skip STX for CRC
    int crc = _calculateCrc(rawHeaderAndPayload);

    buffer.addByte(crc & 0xFF);
    buffer.addByte((crc >> 8) & 0xFF);

    return buffer.toBytes();
  }

  static int _calculateCrc(Uint8List data) {
    int crc = 0xFFFF;
    for (int b in data) {
      int tmp = b ^ (crc & 0xFF);
      tmp = (tmp ^ (tmp << 4)) & 0xFF;
      crc = ((crc >> 8) ^ (tmp << 8) ^ (tmp << 3) ^ (tmp >> 4)) & 0xFFFF;
    }
    return crc;
  }
}

/// Parsed MAVLink Telemetry Structures
class MavAttitude {
  final double roll; // degrees
  final double pitch; // degrees
  final double yaw; // degrees
  final double rollSpeed;
  final double pitchSpeed;
  final double yawSpeed;

  MavAttitude({
    required this.roll,
    required this.pitch,
    required this.yaw,
    this.rollSpeed = 0,
    this.pitchSpeed = 0,
    this.yawSpeed = 0,
  });

  static MavAttitude? fromPayload(Uint8List payload) {
    if (payload.length < 28) return null;
    final data = ByteData.sublistView(payload);
    // time_boot_ms (4 bytes uint32)
    final rollRad = data.getFloat32(4, Endian.little);
    final pitchRad = data.getFloat32(8, Endian.little);
    final yawRad = data.getFloat32(12, Endian.little);
    final rSpeed = data.getFloat32(16, Endian.little);
    final pSpeed = data.getFloat32(20, Endian.little);
    final ySpeed = data.getFloat32(24, Endian.little);

    return MavAttitude(
      roll: rollRad * (180.0 / 3.1415926535),
      pitch: pitchRad * (180.0 / 3.1415926535),
      yaw: (yawRad * (180.0 / 3.1415926535) + 360) % 360,
      rollSpeed: rSpeed,
      pitchSpeed: pSpeed,
      yawSpeed: ySpeed,
    );
  }
}

class MavGlobalPositionInt {
  final double lat; // deg
  final double lon; // deg
  final double alt; // meters MSL
  final double relativeAlt; // meters AGL
  final double vx; // m/s
  final double vy; // m/s
  final double vz; // m/s
  final double hdg; // deg

  MavGlobalPositionInt({
    required this.lat,
    required this.lon,
    required this.alt,
    required this.relativeAlt,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.hdg,
  });

  static MavGlobalPositionInt? fromPayload(Uint8List payload) {
    if (payload.length < 28) return null;
    final data = ByteData.sublistView(payload);
    // time_boot_ms (4 bytes)
    final latE7 = data.getInt32(4, Endian.little);
    final lonE7 = data.getInt32(8, Endian.little);
    final altMm = data.getInt32(12, Endian.little);
    final relAltMm = data.getInt32(16, Endian.little);
    final vxCm = data.getInt16(20, Endian.little);
    final vyCm = data.getInt16(22, Endian.little);
    final vzCm = data.getInt16(24, Endian.little);
    final hdgCentiDeg = data.getUint16(26, Endian.little);

    return MavGlobalPositionInt(
      lat: latE7 / 1e7,
      lon: lonE7 / 1e7,
      alt: altMm / 1000.0,
      relativeAlt: relAltMm / 1000.0,
      vx: vxCm / 100.0,
      vy: vyCm / 100.0,
      vz: vzCm / 100.0,
      hdg: hdgCentiDeg / 100.0,
    );
  }
}

class MavSysStatus {
  final double voltageBattery; // Volts
  final double currentBattery; // Amperes
  final int batteryRemaining; // % (0-100)
  final int dropRateComm;
  final int cpuLoad;

  MavSysStatus({
    required this.voltageBattery,
    required this.currentBattery,
    required this.batteryRemaining,
    required this.dropRateComm,
    required this.cpuLoad,
  });

  static MavSysStatus? fromPayload(Uint8List payload) {
    if (payload.length < 31) return null;
    final data = ByteData.sublistView(payload);
    // onboard_control_sensors_present/enabled/health (12 bytes)
    final load = data.getUint16(12, Endian.little) ~/ 10;
    final voltMv = data.getUint16(14, Endian.little);
    final currCa = data.getInt16(16, Endian.little);
    final remaining = data.getInt8(18);
    final dropRate = data.getUint16(19, Endian.little);

    return MavSysStatus(
      voltageBattery: voltMv / 1000.0,
      currentBattery: currCa >= 0 ? currCa / 100.0 : 0.0,
      batteryRemaining: remaining.clamp(0, 100),
      dropRateComm: dropRate,
      cpuLoad: load,
    );
  }
}

class MavVfrHud {
  final double airspeed; // m/s
  final double groundspeed; // m/s
  final double heading; // deg (0-360)
  final int throttle; // % (0-100)
  final double alt; // meters
  final double climb; // m/s

  MavVfrHud({
    required this.airspeed,
    required this.groundspeed,
    required this.heading,
    required this.throttle,
    required this.alt,
    required this.climb,
  });

  static MavVfrHud? fromPayload(Uint8List payload) {
    if (payload.length < 20) return null;
    final data = ByteData.sublistView(payload);
    final airspeed = data.getFloat32(0, Endian.little);
    final groundspeed = data.getFloat32(4, Endian.little);
    final heading = data.getInt16(8, Endian.little).toDouble();
    final throttle = data.getUint16(10, Endian.little);
    final alt = data.getFloat32(12, Endian.little);
    final climb = data.getFloat32(16, Endian.little);

    return MavVfrHud(
      airspeed: airspeed,
      groundspeed: groundspeed,
      heading: (heading + 360) % 360,
      throttle: throttle.clamp(0, 100),
      alt: alt,
      climb: climb,
    );
  }
}

class MavStatustext {
  final int severity;
  final String text;

  MavStatustext({required this.severity, required this.text});

  static MavStatustext? fromPayload(Uint8List payload) {
    if (payload.isEmpty) return null;
    final severity = payload[0];
    final textBytes = payload.sublist(1);
    final nullIndex = textBytes.indexOf(0);
    final validBytes = nullIndex != -1 ? textBytes.sublist(0, nullIndex) : textBytes;
    final text = utf8.decode(validBytes, allowMalformed: true);

    return MavStatustext(severity: severity, text: text);
  }
}
