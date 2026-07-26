import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise si l'onboarding a déjà été vu (persistant). Lu de façon synchrone
/// (SharedPreferences est chargé au démarrage) pour le redirect du routeur.
class OnboardingStore {
  const OnboardingStore(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'onboarding_seen';

  bool get hasSeen => _prefs.getBool(_key) ?? false;

  Future<void> markSeen() => _prefs.setBool(_key, true);
}
