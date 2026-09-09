import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../features/dashboard/presentation/widgets/ai_detection_overlay.dart';

class RealAiDetectorService {
  static final RealAiDetectorService _instance = RealAiDetectorService._internal();
  static RealAiDetectorService get instance => _instance;
  RealAiDetectorService._internal();

  static const String serverUrl = 'http://127.0.0.1:5055';

  final ValueNotifier<List<AiDetectedTarget>> detectionsNotifier =
      ValueNotifier<List<AiDetectedTarget>>([]);
  final ValueNotifier<bool> isServerOnlineNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> inferenceMsNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<double> fpsNotifier = ValueNotifier<double>(0.0);

  bool _isProcessing = false;
  DateTime _lastFrameSent = DateTime.now();
  Process? _serverProcess;
  Timer? _healthCheckTimer;

  void start() {
    _checkServerHealth();
  }

  void stop() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    detectionsNotifier.value = [];
  }

  Future<bool> _checkServerHealth() async {
    try {
      final res = await http.get(Uri.parse('$serverUrl/health')).timeout(const Duration(seconds: 1));
      if (res.statusCode == 200) {
        isServerOnlineNotifier.value = true;
        return true;
      }
    } catch (_) {
      // Server not reachable, try to auto-launch local python daemon if on desktop
      _autoLaunchServerIfDesktop();
    }
    isServerOnlineNotifier.value = false;
    return false;
  }

  void _autoLaunchServerIfDesktop() async {
    if (_serverProcess != null) return;
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final scriptPath = 'ai_engine/server.py';
        if (File(scriptPath).existsSync()) {
          _serverProcess = await Process.start('py', [scriptPath], runInShell: true);
          _serverProcess?.stdout.transform(utf8.decoder).listen((_) {});
          _serverProcess?.stderr.transform(utf8.decoder).listen((_) {});
        }
      } catch (_) {}
    }
  }

  Future<void> processFrame(Uint8List frameBytes) async {
    if (_isProcessing) return;
    final now = DateTime.now();
    // Throttle to max ~25 FPS to prevent network/CPU overload
    if (now.difference(_lastFrameSent).inMilliseconds < 40) return;
    _lastFrameSent = now;
    _isProcessing = true;

    try {
      final uri = Uri.parse('$serverUrl/detect_frame');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/octet-stream'},
        body: frameBytes,
      ).timeout(const Duration(milliseconds: 500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          isServerOnlineNotifier.value = true;
          inferenceMsNotifier.value = (data['inference_ms'] as num?)?.toDouble() ?? 0.0;
          fpsNotifier.value = (data['fps'] as num?)?.toDouble() ?? 0.0;

          final rawList = data['detections'] as List<dynamic>? ?? [];
          final targets = <AiDetectedTarget>[];

          for (final item in rawList) {
            final id = item['id'] as String? ?? 'TRK-01';
            final label = item['label'] as String? ?? 'OBJECT';
            final confidence = (item['confidence'] as num?)?.toDouble() ?? 0.0;
            final catStr = item['category'] as String? ?? 'obstacle';
            final rectMap = item['normalized_rect'] as Map<String, dynamic>? ?? {};
            final dist = (item['distance_meters'] as num?)?.toDouble() ?? 20.0;
            final spd = (item['speed_kmh'] as num?)?.toDouble() ?? 0.0;

            final left = (rectMap['left'] as num?)?.toDouble() ?? 0.1;
            final top = (rectMap['top'] as num?)?.toDouble() ?? 0.1;
            final width = (rectMap['width'] as num?)?.toDouble() ?? 0.2;
            final height = (rectMap['height'] as num?)?.toDouble() ?? 0.2;

            AiTargetCategory cat = AiTargetCategory.obstacle;
            if (catStr == 'person') cat = AiTargetCategory.person;
            else if (catStr == 'vehicle') cat = AiTargetCategory.vehicle;
            else if (catStr == 'drone') cat = AiTargetCategory.drone;
            else if (catStr == 'landingPad') cat = AiTargetCategory.landingPad;

            targets.add(AiDetectedTarget(
              id: id,
              category: cat,
              label: label,
              confidence: confidence,
              baseDistanceMeters: dist,
              speedKmh: spd,
              normalizedRect: Rect.fromLTWH(left, top, width, height),
            ));
          }

          detectionsNotifier.value = targets;
        }
      }
    } catch (_) {
      // Graceful ignore when frame dropped
    } finally {
      _isProcessing = false;
    }
  }
}
