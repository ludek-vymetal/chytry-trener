import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole { user, coach }

class AppRoleNotifier extends StateNotifier<AppRole?> {
  AppRoleNotifier() : super(null) {
    _init();
  }

  static const _key = 'selected_role';
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);

    if (state != null) {
      state = null;
    }
  }

  Future<void> setRole(AppRole? role) async {
    state = role;

    final prefs = await SharedPreferences.getInstance();
    if (role == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, role.name);
    }
  }

  Future<void> clearRole() async {
    await setRole(null);
  }
}

final appRoleProvider =
    StateNotifierProvider<AppRoleNotifier, AppRole?>((ref) {
  return AppRoleNotifier();
});