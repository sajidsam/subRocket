import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/real_ai_detector_service.dart';

class IpWebcamStreamView extends StatefulWidget {
  final String streamUrl;
  final BoxFit fit;

  const IpWebcamStreamView({
    super.key,
    required this.streamUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<IpWebcamStreamView> createState() => _IpWebcamStreamViewState();
}

class _IpWebcamStreamViewState extends State<IpWebcamStreamView> {
  Uint8List? _currentFrame;
  bool _isLoading = true;
  bool _hasError = false;
  http.Client? _httpClient;
  StreamSubscription<List<int>>? _streamSubscription;
  Timer? _pollingTimer;

  // FPS Tracking
  int _frameCount = 0;
  DateTime _lastFpsCheck = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void didUpdateWidget(covariant IpWebcamStreamView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _stopStream();
      _startStream();
    }
  }

  @override
  void dispose() {
    _stopStream();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _stopStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _httpClient?.close();
    _httpClient = null;
  }

  Future<void> _startStream() async {
    _stopStream();
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VehicleState>().setCameraStatus('CONNECTING...', isConnected: false);
      }
    });

    final cleanUrl = widget.streamUrl.trim();
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<VehicleState>().setCameraStatus('OFFLINE', isConnected: false);
          }
        });
      }
      return;
    }

    final uri = Uri.parse(cleanUrl);
    final isSnapshotEndpoint = cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.contains('shot.jpg') ||
        cleanUrl.contains('snapshot') ||
        cleanUrl.contains('capture');

    if (isSnapshotEndpoint) {
      _startSnapshotPolling(uri);
    } else {
      _startMjpegStream(uri);
    }
  }

  Future<void> _startSnapshotPolling(Uri uri) async {
    _httpClient = http.Client();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 66), (timer) async {
      if (!mounted) return;
      try {
        final res = await _httpClient!.get(uri).timeout(const Duration(seconds: 2));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          if (mounted) {
            setState(() {
              _currentFrame = res.bodyBytes;
              _isLoading = false;
              _hasError = false;
            });
            _trackFps();
            context.read<VehicleState>().setCameraStatus('ONLINE', isConnected: true);
            RealAiDetectorService.instance.processFrame(res.bodyBytes);
          }
        }
      } catch (e) {
        if (mounted && _currentFrame == null) {
          _handleStreamError();
        }
      }
    });
  }

  Future<void> _startMjpegStream(Uri uri) async {
    try {
      _httpClient = http.Client();
      final request = http.Request('GET', uri);
      final response = await _httpClient!.send(request).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        throw Exception('HTTP Status ${response.statusCode}');
      }

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.startsWith('image/')) {
        final bytes = await response.stream.toBytes();
        if (mounted) {
          setState(() {
            _currentFrame = bytes;
            _isLoading = false;
            _hasError = false;
          });
          context.read<VehicleState>().setCameraStatus('ONLINE', isConnected: true);
        }
        _startSnapshotPolling(uri);
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<VehicleState>().setCameraStatus('ONLINE', isConnected: true);
        }
      });

      final List<int> buffer = [];
      const int soi1 = 0xFF;
      const int soi2 = 0xD8;
      const int eoi1 = 0xFF;
      const int eoi2 = 0xD9;

      _streamSubscription = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);

          int startIdx = -1;
          for (int i = 0; i < buffer.length - 1; i++) {
            if (buffer[i] == soi1 && buffer[i + 1] == soi2) {
              startIdx = i;
              break;
            }
          }

          if (startIdx != -1) {
            int endIdx = -1;
            for (int i = startIdx + 2; i < buffer.length - 1; i++) {
              if (buffer[i] == eoi1 && buffer[i + 1] == eoi2) {
                endIdx = i + 2;
                break;
              }
            }

            if (endIdx != -1) {
              final frameBytes = Uint8List.fromList(buffer.sublist(startIdx, endIdx));
              buffer.removeRange(0, endIdx);

              if (mounted) {
                setState(() {
                  _currentFrame = frameBytes;
                  _isLoading = false;
                  _hasError = false;
                });
                _trackFps();
                RealAiDetectorService.instance.processFrame(frameBytes);
              }
            }
          }

          if (buffer.length > 5000000) {
            buffer.clear();
          }
        },
        onError: (_) {
          _handleStreamError();
        },
        onDone: () {
          _handleStreamError();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _handleStreamError();
    }
  }

  void _trackFps() {
    _frameCount++;
    final now = DateTime.now();
    final diff = now.difference(_lastFpsCheck).inMilliseconds;
    if (diff >= 1000) {
      final fps = (_frameCount * 1000.0) / diff;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<VehicleState>().setCameraFps(fps);
        }
      });
      _frameCount = 0;
      _lastFpsCheck = now;
    }
  }

  void _handleStreamError() {
    if (!mounted) return;

    setState(() {
      _hasError = true;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vehicle = context.read<VehicleState>();
        vehicle.setCameraStatus('OFFLINE', isConnected: false);
        vehicle.setCameraFps(0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentFrame != null && !_hasError) {
      return Image.memory(
        _currentFrame!,
        fit: widget.fit,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildStandbyPlaceholder();
        },
      );
    }

    return _buildStandbyPlaceholder();
  }

  Widget _buildStandbyPlaceholder() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startStream,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Static Mountain Landscape Image Background
          const CustomPaint(
            painter: MountainLandscapePainter(),
          ),

          // 2. Bouncy Ball Loader when Connecting
          if (_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFA7B35).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA7B35).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const BouncyBallLoader(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bouncy Ball Loader with 3 animated bouncing dots
class BouncyBallLoader extends StatefulWidget {
  final Color color;
  final double dotSize;

  const BouncyBallLoader({
    super.key,
    this.color = const Color(0xFFFA7B35),
    this.dotSize = 9.0,
  });

  @override
  State<BouncyBallLoader> createState() => _BouncyBallLoaderState();
}

class _BouncyBallLoaderState extends State<BouncyBallLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final double offset = math.sin((_controller.value * 2 * math.pi) + (index * 0.8));
            final double bounceY = -offset.clamp(0.0, 1.0) * 10.0;
            final double scale = 0.8 + (offset.clamp(0.0, 1.0) * 0.35);

            return Transform.translate(
              offset: Offset(0, bounceY),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Alpine Mountain View Static Background Landscape Painter
class MountainLandscapePainter extends CustomPainter {
  const MountainLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Sky Gradient with soft daylight glow
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF9AB2C5), // Crisp sky blue
        const Color(0xFFC7D7E2), // Pale misty horizon
        const Color(0xFF8294A2), // Soft mountain haze
      ],
      stops: const [0.0, 0.45, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = skyGradient.createShader(rect));

    // Far Distant Mountains
    final farMountainPath = Path();
    farMountainPath.moveTo(0, size.height * 0.6);
    farMountainPath.lineTo(size.width * 0.2, size.height * 0.42);
    farMountainPath.lineTo(size.width * 0.4, size.height * 0.48);
    farMountainPath.lineTo(size.width * 0.55, size.height * 0.38);
    farMountainPath.lineTo(size.width * 0.75, size.height * 0.45);
    farMountainPath.lineTo(size.width, size.height * 0.55);
    farMountainPath.lineTo(size.width, size.height);
    farMountainPath.lineTo(0, size.height);
    farMountainPath.close();

    canvas.drawPath(
      farMountainPath,
      Paint()
        ..color = const Color(0xFF6B7F91).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );

    // Dramatic Sharp Alpine Ridge Peak (Right side & Valley)
    final ridgePath = Path();
    ridgePath.moveTo(size.width * 0.35, size.height);
    ridgePath.lineTo(size.width * 0.45, size.height * 0.55);
    ridgePath.lineTo(size.width * 0.58, size.height * 0.65);
    ridgePath.lineTo(size.width * 0.68, size.height * 0.36); // Sharp peak
    ridgePath.lineTo(size.width * 0.74, size.height * 0.42);
    ridgePath.lineTo(size.width * 0.82, size.height * 0.28); // Highest peak
    ridgePath.lineTo(size.width * 0.92, size.height * 0.45);
    ridgePath.lineTo(size.width, size.height * 0.38);
    ridgePath.lineTo(size.width, size.height);
    ridgePath.close();

    final ridgeGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF8B7765), // Sunlit rock
        const Color(0xFF4A423B), // Shadowed crag
        const Color(0xFF2C2723), // Deep ravine
      ],
    );
    canvas.drawPath(
      ridgePath,
      Paint()
        ..shader = ridgeGradient.createShader(rect)
        ..style = PaintingStyle.fill,
    );

    // Left Foreground Crags
    final leftCrag = Path();
    leftCrag.moveTo(0, size.height);
    leftCrag.lineTo(0, size.height * 0.5);
    leftCrag.lineTo(size.width * 0.18, size.height * 0.62);
    leftCrag.lineTo(size.width * 0.28, size.height * 0.75);
    leftCrag.lineTo(size.width * 0.4, size.height);
    leftCrag.close();

    canvas.drawPath(
      leftCrag,
      Paint()
        ..color = const Color(0xFF38322D)
        ..style = PaintingStyle.fill,
    );

    // Subtle lens vignette
    final vignette = RadialGradient(
      center: Alignment.center,
      radius: 1.1,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.4),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = vignette.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant MountainLandscapePainter oldDelegate) => false;
}
