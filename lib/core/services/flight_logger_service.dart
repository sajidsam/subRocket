import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/log_entry.dart';
import '../models/vehicle_state.dart';

class FlightLoggerService extends ChangeNotifier {
  final VehicleState vehicle;
  Timer? _recordTimer;

  final List<FlightLogSession> recordedSessions = [];
  FlightLogSession? activeSession;
  bool isRecording = false;

  // Playback state
  bool isReplaying = false;
  int playbackIndex = 0;
  double playbackSpeedMultiplier = 1.0;
  Timer? _playbackTimer;

  FlightLoggerService({required this.vehicle}) {
    _createInitialSampleSession();
    // Auto-record telemetry at 4Hz (250ms interval)
    _startRecordingTimer();
  }

  void _startRecordingTimer() {
    _recordTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (vehicle.isConnected) {
        _captureFrame();
      }
    });
  }

  void _captureFrame() {
    if (activeSession == null) {
      final now = DateTime.now();
      activeSession = FlightLogSession(
        id: 'LOG_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}${now.second}',
        title: 'Mission #${recordedSessions.length + 1} (${vehicle.connectionType})',
        startTime: now,
        endTime: now,
      );
      recordedSessions.insert(0, activeSession!);
    }

    final frame = TelemetryFrame(
      timestamp: DateTime.now(),
      altitude: vehicle.altitudeAgl,
      groundspeed: vehicle.groundspeed,
      airspeed: vehicle.airspeed,
      verticalSpeed: vehicle.climbRate,
      pitch: vehicle.pitch,
      roll: vehicle.roll,
      yaw: vehicle.yaw,
      batteryVoltage: vehicle.batteryVoltage,
      batteryCurrent: vehicle.batteryCurrent,
      batteryRemaining: vehicle.batteryRemaining,
      lat: vehicle.currentLocation?.latitude ?? 23.8103,
      lon: vehicle.currentLocation?.longitude ?? 90.4125,
      throttlePercent: vehicle.throttlePercent,
      flightMode: vehicle.mode.name,
      isArmed: vehicle.isArmed,
      vibeX: vehicle.vibeX,
      vibeY: vehicle.vibeY,
      vibeZ: vehicle.vibeZ,
    );

    activeSession?.frames.add(frame);
    activeSession?.endTime = DateTime.now();

    if (vehicle.altitudeAgl > (activeSession?.maxAltitude ?? 0)) {
      activeSession?.maxAltitude = vehicle.altitudeAgl;
    }
    if (vehicle.groundspeed > (activeSession?.maxSpeed ?? 0)) {
      activeSession?.maxSpeed = vehicle.groundspeed;
    }

    // Keep session frames capped to prevent memory exhaustion in long tests
    if ((activeSession?.frames.length ?? 0) > 5000) {
      activeSession?.frames.removeAt(0);
    }
    notifyListeners();
  }

  void startNewSession(String title) {
    final now = DateTime.now();
    activeSession = FlightLogSession(
      id: 'LOG_${now.millisecondsSinceEpoch}',
      title: title,
      startTime: now,
      endTime: now,
    );
    recordedSessions.insert(0, activeSession!);
    notifyListeners();
  }

  // --- Replay Controls ---

  void startPlayback(FlightLogSession session) {
    if (session.frames.isEmpty) return;
    isReplaying = true;
    playbackIndex = 0;
    _playbackTimer?.cancel();

    _playbackTimer = Timer.periodic(
      Duration(milliseconds: (250 / playbackSpeedMultiplier).round()),
      (timer) {
        if (playbackIndex < session.frames.length - 1) {
          playbackIndex++;
          final f = session.frames[playbackIndex];
          // Inject replay telemetry into vehicle view
          vehicle.altitudeAgl = f.altitude;
          vehicle.groundspeed = f.groundspeed;
          vehicle.climbRate = f.verticalSpeed;
          vehicle.pitch = f.pitch;
          vehicle.roll = f.roll;
          vehicle.yaw = f.yaw;
          vehicle.batteryVoltage = f.batteryVoltage;
          vehicle.batteryRemaining = f.batteryRemaining;
          vehicle.currentLocation = LatLng(f.lat, f.lon);
          notifyListeners();
        } else {
          stopPlayback();
        }
      },
    );
    notifyListeners();
  }

  void seekPlayback(FlightLogSession session, double progressFraction) {
    if (session.frames.isEmpty) return;
    playbackIndex = ((session.frames.length - 1) * progressFraction.clamp(0.0, 1.0)).round();
    final f = session.frames[playbackIndex];
    vehicle.altitudeAgl = f.altitude;
    vehicle.groundspeed = f.groundspeed;
    vehicle.pitch = f.pitch;
    vehicle.roll = f.roll;
    vehicle.yaw = f.yaw;
    vehicle.currentLocation = LatLng(f.lat, f.lon);
    notifyListeners();
  }

  void setPlaybackSpeed(double speed) {
    playbackSpeedMultiplier = speed;
    if (isReplaying && activeSession != null) {
      startPlayback(activeSession!);
    }
    notifyListeners();
  }

  void stopPlayback() {
    isReplaying = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    notifyListeners();
  }

  void _createInitialSampleSession() {
    final now = DateTime.now().subtract(const Duration(minutes: 25));
    final sample = FlightLogSession(
      id: 'LOG_DEMO_01',
      title: 'Demo Flight #1 (Autonomous Waypoint Mission)',
      startTime: now,
      endTime: now.add(const Duration(minutes: 12, seconds: 40)),
      maxAltitude: 85.4,
      maxSpeed: 22.1,
      totalDistance: 3240.0,
    );

    // Generate sample trajectory
    for (int i = 0; i < 60; i++) {
      final t = now.add(Duration(seconds: i * 12));
      final progress = i / 60.0;
      final alt = (sin(progress * 3.14159) * 85.0).clamp(0.0, 85.4);
      final speed = (progress < 0.1 || progress > 0.9) ? 4.0 : 18.0 + sin(progress * 10) * 3.0;

      sample.frames.add(TelemetryFrame(
        timestamp: t,
        altitude: alt,
        groundspeed: speed,
        airspeed: speed + 1.1,
        verticalSpeed: (alt > 20 && progress < 0.5) ? 2.5 : -1.8,
        pitch: -5.0 + sin(progress * 8) * 3.0,
        roll: sin(progress * 6) * 15.0,
        yaw: (progress * 360.0) % 360,
        batteryVoltage: (16.8 - (progress * 2.2)),
        batteryCurrent: 14.5 + sin(progress * 4) * 3.0,
        batteryRemaining: (100 - (progress * 45)).toInt(),
        lat: 23.8103 + (sin(progress * 3.14) * 0.005),
        lon: 90.4125 + (cos(progress * 3.14) * 0.005),
        throttlePercent: 65,
        flightMode: progress < 0.1 ? 'TAKEOFF' : (progress > 0.85 ? 'RTL' : 'AUTO'),
        isArmed: true,
      ));
    }
    recordedSessions.add(sample);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }
}
