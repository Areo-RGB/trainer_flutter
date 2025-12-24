import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

/// Sound Counter screen - counts sounds above a threshold using the microphone.
class SoundCounterScreen extends StatefulWidget {
  const SoundCounterScreen({super.key});

  @override
  State<SoundCounterScreen> createState() => _SoundCounterScreenState();
}

class _SoundCounterScreenState extends State<SoundCounterScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  // State
  bool _isListening = false;
  bool _hasPermission = false;
  int _counter = 0;
  double _currentAmplitude = -160.0; // dBFS, -160 is silence
  double _threshold = -30.0; // dBFS threshold
  bool _wasAboveThreshold = false;
  String? _errorMessage;
  bool _showConfigView = true; // Toggle between config and counter-only view
  DateTime? _startTime; // For calculating counts per second
  
  // Device selection
  List<InputDevice> _availableDevices = [];
  InputDevice? _selectedDevice;
  bool _loadingDevices = false;
  
  Timer? _amplitudeTimer;
  StreamSubscription<RecordState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _recorder.onStateChanged().listen((state) {
      if (mounted) {
        setState(() {
          _isListening = state == RecordState.record;
        });
      }
    });
  }

  @override
  void dispose() {
    _stopListening();
    _stateSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => _loadingDevices = true);
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Microphone permission denied';
          _hasPermission = false;
          _loadingDevices = false;
        });
        return;
      }
      setState(() => _hasPermission = true);
      
      final devices = await _recorder.listInputDevices();
      setState(() {
        _availableDevices = devices;
        _loadingDevices = false;
        if (_selectedDevice == null && devices.isNotEmpty) {
          _selectedDevice = devices.first;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load devices: $e';
        _loadingDevices = false;
      });
    }
  }

  Future<void> _startListening() async {
    setState(() => _errorMessage = null);
    
    if (!_hasPermission) {
      try {
        final hasPermission = await _recorder.hasPermission();
        if (!hasPermission) {
          setState(() {
            _errorMessage = 'Microphone permission denied';
            _hasPermission = false;
          });
          return;
        }
        setState(() => _hasPermission = true);
      } catch (e) {
        setState(() => _errorMessage = 'Permission error: $e');
        return;
      }
    }

    try {
      final config = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.wav,
        numChannels: 1,
        device: _selectedDevice,
      );
      
      await _recorder.start(config, path: '');
    } catch (e) {
      debugPrint('Recording start error: $e');
      setState(() => _errorMessage = 'Failed to start: $e');
      return;
    }

    setState(() {
      _isListening = true;
      _counter = 0;
      _wasAboveThreshold = false;
      _startTime = DateTime.now();
    });

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_isListening) return;
      
      try {
        final amplitude = await _recorder.getAmplitude();
        if (!mounted) return;
        
        final current = amplitude.current;
        setState(() {
          _currentAmplitude = current;
        });

        final isAboveThreshold = current >= _threshold;
        
        if (isAboveThreshold && !_wasAboveThreshold) {
          debugPrint('🔊 Sound detected! Amplitude: $current, Threshold: $_threshold');
          setState(() {
            _counter++;
            _wasAboveThreshold = true;
          });
        } else if (!isAboveThreshold && _wasAboveThreshold) {
          setState(() {
            _wasAboveThreshold = false;
          });
        }
      } catch (e) {
        debugPrint('Amplitude error: $e');
      }
    });
  }

  Future<void> _stopListening() async {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  void _toggleView() {
    setState(() {
      _showConfigView = !_showConfigView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final normalizedAmplitude = ((_currentAmplitude + 160) / 160).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _stopListening();
            context.go('/');
          },
        ),
        title: const Text('Sound Counter'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showConfigView ? Icons.fullscreen : Icons.settings),
            tooltip: _showConfigView ? 'Counter Only' : 'Show Settings',
            onPressed: _toggleView,
          ),
        ],
      ),
      body: _showConfigView 
          ? _buildConfigView(theme, colorScheme, normalizedAmplitude)
          : _buildCounterOnlyView(theme, colorScheme, normalizedAmplitude),
    );
  }

  Widget _buildCounterOnlyView(ThemeData theme, ColorScheme colorScheme, double normalizedAmplitude) {
    return GestureDetector(
      onTap: _resetCounter,
      onDoubleTap: _toggleView,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large counter
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: _isListening
                      ? colorScheme.primary.withValues(alpha: normalizedAmplitude)
                      : Colors.transparent,
                  width: 12,
                ),
                boxShadow: _isListening && _wasAboveThreshold
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$_counter',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'sounds',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            // Counts per second
            if (_isListening && _startTime != null) ...[
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final elapsed = DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;
                final rate = elapsed > 0 ? _counter / elapsed : 0.0;
                return Text(
                  '${rate.toStringAsFixed(2)} / sec',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
            ],
            const SizedBox(height: 48),
            // Minimal controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _isListening ? _stopListening : _startListening,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? 'Stop' : 'Start'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: _isListening
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to reset • Double-tap for settings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigView(ThemeData theme, ColorScheme colorScheme, double normalizedAmplitude) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Counter display
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: _isListening
                        ? colorScheme.primary.withValues(alpha: normalizedAmplitude)
                        : Colors.transparent,
                    width: 8,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_counter',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'sounds',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Amplitude indicator
              if (_isListening) ...[
                Text(
                  'Amplitude: ${_currentAmplitude.toStringAsFixed(1)} dBFS',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: normalizedAmplitude,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: normalizedAmplitude > ((_threshold + 160) / 160)
                      ? Colors.green
                      : colorScheme.primary,
                ),
                const SizedBox(height: 24),
              ],

              // Microphone selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MICROPHONE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_loadingDevices)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: _isListening ? null : _loadDevices,
                              tooltip: 'Refresh devices',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_availableDevices.isEmpty)
                        OutlinedButton.icon(
                          onPressed: _isListening ? null : _loadDevices,
                          icon: const Icon(Icons.mic),
                          label: const Text('Load Microphones'),
                        )
                      else
                        DropdownButtonFormField<InputDevice>(
                          value: _selectedDevice,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _availableDevices.map((device) {
                            return DropdownMenuItem(
                              value: device,
                              child: Text(
                                device.label.isNotEmpty 
                                    ? device.label 
                                    : 'Microphone ${device.id}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _isListening
                              ? null
                              : (device) => setState(() => _selectedDevice = device),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Threshold control
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'THRESHOLD',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_threshold.toStringAsFixed(0)} dBFS',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _threshold,
                        min: -80,
                        max: 0,
                        divisions: 80,
                        label: '${_threshold.toStringAsFixed(0)} dBFS',
                        onChanged: _isListening
                            ? null
                            : (value) => setState(() => _threshold = value),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lower = more sensitive',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(_isListening ? 'Stop' : 'Start Listening'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: _isListening
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton.outlined(
                    onPressed: _resetCounter,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset Counter',
                  ),
                ],
              ),

              // Permission info
              if (!_hasPermission && _errorMessage == null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: colorScheme.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Click "Load Microphones" or "Start Listening" to grant access',
                          style: TextStyle(color: colorScheme.onTertiaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
