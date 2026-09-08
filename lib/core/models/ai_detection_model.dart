import 'package:flutter/material.dart';

enum TargetCategory {
  aircraft,
  vehicle,
  personnel,
  helipad,
  structure,
  hazard,
}

class DetectedObject {
  final String id;
  final String label;
  final double confidence; // 0.0 - 1.0
  final Rect normalizedRect; // 0.0 - 1.0 coordinates relative to camera frame
  final TargetCategory category;
  final double distanceMeters;
  final double velocityKmh;
  final Color color;

  const DetectedObject({
    required this.id,
    required this.label,
    required this.confidence,
    required this.normalizedRect,
    required this.category,
    required this.distanceMeters,
    this.velocityKmh = 0.0,
    required this.color,
  });

  DetectedObject copyWith({
    String? id,
    String? label,
    double? confidence,
    Rect? normalizedRect,
    TargetCategory? category,
    double? distanceMeters,
    double? velocityKmh,
    Color? color,
  }) {
    return DetectedObject(
      id: id ?? this.id,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      normalizedRect: normalizedRect ?? this.normalizedRect,
      category: category ?? this.category,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      velocityKmh: velocityKmh ?? this.velocityKmh,
      color: color ?? this.color,
    );
  }
}
