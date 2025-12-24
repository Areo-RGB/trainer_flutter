import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants.dart';
import '../game_logic.dart';
import 'config_panel.dart';
import 'game_display.dart';
import 'number_pad.dart';
import 'result_panel.dart';

/// Main Kettenrechner screen that switches between game states.
class KettenrechnerScreen extends StatefulWidget {
  const KettenrechnerScreen({super.key});

  @override
  State<KettenrechnerScreen> createState() => _KettenrechnerScreenState();
}

class _KettenrechnerScreenState extends State<KettenrechnerScreen> {
  late final GameLogic _gameLogic;

  @override
  void initState() {
    super.initState();
    _gameLogic = GameLogic();
    _gameLogic.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    _gameLogic.removeListener(_onGameStateChanged);
    _gameLogic.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showAppBar = _gameLogic.status == GameStatus.config;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: showAppBar
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
              title: const Text('Kettenrechner'),
              backgroundColor: colorScheme.surface,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentScreen(),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_gameLogic.status) {
      case GameStatus.config:
        return ConfigPanel(
          key: const ValueKey('config'),
          gameLogic: _gameLogic,
        );
      case GameStatus.playing:
        return GameDisplay(
          key: const ValueKey('playing'),
          gameLogic: _gameLogic,
        );
      case GameStatus.pending:
        return NumberPad(
          key: const ValueKey('pending'),
          gameLogic: _gameLogic,
        );
      case GameStatus.result:
        return ResultPanel(
          key: const ValueKey('result'),
          gameLogic: _gameLogic,
        );
    }
  }
}
