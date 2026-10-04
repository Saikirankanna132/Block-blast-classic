import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/strings.dart';

/// Settings: sound, music, vibration, dark mode, accessibility,
/// language and high-score reset.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.sound,
  });

  final AppSettings settings;
  final SoundService sound;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final s = Strings(settings.languageCode);
        return Scaffold(
          appBar: AppBar(title: Text(s.get('settings'))),
          body: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              SwitchListTile(
                title: Text(s.get('sound'), style: _titleStyle),
                secondary: const Icon(Icons.volume_up_rounded),
                value: settings.soundOn,
                onChanged: settings.setSound,
              ),
              SwitchListTile(
                title: Text(s.get('music'), style: _titleStyle),
                secondary: const Icon(Icons.music_note_rounded),
                value: settings.musicOn,
                onChanged: (v) {
                  settings.setMusic(v);
                  if (!v) {
                    sound.stopMusic();
                  } else {
                    sound.startMusic();
                  }
                },
              ),
              SwitchListTile(
                title: Text(s.get('vibration'), style: _titleStyle),
                secondary: const Icon(Icons.vibration_rounded),
                value: settings.vibrationOn,
                onChanged: settings.setVibration,
              ),
              const Divider(),
              SwitchListTile(
                title: Text(s.get('darkMode'), style: _titleStyle),
                secondary: const Icon(Icons.dark_mode_rounded),
                value: settings.darkMode,
                onChanged: settings.setDarkMode,
              ),
              SwitchListTile(
                title:
                    Text(s.get('highContrast'), style: _titleStyle),
                secondary: const Icon(Icons.contrast_rounded),
                value: settings.highContrast,
                onChanged: settings.setHighContrast,
              ),
              SwitchListTile(
                title: Text(s.get('colorBlind'), style: _titleStyle),
                secondary:
                    const Icon(Icons.remove_red_eye_rounded),
                value: settings.colorBlindMode,
                onChanged: settings.setColorBlindMode,
              ),
              SwitchListTile(
                title: Text(s.get('largeText'), style: _titleStyle),
                secondary: const Icon(Icons.text_fields_rounded),
                value: settings.largeText,
                onChanged: settings.setLargeText,
              ),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title:
                    Text(s.get('language'), style: _titleStyle),
                trailing: DropdownButton<String>(
                  value: settings.languageCode,
                  items: [
                    for (final entry
                        in Strings.supported.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (code) {
                    if (code != null) settings.setLanguage(code);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded,
                    color: Colors.red),
                title: Text(s.get('resetScore'),
                    style: _titleStyle.copyWith(color: Colors.red)),
                onTap: () => _confirmReset(context, s),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  s.get('noAds'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const _titleStyle = TextStyle(fontSize: 18);

  void _confirmReset(BuildContext context, Strings s) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.get('resetScore')),
        content: Text(s.get('resetConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              await StorageService.instance.resetStats();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(s.get('reset')),
          ),
        ],
      ),
    );
  }
}
