import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lite_camera/flutter_lite_camera.dart';
import 'package:go_router/go_router.dart';

/// Motion Counter screen - counts motion crossing a virtual tripwire using camera.
class MotionCounterScreen extends StatefulWidget {
  const MotionCounterScreen({super.key});

  @override
  State<MotionCounterScreen> createState() => _MotionCounterScreenState();
}

class _MotionCounterScreenState extends State<MotionCounterScreen> {
  // Camera
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  String? _errorMessage;

  // State
  bool _isDetecting = false;
  int _counter = 0;
  double _tripwirePosition = 0.5; // 0.0 = left, 1.0 = right
  int _sensitivity = 30; // Motion sensitivity threshold (0-100)
  bool _showConfigView = true;
  DateTime? _startTime;
  
  // Motion detection
  Uint8List? _previousFrame;
  bool _motionDetectedInZone = false;
  double _currentMotionLevel = 0.0;
  
  // Lite Camera (Linux/Desktop)
  final _liteCamera = FlutterLiteCamera();
  List<String> _liteDevices = [];
  List<MapEntry<int, String>> _uniqueLiteDevices = [];
  Timer? _liteTimer; // For polling frames
  Uint8List? _liteFrameBytes; // RGB bytes
  int _liteWidth = 640;
  int _liteHeight = 480;
  ui.Image? _liteImage; // For display
  bool _isCapturing = false;
  bool _isSwitching = false;

  // Tripwire zone width as percentage of frame
  static const double _tripwireZoneWidth = 0.1; // 10% of frame width

