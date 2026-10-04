import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/haptics_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/strings.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Home screen: logo, best score and big friendly buttons.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
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
    final strings = Strings(settings.languageCode);
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final s = Strings(settings.languageCode);
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo (falls back to an emoji tile if missing).
                    _Logo(),
                    const SizedBox(height: 16),
                    Text(
                      s.get('appName'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.get('tagline'),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    _BestChip(
                        label: s.get('best'), value: '${storage.bestScore}'),
                    const SizedBox(height: 28),
                    _MenuButton(
                      label: s.get('start'),
                      icon: Icons.play_arrow_rounded,
                      color: Colors.green,
                      onTap: () {
                        sound.playClick();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameScreen(
                              settings: settings,
                              sound: sound,
                              haptics: haptics,
                              storage: storage,
                            ),
                          ),
                        );
                      },
                    ),
                    _MenuButton(
                      label: s.get('statistics'),
                      icon: Icons.bar_chart_rounded,
                      color: Colors.blue,
                      onTap: () {
                        sound.playClick();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StatsScreen(settings: settings),
                          ),
                        );
                      },
                    ),
                    _MenuButton(
                      label: s.get('settings'),
                      icon: Icons.settings_rounded,
                      color: Colors.orange,
                      onTap: () {
                        sound.playClick();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              settings: settings,
                              sound: sound,
                            ),
                          ),
                        );
                      },
                    ),
                    _MenuButton(
                      label: s.get('rate'),
                      icon: Icons.star_rounded,
                      color: Colors.purple,
                      onTap: () {
                        sound.playClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('⭐ ${strings.get('rate')} — v1.0.0')),
                        );
                      },
                    ),
                    _MenuButton(
                      label: s.get('privacy'),
                      icon: Icons.privacy_tip_rounded,
                      color: Colors.teal,
                      onTap: () {
                        sound.playClick();
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(s.get('privacy')),
                            content: Text(s.get('noAds')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(s.get('cancel')),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.amber,
            child: const Center(
              child: Text('🧱', style: TextStyle(fontSize: 56)),
            ),
          ),
        ),
      ),
    );
  }
}

class _BestChip extends StatelessWidget {
  const _BestChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.shade700, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text('$label: $value',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: 60, // large touch target for older adults
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 28),
          label: Text(label, style: const TextStyle(fontSize: 20)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18), // rounded corners
            ),
            elevation: 3,
          ),
        ),
      ),
    );
  }
}
