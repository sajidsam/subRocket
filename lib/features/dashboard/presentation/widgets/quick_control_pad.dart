import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/mavlink_service.dart';

class QuickControlPad extends StatefulWidget {
  const QuickControlPad({super.key});

  @override
  State<QuickControlPad> createState() => _QuickControlPadState();
}

class _QuickControlPadState extends State<QuickControlPad> {
  bool _showJoysticks = false;
  Offset _leftStick = Offset.zero;
  Offset _rightStick = Offset.zero;

  void _updateJoysticks(BuildContext context) {
    final mavlink = context.read<MavlinkService>();
    final throttle = -(_leftStick.dy / 50.0).clamp(-1.0, 1.0);
    final yaw = (_leftStick.dx / 50.0).clamp(-1.0, 1.0);
    final pitch = (_rightStick.dy / 50.0).clamp(-1.0, 1.0);
    final roll = (_rightStick.dx / 50.0).clamp(-1.0, 1.0);

    mavlink.simulator.setManualInputs(
      throttle: throttle,
      pitch: pitch,
      roll: roll,
      yaw: yaw,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Joystick Toggle Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _showJoysticks ? GcsColors.techAmber : GcsColors.surfaceDark,
            foregroundColor: _showJoysticks ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: Icon(_showJoysticks ? Icons.gamepad : Icons.sports_esports, size: 16),
          label: Text(_showJoysticks ? 'HIDE JOYSTICK' : 'VIRTUAL JOYSTICK', style: const TextStyle(fontSize: 11)),
          onPressed: () => setState(() => _showJoysticks = !_showJoysticks),
        ),
        const SizedBox(height: 8),

        // Dual Virtual Joysticks Overlay
        if (_showJoysticks)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GcsColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left Stick (Throttle / Yaw)
                Column(
                  children: [
                    const Text('THROTTLE / YAW', style: TextStyle(fontSize: 9, color: GcsColors.textSecondary, fontFamily: 'monospace')),
                    const SizedBox(height: 6),
                    _buildStickPad(
                      position: _leftStick,
                      onPanUpdate: (d) => setState(() {
                        _leftStick += d.delta;
                        _updateJoysticks(context);
                      }),
                      onPanEnd: (d) => setState(() {
                        _leftStick = Offset(0, _leftStick.dy);
                        _updateJoysticks(context);
                      }),
                    ),
                  ],
                ),
                const SizedBox(width: 24),

                // Right Stick (Pitch / Roll)
                Column(
                  children: [
                    const Text('PITCH / ROLL', style: TextStyle(fontSize: 9, color: GcsColors.textSecondary, fontFamily: 'monospace')),
                    const SizedBox(height: 6),
                    _buildStickPad(
                      position: _rightStick,
                      onPanUpdate: (d) => setState(() {
                        _rightStick += d.delta;
                        _updateJoysticks(context);
                      }),
                      onPanEnd: (d) => setState(() {
                        _rightStick = Offset.zero;
                        _updateJoysticks(context);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStickPad({
    required Offset position,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: GcsColors.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Transform.translate(
            offset: Offset(position.dx.clamp(-40.0, 40.0), position.dy.clamp(-40.0, 40.0)),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: GcsColors.techAmber,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
