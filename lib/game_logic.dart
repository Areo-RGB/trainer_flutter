import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// Manages all state and logic for the Kettenrechner game.
///
/// This class is responsible for:
/// - Game configuration (speed, steps, beep settings)
/// - Game flow (countdown, playing, pending answer, result)
/// - Answer checking and scoring
class GameLogic extends ChangeNotifier {
  // Config state
  GameStatus _status = GameStatus.config;
  int _speed = 5;
  int _targetSteps = 5;
  int _fontSize = 6;
  bool _playBeepOnStep = false;

  // Game state
  String _display = 'Ready?';
  int _total = 0;
  List<String> _history = [];
  String _userAnswer = '';
  bool? _isCorrect;
  bool _showCelebration = false;
  int _currentStep = 0;

  Timer? _timer;
  final Random _random = Random();
  String? _lastOpStr;

  // Shared preferences instance
  SharedPreferences? _prefs;

  // Getters
  GameStatus get status => _status;
  int get speed => _speed;
  int get targetSteps => _targetSteps;
  int get fontSize => _fontSize;
  bool get playBeepOnStep => _playBeepOnStep;
  String get display => _display;
  int get total => _total;
  List<String> get history => List.unmodifiable(_history);
  String get userAnswer => _userAnswer;
  bool? get isCorrect => _isCorrect;
  bool get showCelebration => _showCelebration;
  int get currentStep => _currentStep;

  GameLogic() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _speed = _prefs?.getInt('kettenrechner_speed') ?? 5;
    _targetSteps = _prefs?.getInt('kettenrechner_targetSteps') ?? 5;
    _fontSize = _prefs?.getInt('kettenrechner_fontSize') ?? 6;
    _playBeepOnStep = _prefs?.getBool('kettenrechner_playBeepOnStep') ?? false;
    notifyListeners();
  }

  // Setters with persistence
  void setSpeed(int value) {
    _speed = value.clamp(1, 30);
    _prefs?.setInt('kettenrechner_speed', _speed);
    notifyListeners();
  }

  void setTargetSteps(int value) {
    _targetSteps = value.clamp(1, 100);
    _prefs?.setInt('kettenrechner_targetSteps', _targetSteps);
    notifyListeners();
  }

  void setFontSize(int value) {
    _fontSize = value.clamp(1, 20);
    _prefs?.setInt('kettenrechner_fontSize', _fontSize);
    notifyListeners();
  }

  void setPlayBeepOnStep(bool value) {
    _playBeepOnStep = value;
    _prefs?.setBool('kettenrechner_playBeepOnStep', _playBeepOnStep);
    notifyListeners();
  }

  /// Starts the game with optional overrides for speed and steps.
  void startGame({int? overrideSpeed, int? overrideSteps}) {
    _timer?.cancel();

    final activeSpeed = overrideSpeed ?? _speed;
    final activeSteps = overrideSteps ?? _targetSteps;

    if (overrideSpeed != null) setSpeed(overrideSpeed);
    if (overrideSteps != null) setTargetSteps(overrideSteps);

    _status = GameStatus.playing;
    _total = 0;
    _history = [];
    _currentStep = 0;
    _lastOpStr = null;
    notifyListeners();

    _runCountdown(activeSpeed, activeSteps);
  }

  void _runCountdown(int activeSpeed, int activeSteps) {
    final seq = ['3', '2', '1'];
    int idx = 0;
    _display = seq[0];
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      idx++;
      if (idx < seq.length) {
        _display = seq[idx];
        notifyListeners();
      } else {
        timer.cancel();
        _startLogic(activeSpeed, activeSteps);
      }
    });
  }

  void _startLogic(int activeSpeed, int activeSteps) {
    int steps = 0;

    void tick() {
      if (activeSteps > 0 && steps >= activeSteps) {
        _finishGame();
        return;
      }

      int n;
      bool add;
      String opStr;
      int attempts = 0;

      // Prevent exact same operation twice in a row
      do {
        n = _random.nextInt(9) + 1;
        add = _random.nextBool();
        // Fallback if result would be negative
        if (!add && _total - n < 0) add = true;

        opStr = add ? '+$n' : '-$n';
        attempts++;
      } while (opStr == _lastOpStr && attempts < 10);

      _lastOpStr = opStr;
      _total = add ? _total + n : _total - n;

      // TODO: Play beep if _playBeepOnStep is true

      _display = opStr;
      _history = [..._history, opStr];
      _currentStep++;
      steps++;
      notifyListeners();
    }

    tick();
    _timer = Timer.periodic(
      Duration(seconds: activeSpeed),
      (_) => tick(),
    );
  }

  void _finishGame() {
    _timer?.cancel();
    _status = GameStatus.pending;
    _display = '?';
    _userAnswer = '';
    _isCorrect = null;
    _showCelebration = false;
    notifyListeners();
  }

  /// Appends a digit to the user's answer.
  void appendDigit(String digit) {
    _userAnswer += digit;
    notifyListeners();
  }

  /// Clears the user's input.
  void clearInput() {
    _userAnswer = '';
    notifyListeners();
  }

  /// Checks the user's answer against the total.
  void checkAnswer() {
    final trimmed = _userAnswer.trim();
    if (trimmed.isEmpty) {
      _showCelebration = false;
      _isCorrect = null;
    } else {
      final userNum = int.tryParse(trimmed);
      final correct = userNum == _total;
      _isCorrect = correct;
      _showCelebration = correct;

      // TODO: Play win/lose sound
    }
    _status = GameStatus.result;
    notifyListeners();
  }

  /// Returns to the configuration screen.
  void returnToConfig() {
    _timer?.cancel();
    _status = GameStatus.config;
    _display = 'Ready?';
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
