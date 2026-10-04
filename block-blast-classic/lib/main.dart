import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/haptics_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'utils/strings.dart';

/// App entry point.
///
/// Wiring order matters:
/// 1. Storage (shared_preferences) must init first — everything reads it.
/// 2. Settings load from storage.
/// 3. Sound/haptics follow the settings toggles live.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.init();
  final settings = AppSettings()..load();

  final sound = SoundService()
    ..soundOn = settings.soundOn
    ..musicOn = settings.musicOn;
  final haptics = HapticsService()..enabled = settings.vibrationOn;

  // Keep services in sync when the user flips toggles in Settings.
  settings.addListener(() {
    sound.soundOn = settings.soundOn;
    if (!settings.musicOn) {
      sound.musicOn = false;
      sound.stopMusic();
    } else {
      sound.musicOn = true;
    }
    haptics.enabled = settings.vibrationOn;
  });

  runApp(BlockBlastApp(
    settings: settings,
    sound: sound,
    haptics: haptics,
    storage: storage,
  ));
}

class BlockBlastApp extends StatelessWidget {
  const BlockBlastApp({
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final strings = Strings(settings.languageCode);
        return MaterialApp(
          title: strings.get('appName'),
          debugShowCheckedModeBanner: false,
          // Large-text accessibility mode scales all text up.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                  settings.largeText ? 1.3 : 1.0),
            ),
            child: child!,
          ),
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.orange,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFFFBEB),
            appBarTheme: const AppBarTheme(centerTitle: true),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.orange,
            brightness: Brightness.dark,
          ),
          themeMode:
              settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: HomeScreen(
            settings: settings,
            sound: sound,
            haptics: haptics,
            storage: storage,
          ),
        );
      },
    );
  }
}
