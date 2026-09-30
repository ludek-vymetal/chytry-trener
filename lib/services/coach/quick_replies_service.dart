import 'package:shared_preferences/shared_preferences.dart';

/// Uložené rychlé odpovědi do zpráv (každé zařízení / role zvlášť).
class QuickRepliesService {
  QuickRepliesService._();

  static String _key(bool coach) =>
      coach ? 'chat_quick_replies_coach_v1' : 'chat_quick_replies_client_v1';

  static const coachDefaults = [
    'Super výkon! 💪 Příště zkus o 2,5 kg víc.',
    'Díky za check-in, podívám se na to a ozvu se.',
    'Nezapomeň dnes odeslat trénink 🙂',
    'Jak ses po tréninku cítil/a?',
    'Na příští týden ti posílám nové tréninky.',
    'Skvělá práce, jen tak dál! 🔥',
  ];

  static const clientDefaults = [
    'Hotovo ✅',
    'Dnes to nestíhám, odcvičím zítra.',
    'Mám dotaz k tréninku:',
    'Díky! 🙏',
  ];

  static Future<List<String>> load({required bool coach}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key(coach)) ??
        (coach ? coachDefaults : clientDefaults);
  }

  static Future<void> save(List<String> items, {required bool coach}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(coach), items);
  }
}
