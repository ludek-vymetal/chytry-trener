import 'package:shared_preferences/shared_preferences.dart';

class ActiveClientService {
  static const _key = 'active_client_id_v1';

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> save(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, clientId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}