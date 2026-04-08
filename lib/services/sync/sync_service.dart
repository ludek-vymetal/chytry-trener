import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  static const _lastSyncKey = 'last_cloud_sync_v1';
  static const _deviceIdKey = 'device_id_v1';

  // --------------------------
  // DEVICE ID
  // --------------------------
  static Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  static Future<void> setDeviceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, id);
  }

  // --------------------------
  // LAST SYNC TIME
  // --------------------------
  static Future<DateTime?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    if (raw == null) return null;

    return DateTime.tryParse(raw);
  }

  static Future<void> setLastSyncAt(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  // --------------------------
  // DEBUG / RESET
  // --------------------------
  static Future<void> resetSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
  }
}