import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// App-wide user preferences (settings + accessibility).
/// Persists to [StorageService] and notifies listeners so the UI rebuilds.
class AppSettings extends ChangeNotifier {
  late bool soundOn;
  late bool musicOn;
  late bool vibrationOn;
  late bool darkMode;
  late bool highContrast;
  late bool colorBlindMode;
  late bool largeText;
  late String languageCode;

  StorageService get _s => StorageService.instance;

  void load() {
    soundOn = _s.soundOn;
    musicOn = _s.musicOn;
    vibrationOn = _s.vibrationOn;
    darkMode = _s.darkMode;
    highContrast = _s.highContrast;
    colorBlindMode = _s.colorBlindMode;
    largeText = _s.largeText;
    languageCode = _s.languageCode;
  }

  void setSound(bool v) {
    soundOn = v;
    _s.soundOn = v;
    notifyListeners();
  }

  void setMusic(bool v) {
    musicOn = v;
    _s.musicOn = v;
    notifyListeners();
  }

  void setVibration(bool v) {
    vibrationOn = v;
    _s.vibrationOn = v;
    notifyListeners();
  }

  void setDarkMode(bool v) {
    darkMode = v;
    _s.darkMode = v;
    notifyListeners();
  }

  void setHighContrast(bool v) {
    highContrast = v;
    _s.highContrast = v;
    notifyListeners();
  }

  void setColorBlindMode(bool v) {
    colorBlindMode = v;
    _s.colorBlindMode = v;
    notifyListeners();
  }

  void setLargeText(bool v) {
    largeText = v;
    _s.largeText = v;
    notifyListeners();
  }

  void setLanguage(String code) {
    languageCode = code;
    _s.languageCode = code;
    notifyListeners();
  }
}
