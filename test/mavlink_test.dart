import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_controller/core/models/flight_mode.dart';
import 'package:rocket_controller/core/models/mavlink_messages.dart';
import 'package:rocket_controller/core/models/mission_command.dart';
import 'package:rocket_controller/core/models/parameter_item.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('MAVLink Protocol & Models Tests', () {
    test('FlightMode string parser matches correctly', () {
      expect(FlightMode.fromString('AUTO'), FlightMode.auto);
      expect(FlightMode.fromString('STABILIZE'), FlightMode.stabilize);
      expect(FlightMode.fromString('ALT_HOLD'), FlightMode.altHold);
      expect(FlightMode.fromString('RTL'), FlightMode.rtl);
      expect(FlightMode.fromString('LOITER'), FlightMode.loiter);
    });

    test('MAVLink packet serialization and checksum works', () {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final packet = MavlinkPacket(
        len: payload.length,
        seq: 10,
        msgId: MavlinkMsgId.heartbeat,
        payload: payload,
        checksum: 0,
      );

      final rawBytes = packet.serialize();
      expect(rawBytes[0], 0xFD); // MAVLink v2 STX
      expect(rawBytes[1], payload.length);

      final parsed = MavlinkPacket.parse(rawBytes);
      expect(parsed, isNotNull);
      expect(parsed!.msgId, MavlinkMsgId.heartbeat);
      expect(parsed.len, payload.length);
      expect(parsed.seq, 10);
    });

    test('Mission item model serialization and copyWith', () {
      final item = MissionItem(
        seq: 1,
        command: MissionCommandType.waypoint,
        position: const LatLng(23.8103, 90.4125),
        altitude: 60.0,
        speed: 15.0,
      );

      final json = item.toJson();
      final fromJson = MissionItem.fromJson(json);
      expect(fromJson.seq, 1);
      expect(fromJson.command, MissionCommandType.waypoint);
      expect(fromJson.altitude, 60.0);
      expect(fromJson.speed, 15.0);

      final modified = item.copyWith(altitude: 100.0, speed: 20.0);
      expect(modified.altitude, 100.0);
      expect(modified.speed, 20.0);
    });

    test('ParameterItem update and dirty tracking', () {
      final param = ParameterItem(
        name: 'BATT_CAPACITY',
        value: 5200.0,
        defaultValue: 5200.0,
        min: 500.0,
        max: 50000.0,
        unit: 'mAh',
        description: 'Battery capacity',
        category: ParamCategory.battery,
      );

      expect(param.isDirty, isFalse);
      param.updateValue(6000.0);
      expect(param.value, 6000.0);
      expect(param.isDirty, isTrue);

      param.updateValue(5200.0);
      expect(param.isDirty, isFalse);
    });
  });
}
