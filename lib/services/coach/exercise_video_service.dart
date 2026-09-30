import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Odkazy na videa s technikou cviků (název cviku → URL).
/// Trenér je zadá jednou a posílají se s každým tréninkem klientovi.
class ExerciseVideoService {
  ExerciseVideoService._();

  static const key = 'exercise_videos_v1';

  static String norm(String name) => name.trim().toLowerCase();

  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final d = jsonDecode(raw);
      if (d is Map) {
        return {for (final e in d.entries) e.key.toString(): e.value.toString()};
      }
    } catch (_) {}
    return {};
  }

  static Future<void> save(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(map));
  }

  /// Odkaz pro cvik (podle názvu, bez ohledu na velikost písmen).
  static String? urlFor(Map<String, String> map, String name) => map[norm(name)];

  /// Je to rozumný odkaz?
  static bool isValid(String url) {
    final u = Uri.tryParse(url.trim());
    return u != null &&
        (u.scheme == 'https' || u.scheme == 'http') &&
        u.host.isNotEmpty;
  }
}
