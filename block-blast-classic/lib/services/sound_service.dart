import 'package:audioplayers/audioplayers.dart';

/// Plays short sound effects and looping background music.
/// All calls are safe no-ops when the corresponding toggle is off or when
/// an asset is missing (e.g. before real sounds are added).
class SoundService {
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool soundOn = true;
  bool musicOn = true;
  bool _musicStarted = false;

  Future<void> _play(String asset) async {
    if (!soundOn) return;
    try {
      // AssetSource paths are relative to the assets/ root declared in pubspec.
      await _sfx.play(AssetSource(asset));
    } catch (_) {
      // Missing/corrupt asset — never crash the game over audio.
    }
  }

  Future<void> playPlace() => _play('sounds/place.wav');
  Future<void> playClear(int lines) =>
      _play(lines > 1 ? 'sounds/combo.wav' : 'sounds/clear.wav');
  Future<void> playGameOver() => _play('sounds/game_over.wav');
  Future<void> playClick() => _play('sounds/click.wav');

  /// Starts the gentle background loop. Call from the game screen's init.
  Future<void> startMusic() async {
    if (!musicOn || _musicStarted) return;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource('sounds/music.wav'));
      _musicStarted = true;
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
    _musicStarted = false;
  }

  Future<void> dispose() async {
    await _sfx.dispose();
    await _music.dispose();
  }
}
