// Constants for the Kettenrechner game.

/// Defines the possible game states.
enum GameStatus {
  /// The configuration screen where users set up the game.
  config,

  /// The game is actively playing, showing operations.
  playing,

  /// The game is waiting for the user's answer.
  pending,

  /// The game is showing the result of the user's answer.
  result,
}

/// Default confetti colors.
const List<int> confettiColors = [
  0xFFFF6347, // Tomato
  0xFFFFA500, // Orange
  0xFF32CD32, // LimeGreen
  0xFF1E90FF, // DodgerBlue
  0xFFFF69B4, // HotPink
  0xFF8BAA8B, // SageGreen
  0xFF5076A3, // SteelBlue
];
