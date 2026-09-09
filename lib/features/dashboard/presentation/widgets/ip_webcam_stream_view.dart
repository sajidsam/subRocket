import 'dart:async';
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
  String _errorMessage = 'CONNECTING...';
  http.Client? _httpClient;
  StreamSubscription<List<int>>? _streamSubscription;
  Timer? _pollingTimer;
  Timer? _reconnectTimer;

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
    _reconnectTimer?.cancel();
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
      _errorMessage = 'CONNECTING...';
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
          _errorMessage = 'ENTER VALID HTTP CAMERA URL';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<VehicleState>().setCameraStatus('Invalid URL', isConnected: false);
          }
        });
      }
      return;
    }

    // Determine if it's a still image snapshot endpoint or a continuous video stream
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
          _handleStreamError('Snapshot error: $e');
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
      // If server returned a single image instead of multipart stream
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
        // Switch to snapshot polling for continuous feed
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
                _trackFps();
                RealAiDetectorService.instance.processFrame(frameBytes);
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

  void _handleStreamError(String error) {
    if (!mounted) return;
    String readableMsg = 'DISCONNECTED / OFFLINE';
    if (error.contains('SocketException') || error.contains('Failed host lookup') || error.contains('OS Error')) {
      readableMsg = 'CANNOT REACH IP (CHECK SAME WI-FI)';
    } else if (error.contains('TimeoutException') || error.contains('timeout')) {
      readableMsg = 'CONNECTION TIMED OUT';
    } else if (error.contains('404')) {
      readableMsg = 'ENDPOINT 404 (TRY /shot.jpg OR /video)';
    } else if (error.contains('Connection refused')) {
      readableMsg = 'SERVER NOT STARTED ON PHONE (TAP START SERVER)';
    }

    setState(() {
      _hasError = true;
      _isLoading = false;
      _errorMessage = readableMsg;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vehicle = context.read<VehicleState>();
        vehicle.setCameraStatus(readableMsg, isConnected: false);
        vehicle.setCameraFps(0.0);
      }
    });

    // Auto retry after 3 seconds
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _startStream();
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
    return Container(
      color: const Color(0xFF090C10),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(GcsColors.cyanAccent),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'CONNECTING TO CAMERA...',
                  style: TextStyle(
                    color: GcsColors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.streamUrl,
                  style: const TextStyle(
                    color: GcsColors.textMuted,
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                  ),
                ),
              ] else ...[
                const Icon(Icons.videocam_off_outlined, color: GcsColors.warningOrange, size: 28),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: GcsColors.warningOrange,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.streamUrl,
                  style: const TextStyle(
                    color: GcsColors.textMuted,
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GcsColors.cyanAccent,
                    side: const BorderSide(color: GcsColors.cyanAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.refresh, size: 12),
                  label: const Text('RETRY LINK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: _startStream,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
