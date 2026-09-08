import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ai_detection_model.dart';
import '../presentation/theme/gcs_theme.dart';

class AiDetectorService {
  static const String modelName = 'YOLOv11-Aero Core';
  static const String modelArchitecture = 'Ultralytics YOLOv11x (Aerospace SOTA)';

  static List<DetectedObject> getDetections(double animValue) {
    // Dynamic positions based on subtle sinusoidal telemetry movement
    final double t = animValue * 2 * pi;

    // 1. Tactical Drone / UAV
    final double uavX = 0.62 + 0.04 * cos(t * 0.8);
    final double uavY = 0.22 + 0.03 * sin(t);
    final double uavDist = 185.0 + 10.0 * sin(t * 0.5);

    // 2. Ground Vehicle
    final double vehX = 0.28 + 0.02 * sin(t * 0.6);
    final double vehY = 0.68 + 0.015 * cos(t * 0.4);
    final double vehDist = 94.0 + 4.0 * cos(t * 0.3);

    // 3. Ground Crew / Personnel
    final double crewX = 0.18 + 0.01 * cos(t * 0.5);
    final double crewY = 0.58 + 0.01 * sin(t * 0.3);
    final double crewDist = 62.0;

    // 4. Helipad / Landing Zone
    const double padX = 0.74;
    const double padY = 0.72;
    const double padDist = 120.0;

    return [
      DetectedObject(
        id: 'TRK-01',
        label: 'DRONE [UAV]',
        confidence: 0.984 + 0.01 * sin(t),
        normalizedRect: Rect.fromLTWH(uavX, uavY, 0.11, 0.09),
        category: TargetCategory.aircraft,
        distanceMeters: uavDist,
        velocityKmh: 42.5,
        color: GcsColors.cyanAccent,
      ),
      DetectedObject(
        id: 'TRK-02',
        label: 'VEHICLE',
        confidence: 0.962 + 0.015 * cos(t),
        normalizedRect: Rect.fromLTWH(vehX, vehY, 0.14, 0.11),
        category: TargetCategory.vehicle,
        distanceMeters: vehDist,
        velocityKmh: 28.0,
        color: GcsColors.goldAccent,
      ),
      DetectedObject(
        id: 'TRK-03',
        label: 'CREW',
        confidence: 0.957,
        normalizedRect: Rect.fromLTWH(crewX, crewY, 0.07, 0.12),
        category: TargetCategory.personnel,
        distanceMeters: crewDist,
        velocityKmh: 3.2,
        color: GcsColors.greenActive,
      ),
      DetectedObject(
        id: 'TRK-04',
        label: 'HELIPAD / LZ',
        confidence: 0.991,
        normalizedRect: const Rect.fromLTWH(padX, padY, 0.16, 0.13),
        category: TargetCategory.helipad,
        distanceMeters: padDist,
        velocityKmh: 0.0,
        color: const Color(0xFF60A5FA),
      ),
    ];
  }
}
