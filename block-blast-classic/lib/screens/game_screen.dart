import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/app_settings.dart';
import '../services/haptics_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../widgets/block_tray.dart';
import '../widgets/game_board.dart';

/// A floating "+120" label that rises and fades.
class _Popup {
  _Popup(this.id, this.text, this.isCombo);
  final int id;
  final String text;
  final bool isCombo;
}

/// The main gameplay screen: score header, board, tray, effects.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.haptics,
    required this.storage,
  });

  final AppSettings settings;
  final SoundService sound;
  final HapticsService haptics;
  final StorageService storage;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameState _game;
  final List<_Popup> _popups = [];
  int _popupId = 0;

  Set<String> _flashCells = {};
  late final AnimationController _flashController;

  String? _comboText;
  bool _gameOverShown = false;

  @override
  void initState() {
    super.initState();
    _game = GameState(
      storage: widget.storage,
      sound: widget.sound,
      haptics: widget.haptics,
    )..newGame();
    _game.addListener(_onGameChanged);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() => setState(() {}));

    widget.sound.startMusic();
  }

  void _onGameChanged() {
    if (_game.gameOver && !_gameOverShown && mounted) {
      _gameOverShown = true;
      // Let the final board paint before the dialog appears.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOver();
      });
    }
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _flashController.dispose();
    widget.sound.stopMusic();
    super.dispose();
  }

  void _onPlaced(PlacementResult result) {
    setState(() {
      // Floating score animation.
      _popups.add(_Popup(
        _popupId++,
        '+${result.points}',
        result.linesCleared > 1,
      ));

      // Row-clear explosion flash.
      if (result.clearedCells.isNotEmpty) {
        _flashCells = {
          for (final c in result.clearedCells) '${c[0]},${c[1]}',
        };
        _flashController.forward(from: 0);
      }

      // Combo celebration banner.
      if (result.linesCleared > 1) {
        final s = Strings(widget.settings.languageCode);
        _comboText =
            '${s.get('combo')} x${result.linesCleared}! +${result.points}';
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _comboText = null);
        });
      }
    });
  }

  void _showGameOver() {
    final s = Strings(widget.settings.languageCode);
    final isNewBest =
        _game.score >= _game.best && _game.score > 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🎮', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(s.get('gameOver')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNewBest)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('🎉 ${s.get('newBest')}',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
              ),
            _StatRow(
                label: s.get('finalScore'), value: '${_game.score}'),
            _StatRow(
                label: s.get('bestScore'), value: '${_game.best}'),
            _StatRow(
                label: s.get('rowsCleared'),
                value: '${_game.rowsClearedTotal}'),
            _StatRow(
                label: s.get('colsCleared'),
                value: '${_game.colsClearedTotal}'),
            _StatRow(
                label: s.get('gamesPlayed'),
                value: '${widget.storage.gamesPlayed}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // close dialog
              Navigator.of(context).pop(); // back to home
            },
            child: Text(s.get('home')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                _gameOverShown = false;
                _popups.clear();
                _comboText = null;
              });
              _game.newGame();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(s.get('playAgain')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_game, widget.settings]),
      builder: (context, _) {
        final s = Strings(widget.settings.languageCode);
        final palette = widget.settings.highContrast
            ? BlockPalette.highContrastColors
            : BlockPalette.colors;

        return Scaffold(
          appBar: AppBar(
            title: Text(s.get('appName')),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(widget.settings.soundOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded),
                tooltip: s.get('sound'),
                onPressed: () {
                  widget.settings
                      .setSound(!widget.settings.soundOn);
                  widget.sound.playClick();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Score header: current + best.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          _ScoreCard(
                              label: s.get('score'),
                              value: '${_game.score}',
                              color: Colors.blue),
                          _ScoreCard(
                              label: s.get('best'),
                              value: '${_game.best}',
                              color: Colors.amber.shade700),
                        ],
                      ),
                    ),
                    // Board.
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: GameBoard(
                            state: _game,
                            onPlaced: _onPlaced,
                            flashCells: _flashCells,
                            flashValue:
                                1.0 - _flashController.value,
                            palette: palette,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tray.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: BlockTray(
                        state: _game,
                        highContrast:
                            widget.settings.highContrast,
                        colorBlindMode:
                            widget.settings.colorBlindMode,
                      ),
                    ),
                  ],
                ),

                // Floating score popups.
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      for (final popup in _popups)
                        _FloatingPopup(
                          key: ValueKey(popup.id),
                          popup: popup,
                          onDone: () => setState(() =>
                              _popups.removeWhere(
                                  (p) => p.id == popup.id)),
                        ),
                    ],
                  ),
                ),

                // Combo celebration banner.
                if (_comboText != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.6, end: 1.15),
                          duration:
                              const Duration(milliseconds: 350),
                          builder: (context, scale, child) =>
                              Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.purple,
                                  Colors.deepOrange
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _comboText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold)),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _FloatingPopup extends StatelessWidget {
  const _FloatingPopup(
      {super.key, required this.popup, required this.onDone});
  final _Popup popup;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      onEnd: onDone,
      builder: (context, t, child) {
        return Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: Offset(0, -50 * t),
            child: child,
          ),
        );
      },
      child: Text(
        popup.text,
        style: TextStyle(
          fontSize: popup.isCombo ? 34 : 26,
          fontWeight: FontWeight.bold,
          color: popup.isCombo ? Colors.deepOrange : Colors.green,
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
