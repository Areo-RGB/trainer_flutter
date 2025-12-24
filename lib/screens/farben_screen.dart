import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

/// Farben screen - Stroop effect color trainer.
class FarbenScreen extends StatefulWidget {
  const FarbenScreen({super.key});

  @override
  State<FarbenScreen> createState() => _FarbenScreenState();
}

class _FarbenScreenState extends State<FarbenScreen> {
  // Status
  bool _isPlaying = false;
  bool _isPaused = false;

  // Config
  int _intervalMs = 1000;
  bool _noColors = false;
  bool _preventDuplicates = false;
  bool _playSoundOnChange = false;
  final List<String> _customLabels = [''];

  // Game state
  _ColorType _currentColor = _ColorType.white;
  String _currentLabel = '';
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  _ColorType _getNextColor(_ColorType prev) {
    final available = _ColorType.values.where((c) => c != prev).toList();
    return available[_random.nextInt(available.length)];
  }

  String _getNextLabel(String prev) {
    final validLabels = _customLabels.where((l) => l.trim().isNotEmpty).toList();
    if (validLabels.isEmpty) return '';

    List<String> pool = validLabels;
    if (_preventDuplicates && prev.isNotEmpty && validLabels.length > 1) {
      pool = validLabels.where((l) => l != prev).toList();
    }
    return pool[_random.nextInt(pool.length)];
  }

  Future<void> _playBeep() async {
    if (_playSoundOnChange) {
      try {
        await _audioPlayer.setUrl('https://www.soundjay.com/buttons/beep-01a.mp3');
        await _audioPlayer.setVolume(0.3);
        await _audioPlayer.play();
      } catch (_) {
        // Ignore audio errors
      }
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _currentColor = _getNextColor(_currentColor);
      _currentLabel = _getNextLabel(_currentLabel);
    });
    _playBeep();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _intervalMs), (_) {
      if (!_isPaused) {
        setState(() {
          _currentColor = _getNextColor(_currentColor);
          _currentLabel = _getNextLabel(_currentLabel);
        });
        _playBeep();
      }
    });
  }

  void _stopGame() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _handleLabelChange(int index, String value) {
    setState(() {
      _customLabels[index] = value;
      if (index == _customLabels.length - 1 && value.trim().isNotEmpty) {
        _customLabels.add('');
      }
    });
  }

  void _removeLabel(int index) {
    setState(() {
      _customLabels.removeAt(index);
      if (_customLabels.isEmpty) _customLabels.add('');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isPlaying) {
      return _buildPlayingMode(theme, colorScheme);
    }
    return _buildConfigMode(theme, colorScheme);
  }

  Widget _buildConfigMode(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Farben'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Interval control
            _buildConfigCard(
              theme,
              colorScheme,
              title: 'INTERVAL (MS)',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => setState(
                        () => _intervalMs = (_intervalMs - 100).clamp(100, 5000)),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_intervalMs}ms',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    onPressed: () => setState(
                        () => _intervalMs = (_intervalMs + 100).clamp(100, 5000)),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Options
            _buildConfigCard(
              theme,
              colorScheme,
              title: 'OPTIONS',
              child: Column(
                children: [
                  _buildSwitchRow('No Colors (Text Only)', _noColors,
                      (v) => setState(() => _noColors = v)),
                  _buildSwitchRow('Prevent Duplicate Words', _preventDuplicates,
                      (v) => setState(() => _preventDuplicates = v)),
                  _buildSwitchRow('Play Sound on Change', _playSoundOnChange,
                      (v) => setState(() => _playSoundOnChange = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Custom Labels
            _buildConfigCard(
              theme,
              colorScheme,
              title: 'CUSTOM LABELS',
              child: Column(
                children: [
                  for (int i = 0; i < _customLabels.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Enter label...',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => _handleLabelChange(i, v),
                            ),
                          ),
                          if (_customLabels.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removeLabel(i),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Start button
            FilledButton(
              onPressed: _startGame,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayingMode(ThemeData theme, ColorScheme colorScheme) {
    final colorConfig = _currentColor.config;
    final bgColor = _noColors ? Colors.grey.shade900 : colorConfig.bgColor;
    final textColor = _noColors ? Colors.white : colorConfig.textColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentLabel.isNotEmpty ? _currentLabel : colorConfig.label,
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Positioned(
            top: 16,
            left: 16,
            child: IconButton.filledTonal(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _stopGame,
                  icon: const Icon(Icons.settings),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _togglePause,
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

enum _ColorType {
  red,
  green,
  blue,
  yellow,
  orange,
  purple,
  white;

  _ColorConfig get config {
    switch (this) {
      case _ColorType.red:
        return _ColorConfig(Colors.red.shade700, Colors.white, 'ROT');
      case _ColorType.green:
        return _ColorConfig(Colors.green.shade700, Colors.white, 'GRÜN');
      case _ColorType.blue:
        return _ColorConfig(Colors.blue.shade700, Colors.white, 'BLAU');
      case _ColorType.yellow:
        return _ColorConfig(Colors.yellow.shade600, Colors.black, 'GELB');
      case _ColorType.orange:
        return _ColorConfig(Colors.orange.shade700, Colors.white, 'ORANGE');
      case _ColorType.purple:
        return _ColorConfig(Colors.purple.shade700, Colors.white, 'LILA');
      case _ColorType.white:
        return _ColorConfig(Colors.white, Colors.black, 'WEISS');
    }
  }
}

class _ColorConfig {
  final Color bgColor;
  final Color textColor;
  final String label;

  const _ColorConfig(this.bgColor, this.textColor, this.label);
}
