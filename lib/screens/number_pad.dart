import 'package:flutter/material.dart';

import '../game_logic.dart';

/// Number pad for entering the user's answer.
class NumberPad extends StatelessWidget {
  final GameLogic gameLogic;

  const NumberPad({super.key, required this.gameLogic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Question mark title
        Text(
          '?',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),

        // Answer display
        Container(
          constraints: const BoxConstraints(minWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            gameLogic.userAnswer.isEmpty ? '_' : gameLogic.userAnswer,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Number pad grid
        SizedBox(
          width: 280,
          child: Column(
            children: [
              // Rows 1-3
              for (int row = 0; row < 3; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int col = 1; col <= 3; col++)
                        _buildDigitButton(
                          context,
                          digit: '${row * 3 + col}',
                        ),
                    ],
                  ),
                ),
              // Bottom row: clear, 0, submit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Clear button
                  _buildActionButton(
                    context,
                    icon: Icons.backspace_outlined,
                    onPressed: gameLogic.clearInput,
                    color: colorScheme.error,
                  ),
                  // 0 button
                  _buildDigitButton(context, digit: '0'),
                  // Negative toggle
                  _buildDigitButton(context, digit: '-'),
                ],
              ),
              const SizedBox(height: 24),
              // Submit button
              FilledButton(
                onPressed: gameLogic.checkAnswer,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64,
                    vertical: 20,
                  ),
                ),
                child: const Text('Check Answer'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitButton(BuildContext context, {required String digit}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 72,
      height: 72,
      child: FilledButton.tonal(
        onPressed: () => gameLogic.appendDigit(digit),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          digit,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
