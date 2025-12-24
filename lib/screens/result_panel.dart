import 'package:flutter/material.dart';

import '../game_logic.dart';

/// Displays the result of the game with celebration or retry options.
class ResultPanel extends StatelessWidget {
  final GameLogic gameLogic;

  const ResultPanel({super.key, required this.gameLogic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCorrect = gameLogic.isCorrect ?? false;
    final resultColor = isCorrect ? Colors.green : colorScheme.error;
    final resultIcon = isCorrect ? Icons.check_circle : Icons.cancel;
    final resultText = isCorrect ? 'Correct!' : 'Wrong!';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Result icon and text
        Icon(
          resultIcon,
          size: 96,
          color: resultColor,
        ),
        const SizedBox(height: 16),
        Text(
          resultText,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: resultColor,
          ),
        ),
        const SizedBox(height: 24),

        // Show correct answer if wrong
        if (!isCorrect) ...[
          Text(
            'The answer was:',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${gameLogic.total}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // History display
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'History',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: gameLogic.history
                    .map(
                      (op) => Chip(
                        label: Text(op),
                        backgroundColor: colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: gameLogic.returnToConfig,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Back to Config'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: () => gameLogic.startGame(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Play Again'),
            ),
          ],
        ),
      ],
    );
  }
}
