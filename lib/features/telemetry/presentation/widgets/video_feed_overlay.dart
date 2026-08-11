import 'package:flutter/material.dart';

class VideoFeedOverlay extends StatefulWidget {
  const VideoFeedOverlay({super.key});

  @override
  State<VideoFeedOverlay> createState() => _VideoFeedOverlayState();
}

class _VideoFeedOverlayState extends State<VideoFeedOverlay> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      right: 170, // Placed left of the thruster
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isExpanded ? 400 : 200,
          height: _isExpanded ? 300 : 150,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            border: Border.all(color: Colors.greenAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, color: Colors.white54, size: 40),
                    SizedBox(height: 8),
                    Text('NO VIDEO SIGNAL', style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('RTSP STREAM', style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Icon(
                  _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
