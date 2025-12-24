import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Timers screen - Custom timers and sequences.
class TimersScreen extends StatefulWidget {
  const TimersScreen({super.key});

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  List<_TimerSequence> _sequences = [];
  bool _showBuilder = false;

  @override
  void initState() {
    super.initState();
    _loadSequences();
  }

  Future<void> _loadSequences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('timer_sequences') ?? [];
    setState(() {
      _sequences = data.map((s) => _TimerSequence.fromString(s)).toList();
    });
  }

  Future<void> _saveSequences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'timer_sequences',
      _sequences.map((s) => s.toString()).toList(),
    );
  }

  void _addSequence(_TimerSequence sequence) {
    setState(() {
      _sequences.add(sequence);
      _showBuilder = false;
    });
    _saveSequences();
  }

  void _deleteSequence(String id) {
    setState(() {
      _sequences.removeWhere((s) => s.id == id);
    });
    _saveSequences();
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
        title: const Text('Timers'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _sequences.length + 2 + 1, // 2 default + sequences + add button
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _TimerCard(
                        title: 'Custom Timer',
                        color: Colors.blue,
                        defaultDuration: 60,
                      );
                    }
                    if (index == 1) {
                      return _TimerCard(
                        title: 'Presets',
                        color: Colors.orange,
                        defaultDuration: 30,
                        presets: const [15, 30, 45, 60],
                      );
                    }
                    if (index < _sequences.length + 2) {
                      final seq = _sequences[index - 2];
                      return _SequenceCard(
                        sequence: seq,
                        onDelete: () => _deleteSequence(seq.id),
                      );
                    }
                    // Add button
                    return _AddSequenceCard(
                      onTap: () => setState(() => _showBuilder = true),
                    );
                  },
                );
              },
            ),
          ),

          // Builder dialog
          if (_showBuilder)
            _SequenceBuilderDialog(
              onClose: () => setState(() => _showBuilder = false),
              onSave: _addSequence,
            ),
        ],
      ),
    );
  }
}

/// A single timer card with countdown functionality.
class _TimerCard extends StatefulWidget {
  final String title;
  final Color color;
  final int defaultDuration;
  final List<int>? presets;

  const _TimerCard({
    required this.title,
    required this.color,
    required this.defaultDuration,
    this.presets,
  });

  @override
  State<_TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<_TimerCard> {
  late int _duration;
  int _remaining = 0;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _duration = widget.defaultDuration;
    _remaining = _duration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _remaining = _duration;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _stop();
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remaining = _duration;
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: widget.color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
            const Spacer(),

            // Timer display
            Center(
              child: Text(
                _formatTime(_remaining),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const Spacer(),

            // Presets
            if (widget.presets != null) ...[
              Wrap(
                spacing: 8,
                children: widget.presets!.map((p) {
                  return ActionChip(
                    label: Text('${p}s'),
                    onPressed: _isRunning
                        ? null
                        : () => setState(() {
                              _duration = p;
                              _remaining = p;
                            }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning)
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(backgroundColor: widget.color),
                  )
                else
                  FilledButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for a saved timer sequence.
class _SequenceCard extends StatefulWidget {
  final _TimerSequence sequence;
  final VoidCallback onDelete;

  const _SequenceCard({
    required this.sequence,
    required this.onDelete,
  });

  @override
  State<_SequenceCard> createState() => _SequenceCardState();
}

class _SequenceCardState extends State<_SequenceCard> {
  bool _isRunning = false;
  int _currentIndex = 0;
  int _remaining = 0;
  int _currentLoop = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _currentIndex = 0;
      _currentLoop = 0;
      _remaining = widget.sequence.steps[0];
    });
    _runTimer();
  }

  void _runTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _nextStep();
        }
      });
    });
  }

  void _nextStep() {
    _currentIndex++;
    if (_currentIndex >= widget.sequence.steps.length) {
      _currentIndex = 0;
      _currentLoop++;
      if (widget.sequence.loops > 0 && _currentLoop >= widget.sequence.loops) {
        _stop();
        return;
      }
    }
    _remaining = widget.sequence.steps[_currentIndex];
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.sequence.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                  color: colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.sequence.steps.length} steps • ${widget.sequence.loops > 0 ? "${widget.sequence.loops} loops" : "infinite"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),

            if (_isRunning) ...[
              Center(
                child: Column(
                  children: [
                    Text(
                      'Step ${_currentIndex + 1}/${widget.sequence.steps.length}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${_remaining}s',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _isRunning ? _stop : _start,
                  icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(_isRunning ? 'Stop' : 'Start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Add sequence card.
class _AddSequenceCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddSequenceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 32,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create Sequence',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Build a custom loop of timers',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for building a new sequence.
class _SequenceBuilderDialog extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(_TimerSequence) onSave;

  const _SequenceBuilderDialog({
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_SequenceBuilderDialog> createState() => _SequenceBuilderDialogState();
}

class _SequenceBuilderDialogState extends State<_SequenceBuilderDialog> {
  String _name = '';
  List<int> _steps = [30];
  int _loops = 0;

  void _addStep() {
    setState(() {
      _steps.add(30);
    });
  }

  void _removeStep(int index) {
    if (_steps.length > 1) {
      setState(() {
        _steps.removeAt(index);
      });
    }
  }

  void _save() {
    if (_name.trim().isEmpty) return;
    widget.onSave(_TimerSequence(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.trim(),
      steps: _steps,
      loops: _loops,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Sequence',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Name input
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Sequence Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => _name = v,
                    ),
                    const SizedBox(height: 24),

                    // Steps
                    Text(
                      'STEPS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < _steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('Step ${i + 1}'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  suffixText: 'sec',
                                ),
                                controller:
                                    TextEditingController(text: '${_steps[i]}'),
                                onChanged: (v) {
                                  final val = int.tryParse(v);
                                  if (val != null) _steps[i] = val;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeStep(i),
                            ),
                          ],
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Step'),
                    ),
                    const SizedBox(height: 16),

                    // Loops
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Loops (0 = infinite)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => _loops = int.tryParse(v) ?? 0,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Save Sequence'),
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
}

/// Data model for a timer sequence.
class _TimerSequence {
  final String id;
  final String name;
  final List<int> steps;
  final int loops;

  const _TimerSequence({
    required this.id,
    required this.name,
    required this.steps,
    required this.loops,
  });

  factory _TimerSequence.fromString(String data) {
    final parts = data.split('|');
    return _TimerSequence(
      id: parts[0],
      name: parts[1],
      steps: parts[2].split(',').map((s) => int.parse(s)).toList(),
      loops: int.parse(parts[3]),
    );
  }

  @override
  String toString() => '$id|$name|${steps.join(',')}|$loops';
}
