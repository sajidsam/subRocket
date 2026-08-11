import 'package:flutter/foundation.dart';

/// GCS Audio / Voice Synthesizer & Alarm System
class SpeechService {
  bool isAudioEnabled = true;
  DateTime? _lastAlertTime;

  void announce(String message) {
    if (!isAudioEnabled) return;
    debugPrint('[GCS AUDIO ANNOUNCER]: $message');
    // Web and native speech synthesis dispatch placeholder (safely logs without throwing)
  }

  void playAlarm({required String reason, bool isCritical = false}) {
    if (!isAudioEnabled) return;
    final now = DateTime.now();
    if (_lastAlertTime != null && now.difference(_lastAlertTime!).inSeconds < 2) {
      return; // prevent alarm flood
    }
    _lastAlertTime = now;
    debugPrint('[GCS ALARM] ${isCritical ? "CRITICAL ALARM" : "WARNING"}: $reason');
  }

  void announceModeChange(String modeName) {
    announce('Mode $modeName');
  }

  void announceArmed() {
    announce('Warning: Vehicle Armed');
  }

  void announceDisarmed() {
    announce('Vehicle Disarmed');
  }

  void announceWaypoint(int index, double distance) {
    announce('Waypoint $index reached');
  }

  void announceLowBattery(int percent) {
    playAlarm(reason: 'Low Battery $percent percent', isCritical: percent <= 15);
  }
}
