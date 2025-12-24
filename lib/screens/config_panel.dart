import 'package:flutter/material.dart';

import '../game_logic.dart';

/// Configuration screen where users set up the game parameters.
class ConfigPanel extends StatefulWidget {
  final GameLogic gameLogic;

  const ConfigPanel({super.key, required this.gameLogic});

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  bool _levelsOpen = false;

  @override
  Widget build(BuildContext context) {
    final logic = widget.gameLogic;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Text(
              'Ready?',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Levels Accordion
            _buildLevelsAccordion(context, logic),
            const SizedBox(height: 24),

            // Manual Config
            _buildManualConfig(context, logic),
            const SizedBox(height: 24),

            // Start Button
            FilledButton(
              onPressed: () => logic.startGame(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 20,
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelsAccordion(BuildContext context, GameLogic logic) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Accordion Header
          InkWell(
            onTap: () => setState(() => _levelsOpen = !_levelsOpen),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Levels',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _levelsOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          // Accordion Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  _buildLevelButton(
                    context,
                    label: 'Level 1',
                    subtitle: 'Speed: 5s, Steps: 5',
                    onTap: () => logic.startGame(overrideSpeed: 5, overrideSteps: 5),
                  ),
                  const SizedBox(height: 8),
                  _buildLevelButton(
                    context,
                    label: 'Level 2',
                    subtitle: 'Speed: 5s, Steps: 10',
                    onTap: () =>
                        logic.startGame(overrideSpeed: 5, overrideSteps: 10),
                  ),
                  const SizedBox(height: 8),
                  _buildLevelButton(
                    context,
                    label: 'Level 3',
                    subtitle: 'Speed: 4s, Steps: 5',
                    onTap: () => logic.startGame(overrideSpeed: 4, overrideSteps: 5),
                  ),
                ],
              ),
            ),
            crossFadeState:
                _levelsOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton(
    BuildContext context, {
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.transparent, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualConfig(BuildContext context, GameLogic logic) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Speed control
          _buildConfigRow(
            context,
            label: 'SPEED (SECONDS)',
            value: '${logic.speed}s',
            onDecrement: () => logic.setSpeed(logic.speed - 1),
            onIncrement: () => logic.setSpeed(logic.speed + 1),
          ),
          const SizedBox(height: 24),

          // Steps control
          _buildConfigRow(
            context,
            label: 'STEPS',
            value: '${logic.targetSteps}',
            onDecrement: () => logic.setTargetSteps(logic.targetSteps - 1),
            onIncrement: () => logic.setTargetSteps(logic.targetSteps + 1),
          ),
          const SizedBox(height: 24),

          // Beep toggle
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.volume_up,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Beep on Step',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Switch(
                value: logic.playBeepOnStep,
                onChanged: logic.setPlayBeepOnStep,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 80,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 24),
            IconButton.filledTonal(
              onPressed: onIncrement,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
