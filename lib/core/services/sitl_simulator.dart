import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/flight_mode.dart';
import '../models/mission_command.dart';
import '../models/vehicle_state.dart';

/// 6-DOF Physics & Autopilot Flight Simulator (SITL)
class SitlSimulator {
  final VehicleState vehicle;
  Timer? _simTimer;
  final Random _rnd = Random();

  // Simulated Joystick / RC inputs (-1.0 to 1.0)
  double joyThrottle = 0.0;
  double joyPitch = 0.0;
  double joyRoll = 0.0;
  double joyYaw = 0.0;
  bool isManualControlActive = false;

  bool isRunning = false;

  SitlSimulator({required this.vehicle});

  void start() {
    if (isRunning) return;
    isRunning = true;
    vehicle.isConnected = true;
    vehicle.connectionType = 'SITL Simulator (6-DOF)';
    vehicle.addStatusMessage('SITL 6-DOF Autopilot Simulator Initialized', severity: SeverityLevel.info);

    _simTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _tick();
    });
  }

  void stop() {
    isRunning = false;
    _simTimer?.cancel();
    _simTimer = null;
    vehicle.isConnected = false;
    vehicle.addStatusMessage('SITL Simulator Stopped', severity: SeverityLevel.notice);
  }

  void setManualInputs({
    required double throttle,
    required double pitch,
    required double roll,
    required double yaw,
  }) {
    joyThrottle = throttle;
    joyPitch = pitch;
    joyRoll = roll;
    joyYaw = yaw;
    isManualControlActive = (throttle != 0 || pitch != 0 || roll != 0 || yaw != 0);
  }

  void _tick() {
    vehicle.packetCount += 1;
    vehicle.pingMs = 2 + _rnd.nextInt(3);

    // Update flight timer if armed
    if (vehicle.isArmed && vehicle.armTime != null) {
      vehicle.flightDuration = DateTime.now().difference(vehicle.armTime!);
    }

    // Battery simulation
    if (vehicle.isArmed) {
      final throttleFactor = (vehicle.throttlePercent / 100.0).clamp(0.1, 1.0);
      vehicle.batteryCurrent = 8.0 + (throttleFactor * 22.0) + (_rnd.nextDouble() * 0.4 - 0.2);
      vehicle.consumedMah += (vehicle.batteryCurrent * (50.0 / 3600000.0) * 1000.0);
      vehicle.batteryRemaining = (100 - (vehicle.consumedMah / 5200.0 * 100)).clamp(0, 100).toInt();
      vehicle.batteryVoltage = (14.0 + (vehicle.batteryRemaining / 100.0 * 2.8)).clamp(13.2, 16.8);
      vehicle.cellVoltage = vehicle.batteryVoltage / 4.0;
    } else {
      vehicle.batteryCurrent = 0.4 + (_rnd.nextDouble() * 0.1);
    }

    // Vibration / IMU Noise
    if (vehicle.isArmed) {
      vehicle.vibeX = 0.8 + (_rnd.nextDouble() * 0.4);
      vehicle.vibeY = 0.7 + (_rnd.nextDouble() * 0.3);
      vehicle.vibeZ = 1.2 + (_rnd.nextDouble() * 0.6);
    } else {
      vehicle.vibeX = 0.05;
      vehicle.vibeY = 0.05;
      vehicle.vibeZ = 0.08;
    }

    // Mode-specific flight physics
    switch (vehicle.mode) {
      case FlightMode.manual:
      case FlightMode.stabilize:
      case FlightMode.acro:
        _handleManualFlight();
        break;
      case FlightMode.altHold:
      case FlightMode.posHold:
      case FlightMode.loiter:
        _handleLoiterOrAltHold();
        break;
      case FlightMode.auto:
        _handleAutoMission();
        break;
      case FlightMode.rtl:
        _handleRtl();
        break;
      case FlightMode.land:
        _handleLand();
        break;
      case FlightMode.emergencyStop:
        _handleEmergencyStop();
        break;
      default:
        _handleLoiterOrAltHold();
    }

    // Clamp altitude
    if (vehicle.altitudeAgl < 0) {
      vehicle.altitudeAgl = 0;
      vehicle.climbRate = 0;
    }
    vehicle.altitudeMsl = 20.0 + vehicle.altitudeAgl; // Dhaka elevation baseline

    // Geofence check
    if (vehicle.geofenceEnabled && vehicle.isArmed) {
      if (vehicle.altitudeAgl > vehicle.geofenceMaxAlt) {
        vehicle.addStatusMessage('GEOFENCE BREACH: Max Alt ${vehicle.geofenceMaxAlt.toInt()}m exceeded! RTL initiated', severity: SeverityLevel.critical);
        vehicle.setFlightMode(FlightMode.rtl);
      }
      if (vehicle.distanceToHome > vehicle.geofenceMaxRadius) {
        vehicle.addStatusMessage('GEOFENCE BREACH: Max Radius ${vehicle.geofenceMaxRadius.toInt()}m exceeded! RTL initiated', severity: SeverityLevel.critical);
        vehicle.setFlightMode(FlightMode.rtl);
      }
    }

    // Update distances
    vehicle.updateNavDistances();
    vehicle.notifyStateChanged();
  }

  void _handleManualFlight() {
    if (!vehicle.isArmed) {
      _applyDisarmedDecay();
      return;
    }

    // Roll and pitch mapped to manual joystick
    vehicle.roll = (joyRoll * 45.0) + (_rnd.nextDouble() * 0.4 - 0.2);
    vehicle.pitch = (joyPitch * 45.0) + (_rnd.nextDouble() * 0.4 - 0.2);
    vehicle.yaw = (vehicle.yaw + (joyYaw * 3.0) + 360) % 360;

    // Throttle controls climb rate
    vehicle.throttlePercent = ((joyThrottle + 1.0) / 2.0 * 100).clamp(0, 100).toInt();
    if (vehicle.throttlePercent > 50) {
      vehicle.climbRate = (vehicle.throttlePercent - 50) / 10.0;
    } else {
      vehicle.climbRate = (vehicle.throttlePercent - 50) / 15.0;
    }
    vehicle.altitudeAgl += (vehicle.climbRate * 0.05);

    // Lateral displacement based on pitch & roll
    final speed = sqrt(joyPitch * joyPitch + joyRoll * joyRoll) * 20.0;
    vehicle.groundspeed = speed;
    vehicle.airspeed = speed + 1.5;

    if (vehicle.currentLocation != null && speed > 0.1) {
      final moveBearing = (atan2(joyRoll, -joyPitch) * (180.0 / pi) + 360) % 360;
      const dist = Distance();
      vehicle.currentLocation = dist.offset(vehicle.currentLocation!, speed * 0.05, moveBearing);
    }
  }

  void _handleLoiterOrAltHold() {
    if (!vehicle.isArmed) {
      _applyDisarmedDecay();
      return;
    }

    if (isManualControlActive) {
      _handleManualFlight();
      return;
    }

    // Automatic leveling and hover
    vehicle.roll *= 0.92;
    vehicle.pitch *= 0.92;
    vehicle.climbRate *= 0.90;
    vehicle.groundspeed *= 0.95;
    vehicle.airspeed = vehicle.groundspeed;
    vehicle.throttlePercent = 50; // hover throttle
  }

  void _handleAutoMission() {
    if (!vehicle.isArmed || vehicle.missionItems.isEmpty) {
      _handleLoiterOrAltHold();
      return;
    }

    final currentIndex = vehicle.currentWaypointIndex;
    if (currentIndex >= vehicle.missionItems.length) {
      vehicle.addStatusMessage('Mission Complete! Holding Loiter.', severity: SeverityLevel.notice);
      vehicle.setFlightMode(FlightMode.loiter);
      return;
    }

    final currentWp = vehicle.missionItems[currentIndex];
    final targetPos = currentWp.position;
    final currentPos = vehicle.currentLocation ?? vehicle.homeLocation;

    const dist = Distance();
    final distanceToWp = dist.as(LengthUnit.Meter, currentPos, targetPos);
    final bearingToWp = (dist.bearing(currentPos, targetPos) + 360) % 360;

    // Reached Waypoint?
    if (distanceToWp <= currentWp.acceptanceRadius || (distanceToWp < 8.0)) {
      vehicle.addStatusMessage('Waypoint ${currentIndex + 1} Reached (${currentWp.command.name})', severity: SeverityLevel.notice);

      if (currentWp.command == MissionCommandType.rtl) {
        vehicle.setFlightMode(FlightMode.rtl);
        return;
      } else if (currentWp.command == MissionCommandType.land) {
        vehicle.setFlightMode(FlightMode.land);
        return;
      }

      vehicle.currentWaypointIndex += 1;
      if (vehicle.currentWaypointIndex >= vehicle.missionItems.length) {
        vehicle.addStatusMessage('All Mission Waypoints Completed. Executing RTL.', severity: SeverityLevel.notice);
        vehicle.setFlightMode(FlightMode.rtl);
      }
      return;
    }

    // Smooth Turn towards waypoint
    final diffYaw = _normalizeAngle(bearingToWp - vehicle.yaw);
    vehicle.yaw = (vehicle.yaw + diffYaw.clamp(-4.0, 4.0) + 360) % 360;

    // Bank into turn
    vehicle.roll = (diffYaw.clamp(-25.0, 25.0) * 0.8);
    vehicle.pitch = -10.0; // forward pitch for flight

    // Adjust altitude towards waypoint target altitude
    final targetAlt = currentWp.altitude;
    if ((vehicle.altitudeAgl - targetAlt).abs() > 1.0) {
      vehicle.climbRate = (targetAlt - vehicle.altitudeAgl).clamp(-4.0, 4.0);
    } else {
      vehicle.climbRate = 0.0;
    }
    vehicle.altitudeAgl += (vehicle.climbRate * 0.05);

    // Speed & Position forward step
    final cruiseSpeed = currentWp.speed > 0 ? currentWp.speed : 15.0;
    vehicle.groundspeed = cruiseSpeed;
    vehicle.airspeed = cruiseSpeed + 1.2;
    vehicle.throttlePercent = 75;

    vehicle.currentLocation = dist.offset(currentPos, cruiseSpeed * 0.05, vehicle.yaw);
  }

  void _handleRtl() {
    if (!vehicle.isArmed) {
      _applyDisarmedDecay();
      return;
    }

    const dist = Distance();
    final currentPos = vehicle.currentLocation ?? vehicle.homeLocation;
    final distanceToHome = dist.as(LengthUnit.Meter, currentPos, vehicle.homeLocation);

    // Step 1: Climb to safe RTL altitude (50m) if below
    if (vehicle.altitudeAgl < 50.0 && distanceToHome > 15.0) {
      vehicle.climbRate = 3.0;
      vehicle.altitudeAgl += (vehicle.climbRate * 0.05);
      vehicle.throttlePercent = 80;
    }

    if (distanceToHome > 10.0) {
      // Step 2: Fly home
      final bearingHome = (dist.bearing(currentPos, vehicle.homeLocation) + 360) % 360;
      final diffYaw = _normalizeAngle(bearingHome - vehicle.yaw);
      vehicle.yaw = (vehicle.yaw + diffYaw.clamp(-4.0, 4.0) + 360) % 360;
      vehicle.roll = diffYaw.clamp(-20.0, 20.0);
      vehicle.pitch = -12.0;
      vehicle.groundspeed = 14.0;
      vehicle.currentLocation = dist.offset(currentPos, 14.0 * 0.05, vehicle.yaw);
    } else {
      // Step 3: Arrived above Home, transition to Auto Land
      vehicle.groundspeed = 0.0;
      vehicle.pitch = 0.0;
      vehicle.roll = 0.0;
      vehicle.setFlightMode(FlightMode.land);
    }
  }

  void _handleLand() {
    if (!vehicle.isArmed) {
      _applyDisarmedDecay();
      return;
    }

    vehicle.groundspeed = 0.0;
    vehicle.roll *= 0.8;
    vehicle.pitch *= 0.8;

    if (vehicle.altitudeAgl > 0.2) {
      vehicle.climbRate = -1.5; // gentle descent
      vehicle.altitudeAgl += (vehicle.climbRate * 0.05);
      vehicle.throttlePercent = 35;
    } else {
      // Touchdown: Disarm motors
      vehicle.altitudeAgl = 0.0;
      vehicle.climbRate = 0.0;
      vehicle.setArmed(false);
      vehicle.setFlightMode(FlightMode.stabilize);
      vehicle.addStatusMessage('Touchdown detected: Motors Disarmed.', severity: SeverityLevel.notice);
    }
  }

  void _handleEmergencyStop() {
    vehicle.throttlePercent = 0;
    vehicle.climbRate = -9.8; // freefall or parachute
    vehicle.altitudeAgl += (vehicle.climbRate * 0.05);
    vehicle.groundspeed *= 0.9;
    if (vehicle.altitudeAgl <= 0) {
      vehicle.altitudeAgl = 0;
      vehicle.climbRate = 0;
      vehicle.setArmed(false);
    }
  }

  void _applyDisarmedDecay() {
    vehicle.groundspeed = 0.0;
    vehicle.airspeed = 0.0;
    vehicle.climbRate = 0.0;
    vehicle.roll = 0.0;
    vehicle.pitch = 0.0;
    vehicle.throttlePercent = 0;
  }

  double _normalizeAngle(double angle) {
    while (angle > 180.0) {
      angle -= 360.0;
    }
    while (angle < -180.0) {
      angle += 360.0;
    }
    return angle;
  }
}
