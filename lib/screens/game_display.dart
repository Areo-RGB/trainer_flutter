import 'package:flutter/material.dart';

import '../game_logic.dart';

/// Displays the current operation during gameplay.
class GameDisplay extends StatelessWidget {
  final GameLogic gameLogic;

  const GameDisplay({super.key, required this.gameLogic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate font size based on stored fontSize value (1-20 scale)
    final displayFontSize = 48.0 + (gameLogic.fontSize * 8);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Step ${gameLogic.currentStep}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (gameLogic.targetSteps > 0) ...[
                Text(
                  ' / ${gameLogic.targetSteps}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Main display
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                gameLogic.display,
                key: ValueKey(gameLogic.display),
                style: TextStyle(
                  fontSize: displayFontSize,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),

        // Font size control
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => gameLogic.setFontSize(gameLogic.fontSize - 1),
                icon: const Icon(Icons.text_decrease),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: () => gameLogic.setFontSize(gameLogic.fontSize + 1),
                icon: const Icon(Icons.text_increase),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
