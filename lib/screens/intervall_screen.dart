import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

/// Intervall screen - Periodic audio beep timer.
class IntervallScreen extends StatefulWidget {
  const IntervallScreen({super.key});

  @override
  State<IntervallScreen> createState() => _IntervallScreenState();
}

class _IntervallScreenState extends State<IntervallScreen> {
  double _intervalSec = 2.0;
  String _limitSec = '';
  bool _isRunning = false;
  bool _volumeBoost = false;

  Timer? _beepTimer;
  Timer? _limitTimer;
  int _remainingSeconds = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _beepTimer?.cancel();
    _limitTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    final volume = _volumeBoost ? 0.8 : 0.3;
    try {
      await _audioPlayer.setUrl('https://www.soundjay.com/buttons/beep-01a.mp3');
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.play();
    } catch (_) {
      // Ignore audio errors
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _remainingSeconds = _intervalSec.round();
    });

    _playBeep();
    _startBeepCycle();

    // Auto-stop limit
    final limit = int.tryParse(_limitSec);
    if (limit != null && limit > 0) {
      _limitTimer = Timer(Duration(seconds: limit), _stop);
    }
  }

  void _startBeepCycle() {
    _beepTimer?.cancel();
    _remainingSeconds = _intervalSec.round();

    // Countdown timer
    _beepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _playBeep();
        _remainingSeconds = _intervalSec.round();
      }
    });
  }

  void _stop() {
    _beepTimer?.cancel();
    _limitTimer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _intervalSec.round();
    });
  }

  void _toggle() {
    if (_isRunning) {
      _stop();
    } else {
      _startTimer();
    }
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
          onPressed: () => context.go('/'),
        ),
        title: const Text('Intervall'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timer display
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRunning
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                      ),
                      child: Center(
                        child: _isRunning
                            ? Text(
                                '${_remainingSeconds}s',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Intervall',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Periodic audio cues for training.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Interval control
                    _buildLabel(theme, 'INTERVAL (SECONDS)'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.outlined(
                          onPressed: _isRunning
                              ? null
                              : () => setState(() =>
                                  _intervalSec = (_intervalSec - 0.5).clamp(0.5, 60)),
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: TextEditingController(
                                text: _intervalSec.toStringAsFixed(1)),
                            enabled: !_isRunning,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (v) {
                              final val = double.tryParse(v);
                              if (val != null) {
                                setState(() => _intervalSec = val.clamp(0.5, 60));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton.outlined(
                          onPressed: _isRunning
                              ? null
                              : () => setState(() =>
                                  _intervalSec = (_intervalSec + 0.5).clamp(0.5, 60)),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Presets
                    Wrap(
                      spacing: 8,
                      children: [2, 5, 10, 30].map((val) {
                        final isSelected = _intervalSec == val.toDouble();
                        return ChoiceChip(
                          label: Text('${val}s'),
                          selected: isSelected,
                          onSelected: _isRunning
                              ? null
                              : (_) => setState(() => _intervalSec = val.toDouble()),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Auto-stop limit
                    _buildLabel(theme, 'AUTO-STOP LIMIT'),
                    const SizedBox(height: 8),
                    TextField(
                      enabled: !_isRunning,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Optional (e.g. 60)',
                        border: OutlineInputBorder(),
                        suffixText: 'seconds',
                      ),
                      onChanged: (v) => setState(() => _limitSec = v),
                    ),
                    const SizedBox(height: 24),

                    // Volume boost
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.volume_up, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              const Text('Volume Boost'),
                            ],
                          ),
                          Switch(
                            value: _volumeBoost,
                            onChanged: (v) => setState(() => _volumeBoost = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Start/Stop button
                    FilledButton(
                      onPressed: _toggle,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor:
                            _isRunning ? colorScheme.error : colorScheme.primary,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                          const SizedBox(width: 8),
                          Text(_isRunning ? 'Stop' : 'Start Timer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