  bool get _isDesktop => !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  @override
  void dispose() {
    if (_isDesktop) {
       _liteTimer?.cancel();
       _liteCamera.release();
    } else {
       _controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _initCameras() async {
    if (_isDesktop) {
      await _initLiteCamera();
    } else {
      await _initStandardCameras();
    }
  }

  Future<void> _initLiteCamera() async {
    try {
      _liteDevices = await _liteCamera.getDeviceList();
      debugPrint('MotionDetector (Lite): Found ${_liteDevices.length} devices: $_liteDevices');
      
      _uniqueLiteDevices = [];
      final seenNames = <String>{};
      for (int i = 0; i < _liteDevices.length; i++) {
        final name = _liteDevices[i];
        if (!seenNames.contains(name)) {
          seenNames.add(name);
          _uniqueLiteDevices.add(MapEntry(i, name));
        }
      }

      if (_uniqueLiteDevices.isEmpty) {
        // Fallback to simulated camera
        debugPrint('MotionDetector (Lite): No devices found. Using Simulated Camera.');
        _uniqueLiteDevices.add(const MapEntry(-1, 'Simulated Camera'));
      }
      
      // Auto-open first camera
      await _openLiteCamera(_uniqueLiteDevices.first.key);
    } catch (e) {
      debugPrint('MotionDetector (Lite): Init error: $e');
      setState(() => _errorMessage = 'Refusing to init camera: $e');
    }
  }

  Future<void> _openLiteCamera(int index) async {
    if (_isSwitching) return;
    _isSwitching = true;

    // Stop streaming immediately
    _liteTimer?.cancel();
    _liteTimer = null;
    
    // Force a hard wait to ensure any in-flight native capture calls return or fail
    // Native side might act faster than Dart's event loop, so we wait.
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Double check capture flag, though the delay above usually clears it
    int retries = 0;
    while (_isCapturing && retries < 20) {
      await Future.delayed(const Duration(milliseconds: 50));
      retries++;
    }

    try {
      if (_isInitialized) {
        debugPrint('MotionDetector (Lite): Releasing current camera...');
        setState(() => _isInitialized = false);
        await _liteCamera.release();
        debugPrint('MotionDetector (Lite): Camera released.');
        
        // Give native side time to fully close resource/file descriptors
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('MotionDetector (Lite): Warning releasing camera: $e');
    }

    try {
      debugPrint('MotionDetector (Lite): Opening camera $index...');
      if (index != -1) {
          await _liteCamera.open(index);
      }
      setState(() {
        _selectedCameraIndex = index;
        _isInitialized = true;
        _errorMessage = null;
      });
      debugPrint('MotionDetector (Lite): Camera $index opened');
      _startLiteStreaming();
    } catch (e) {
      debugPrint('MotionDetector (Lite): Error opening camera: $e');
      setState(() => _errorMessage = 'Failed to open camera: $e');
    } finally {
      _isSwitching = false;
    }
  }

  // Simulation helpers
  double _simX = 0;
  int _simDirection = 1;
  
  Map<String, dynamic> _generateSimulatedFrame() {
      // 640x480 simulation
      const width = 640;
      const height = 480;
      final bytes = Uint8List(width * height * 3);
      
      // Move a white block back and forth
      _simX += (_simDirection * 15);
      if (_simX > width - 100) _simDirection = -1;
      if (_simX < 0) _simDirection = 1;
      
      // Fill background (dark grey)
      for (int i = 0; i < bytes.length; i+=3) {
          bytes[i] = 20;
          bytes[i+1] = 20;
          bytes[i+2] = 20;
      }
      
      // Draw block
      final int startX = _simX.toInt();
      final int endX = (startX + 100).clamp(0, width);
      const int startY = 200;
      const int endY = 280;
      
      for (int y = startY; y < endY; y++) {
          for (int x = startX; x < endX; x++) {
              final int index = (y * width + x) * 3;
              if (index + 2 < bytes.length) {
                  bytes[index] = 255;
                  bytes[index+1] = 255;
                  bytes[index+2] = 255;
              }
          }
      }
      
      return {
          'width': width,
          'height': height,
          'data': bytes,
      };
  }

  void _startLiteStreaming() {
    _liteTimer?.cancel();
    _liteTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
       if (!mounted) {
         timer.cancel();
         return;
       }
       // If timer was cancelled externally (e.g. by switch), stop processing
       if (_liteTimer == null && timer.isActive) {
          timer.cancel();
          return;
       }
       
       if (_isCapturing) return; // Skip if previous capture still running
       
       _isCapturing = true;
       try {
         // check again before async call
         if (_isSwitching) return;
         
         Map<String, dynamic> frameData;
         
         if (_selectedCameraIndex == -1) {
            // Simulated Camera
            frameData = _generateSimulatedFrame();
            await Future.delayed(const Duration(milliseconds: 33)); // ~30fps
         } else {
            frameData = await _liteCamera.captureFrame();
         }
         
         // If we were disposed or de-initialized during capture, abort
         if (!_isInitialized || !mounted || _isSwitching) return;
         
         _processLiteFrame(frameData);
       } catch (e) {
         debugPrint('MotionDetector (Lite): Capture error: $e');
       } finally {
         _isCapturing = false;
       }
    });
  }

  Future<void> _initStandardCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMessage = 'No cameras available');
        return;
      }
      await _initController(_selectedCameraIndex);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize cameras: $e');
    }
  }

  Future<void> _initController(int cameraIndex) async {
    debugPrint('MotionDetector: Initializing controller for camera index $cameraIndex');
    if (_cameras.isEmpty) return;
    
    _controller?.dispose();
    
    final controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      debugPrint('MotionDetector: Controller initialized successfully');
      if (!mounted) return;
      
      setState(() {
        _controller = controller;
        _selectedCameraIndex = cameraIndex;
        _isInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('MotionDetector: Failed to initialize controller: $e');
      setState(() => _errorMessage = 'Failed to initialize camera: $e');
    }
  }

  void _startDetection() {
    if (_isDesktop) {
      if (!_isInitialized) return;
      setState(() {
        _isDetecting = true;
        _counter = 0;
        _startTime = DateTime.now();
        _previousFrame = null;
        _motionDetectedInZone = false;
      });
      return;
    }

    if (_controller == null || !_isInitialized) {
      debugPrint('MotionDetector: Detection failed - controller null or not initialized');
      return;
    }

    debugPrint('MotionDetector: Starting detection...');
    setState(() {
      _isDetecting = true;
      _counter = 0;
      _startTime = DateTime.now();
      _previousFrame = null;
      _motionDetectedInZone = false;
    });

    try {
      _controller!.startImageStream((CameraImage image) {
        if (!_isDetecting) return;
        _processFrame(image);
      });
      debugPrint('MotionDetector: Image stream started successfully');
    } catch (e) {
      debugPrint('MotionDetector: Failed to start image stream: $e');
      setState(() => _errorMessage = 'Failed to start detection: $e');
    }
  }

  void _stopDetection() {
    debugPrint('MotionDetector: Stopping detection');
    if (_isDesktop) {
      // Just stop logic, keep streaming preview
    } else {
      try {
        _controller?.stopImageStream();
      } catch (e) {
        debugPrint('MotionDetector: Error stopping stream: $e');
      }
    }
    setState(() {
      _isDetecting = false;
    });
  }

  void _processLiteFrame(Map<String, dynamic> frameData) {
    try {
      final int width = frameData['width'] as int;
      final int height = frameData['height'] as int;
      final Uint8List rgbData = frameData['data'] as Uint8List;
      
      if (_liteWidth != width || _liteHeight != height) {
        _liteWidth = width;
        _liteHeight = height;
      }

      // Always process for display (Preview)
      final rgba = Uint8List(width * height * 4);
      for (int i = 0, j = 0; i < rgbData.length; i += 3, j += 4) {
         if (j + 3 < rgba.length) {
            rgba[j] = rgbData[i];     // R
            rgba[j+1] = rgbData[i+1]; // G
            rgba[j+2] = rgbData[i+2]; // B
            rgba[j+3] = 255;          // A
         }
      }
      
      ui.decodeImageFromPixels(
        rgba, 
        width, 
        height, 
        ui.PixelFormat.rgba8888, 
        (image) {
          if (mounted) {
            setState(() {
               _liteImage = image;
            });
          }
        }
      );

      // Only process motion if detecting
      if (_isDetecting) {
        final grayscale = Uint8List(width * height);
        for (int i = 0, j = 0; i < rgbData.length; i += 3, j++) {
           if (j < grayscale.length) { 
             grayscale[j] = ((rgbData[i] + rgbData[i+1] + rgbData[i+2]) ~/ 3);
           }
        }
        _performMotionLogic(grayscale, width, height);
      } else {
        // Clear motion level if not detecting
        if (_currentMotionLevel != 0.0 && mounted) {
           setState(() => _currentMotionLevel = 0.0);
        }
      }

    } catch (e, stack) {
      debugPrint('MotionDetector (Lite): Process error: $e\n$stack');
    }
  }

  void _performMotionLogic(Uint8List currentFrame, int width, int height) {
    if (_previousFrame == null || _previousFrame!.length != currentFrame.length) {
      _previousFrame = Uint8List.fromList(currentFrame);
      return;
    }

    // Logic from original _processFrame, extracted
    final int zoneStart = (((_tripwirePosition - _tripwireZoneWidth / 2) * width).clamp(0, width - 1)).toInt();
    final int zoneEnd = (((_tripwirePosition + _tripwireZoneWidth / 2) * width).clamp(0, width - 1)).toInt();
    
    int motionPixels = 0;
    int totalPixels = 0;
    
    for (int y = 0; y < height; y++) {
      for (int x = zoneStart; x < zoneEnd; x++) {
        final int index = y * width + x;
        if (index < currentFrame.length && index < _previousFrame!.length) {
          final int diff = (currentFrame[index] - _previousFrame![index]).abs();
          if (diff > _sensitivity) {
            motionPixels++;
          }
          totalPixels++;
        }
      }
    }

    final double motionLevel = totalPixels > 0 ? motionPixels / totalPixels : 0;
    
    if (mounted) {
      setState(() {
        _currentMotionLevel = motionLevel;
      });
    }

    final bool motionNow = motionLevel > 0.05;
    
    if (motionNow && !_motionDetectedInZone) {
      _motionDetectedInZone = true;
    } else if (!motionNow && _motionDetectedInZone) {
      _motionDetectedInZone = false;
      if (mounted) {
        setState(() {
          _counter++;
        });
        debugPrint('🚶 Motion detected! Count: $_counter');
      }
    }

    _previousFrame = Uint8List.fromList(currentFrame);
  }

  void _processFrame(CameraImage image) {
    if (image.planes.isEmpty) return;
    
    // YUV Y plane is usually at index 0
    final Uint8List currentFrame = image.planes[0].bytes;
    _performMotionLogic(currentFrame, image.width, image.height);
  }


  void _resetCounter() {
    setState(() {
      _counter = 0;
      _startTime = DateTime.now();
    });
  }

  void _toggleView() {
    setState(() {
      _showConfigView = !_showConfigView;
    });
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;
    final newIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initController(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _stopDetection();
            context.go('/');
          },
        ),
        title: const Text('Motion Counter'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              tooltip: 'Switch Camera',
              onPressed: _isDetecting ? null : _switchCamera,
            ),
          IconButton(
            icon: Icon(_showConfigView ? Icons.fullscreen : Icons.settings),
            tooltip: _showConfigView ? 'Counter Only' : 'Show Settings',
            onPressed: _toggleView,
          ),
        ],
      ),
      body: _showConfigView
          ? _buildConfigView(theme, colorScheme)
          : _buildCounterOnlyView(theme, colorScheme),
    );
  }

  Widget _buildCameraPreview({bool showTripwire = true, double? height}) {
    Widget preview;
    if (_isDesktop) {
       if (_liteImage != null) {
          preview = RawImage(
             image: _liteImage,
             width: _liteWidth.toDouble(),
             height: _liteHeight.toDouble(),
             fit: BoxFit.contain,
          );
       } else {
          preview = Container(
             color: Colors.black,
             child: const Center(child: Text('Waiting for camera...', style: TextStyle(color: Colors.white))),
          );
       }
    } else {
       if (!_isInitialized || _controller == null) {
          preview = Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
       } else {
          preview = CameraPreview(_controller!);
       }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
         height: height,
         color: Colors.black,
         child: Stack(
          fit: StackFit.expand,
          children: [
            preview,
            if (showTripwire)
              CustomPaint(
                painter: TripwirePainter(
                  position: _tripwirePosition,
                  zoneWidth: _tripwireZoneWidth,
                  motionLevel: _currentMotionLevel,
                  isActive: _isDetecting,
                ),
              ),
          ],
         ),
      ),
    );
  }

  Widget _buildCounterOnlyView(ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _resetCounter,
      onDoubleTap: _toggleView,
      child: Column(
        children: [
          // Camera preview takes most of the space
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCameraPreview(showTripwire: true),
            ),
          ),
          // Counter display
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_counter',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'crossings',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_isDetecting && _startTime != null) ...[
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      final elapsed = DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;
                      final rate = elapsed > 0 ? _counter / elapsed : 0.0;
                      return Text(
                        '${rate.toStringAsFixed(2)} / sec',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isDetecting ? _stopDetection : _startDetection,
                    icon: Icon(_isDetecting ? Icons.stop : Icons.play_arrow),
                    label: Text(_isDetecting ? 'Stop' : 'Start'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: _isDetecting ? colorScheme.error : colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigView(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Error message
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: colorScheme.onErrorContainer, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Camera Preview - Takes remaining space
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCameraPreview(showTripwire: true),
          ),
        ),

        // Config Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_counter',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('crossings', style: theme.textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 16),

              // Settings Row (Tripwire & Sensitivity)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('TRIPWIRE: ${(_tripwirePosition * 100).toInt()}%', 
                           style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                         SizedBox(
                           height: 30, 
                           child: Slider(
                            value: _tripwirePosition,
                            min: 0.1,
                            max: 0.9,
                            divisions: 100,
                            onChanged: _isDetecting ? null : (v) => setState(() => _tripwirePosition = v),
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('SENSITIVITY: $_sensitivity', 
                           style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                         SizedBox(
                           height: 30,
                           child: Slider(
                            value: _sensitivity.toDouble(),
                            min: 5,
                            max: 100,
                            divisions: 95,
                            onChanged: _isDetecting ? null : (v) => setState(() => _sensitivity = v.toInt()),
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 8),

              // Camera Selection & Start Button Row
              Row(
                children: [
                  if ((_isDesktop && _uniqueLiteDevices.length > 1) || (!_isDesktop && _cameras.length > 1))
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _selectedCameraIndex,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          labelText: 'Camera',
                        ),
                        items: _isDesktop 
                            ? _uniqueLiteDevices.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    entry.value.isEmpty ? 'Camera ${entry.key + 1}' : entry.value,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList()
                            : _cameras.asMap().entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    entry.value.name.isEmpty ? 'Camera ${entry.key + 1}' : entry.value.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                        onChanged: _isDetecting
                            ? null
                            : (index) {
                                if (index != null) {
                                  if (_isDesktop) {
                                    _openLiteCamera(index);
                                  } else {
                                    _initController(index);
                                  }
                                }
                              },
                      ),
                    )
                  else
                    const Spacer(),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _isInitialized 
                            ? (_isDetecting ? _stopDetection : _startDetection)
                            : null,
                        icon: Icon(_isDetecting ? Icons.stop : Icons.play_arrow),
                        label: Text(_isDetecting ? 'Stop' : 'Start'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _isDetecting ? colorScheme.error : colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

}

/// Custom painter for the tripwire visualization
class TripwirePainter extends CustomPainter {
  final double position;
  final double zoneWidth;
  final double motionLevel;
  final bool isActive;

  TripwirePainter({
    required this.position,
    required this.zoneWidth,
    required this.motionLevel,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double x = size.width * position;
    final double zonePixelWidth = size.width * zoneWidth;

    // Draw zone background
    final zonePaint = Paint()
      ..color = isActive 
          ? (motionLevel > 0.05 ? Colors.green.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.2))
          : Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(x - zonePixelWidth / 2, 0, zonePixelWidth, size.height),
      zonePaint,
    );

    // Draw tripwire line
    final linePaint = Paint()
      ..color = isActive 
          ? (motionLevel > 0.05 ? Colors.green : Colors.blue)
          : Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      linePaint,
    );

    // Draw arrows indicating direction
    final arrowPaint = Paint()
      ..color = linePaint.color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final arrowSize = 15.0;
    final arrowY = size.height / 2;

    // Left arrow
    canvas.drawLine(
      Offset(x - 20, arrowY),
      Offset(x - 20 - arrowSize, arrowY - arrowSize / 2),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(x - 20, arrowY),
      Offset(x - 20 - arrowSize, arrowY + arrowSize / 2),
      arrowPaint,
    );

    // Right arrow
    canvas.drawLine(
      Offset(x + 20, arrowY),
      Offset(x + 20 + arrowSize, arrowY - arrowSize / 2),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(x + 20, arrowY),
      Offset(x + 20 + arrowSize, arrowY + arrowSize / 2),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TripwirePainter oldDelegate) {
    return position != oldDelegate.position ||
        zoneWidth != oldDelegate.zoneWidth ||
        motionLevel != oldDelegate.motionLevel ||
        isActive != oldDelegate.isActive;
  }
}
