import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle_state.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';

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

  // FPS Tracking
  int _frameCount = 0;
  DateTime _lastFpsCheck = DateTime.now();
  Timer? _reconnectTimer;

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
    _reconnectTimer?.cancel();
    super.dispose();
  }

  void _stopStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
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
            context.read<VehicleState>().setCameraStatus('Invalid URL', isConnected: false);
          }
        });
      }
      return;
    }

    try {
      _httpClient = http.Client();
      final uri = Uri.parse(cleanUrl);
      final request = http.Request('GET', uri);
      final response = await _httpClient!.send(request).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        throw Exception('HTTP Status ${response.statusCode}');
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

          // Find JPEG Start of Image (SOI) and End of Image (EOI)
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
            }
          }

          // Buffer safety limit
          if (buffer.length > 5000000) {
            buffer.clear();
          }
        },
        onError: (error) {
          _handleStreamError(error.toString());
        },
        onDone: () {
          _handleStreamError('Stream ended');
        },
        cancelOnError: true,
      );
    } catch (e) {
      _handleStreamError(e.toString());
    }
  }

  void _handleStreamError(String error) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vehicle = context.read<VehicleState>();
        vehicle.setCameraStatus('DISCONNECTED', isConnected: false);
        vehicle.setCameraFps(0.0);
      }
    });

    // Auto retry after 3 seconds
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final isSimulated = context.read<VehicleState>().isUsingSimulatedCamera;
        if (!isSimulated) {
          _startStream();
        }
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
      );
    }

    // Clean, minimal connecting view without visual clutter
    return Container(
      color: const Color(0xFF090C10),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(GcsColors.cyanAccent),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'CONNECTING...',
              style: TextStyle(
                color: GcsColors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
