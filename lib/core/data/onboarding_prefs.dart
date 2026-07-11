import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether a signed-out visitor has already seen the onboarding
/// carousel, so it only shows once per device rather than every launch.
class OnboardingPrefs {
  const OnboardingPrefs._();

  static const _key = 'onboarding_seen';

  static Future<bool> isSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
