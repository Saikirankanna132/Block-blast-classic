import 'package:shared_preferences/shared_preferences.dart';

/// Thin persistence layer over shared_preferences.
/// Everything is stored locally on-device; the game is fully offline.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;
  static StorageService? _instance;

  static Future<StorageService> init() async {
    _instance ??= StorageService._(await SharedPreferences.getInstance());
    return _instance!;
  }

  static StorageService get instance => _instance!;

  // ---------- statistics ----------
  int get bestScore => _prefs.getInt('best_score') ?? 0;
  set bestScore(int v) => _prefs.setInt('best_score', v);

  int get gamesPlayed => _prefs.getInt('games_played') ?? 0;
  set gamesPlayed(int v) => _prefs.setInt('games_played', v);

  int get totalScore => _prefs.getInt('total_score') ?? 0;
  set totalScore(int v) => _prefs.setInt('total_score', v);

  int get totalBlocksPlaced => _prefs.getInt('total_blocks') ?? 0;
  set totalBlocksPlaced(int v) => _prefs.setInt('total_blocks', v);

  int get totalRowsCleared => _prefs.getInt('total_rows') ?? 0;
  set totalRowsCleared(int v) => _prefs.setInt('total_rows', v);

  int get totalColsCleared => _prefs.getInt('total_cols') ?? 0;
  set totalColsCleared(int v) => _prefs.setInt('total_cols', v);

  double get averageScore =>
      gamesPlayed == 0 ? 0 : totalScore / gamesPlayed;

  Future<void> resetStats() async {
    await _prefs.setInt('best_score', 0);
    await _prefs.setInt('games_played', 0);
    await _prefs.setInt('total_score', 0);
    await _prefs.setInt('total_blocks', 0);
    await _prefs.setInt('total_rows', 0);
    await _prefs.setInt('total_cols', 0);
  }

  // ---------- settings ----------
  bool get soundOn => _prefs.getBool('set_sound') ?? true;
  set soundOn(bool v) => _prefs.setBool('set_sound', v);

  bool get musicOn => _prefs.getBool('set_music') ?? true;
  set musicOn(bool v) => _prefs.setBool('set_music', v);

  bool get vibrationOn => _prefs.getBool('set_vibration') ?? true;
  set vibrationOn(bool v) => _prefs.setBool('set_vibration', v);

  bool get darkMode => _prefs.getBool('set_dark') ?? false;
  set darkMode(bool v) => _prefs.setBool('set_dark', v);

  bool get highContrast => _prefs.getBool('set_contrast') ?? false;
  set highContrast(bool v) => _prefs.setBool('set_contrast', v);

  bool get colorBlindMode => _prefs.getBool('set_colorblind') ?? false;
  set colorBlindMode(bool v) => _prefs.setBool('set_colorblind', v);

  bool get largeText => _prefs.getBool('set_largetext') ?? false;
  set largeText(bool v) => _prefs.setBool('set_largetext', v);

  String get languageCode => _prefs.getString('set_lang') ?? 'en';
  set languageCode(String v) => _prefs.setString('set_lang', v);
}
