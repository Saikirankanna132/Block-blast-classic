import 'package:vibration/vibration.dart';

/// Subtle vibration feedback on successful placement.
/// Disabled automatically when the user turns vibrations off in Settings.
class HapticsService {
  bool enabled = true;

  /// A very short, gentle buzz.
  Future<void> tap() async {
    if (!enabled) return;
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 25, amplitude: 80);
      }
    } catch (_) {
      // Devices without a vibrator (or denied permission) are fine.
    }
  }

  /// A slightly longer buzz for line clears / combos.
  Future<void> celebrate() async {
    if (!enabled) return;
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 60, amplitude: 120);
      }
    } catch (_) {}
  }
}
