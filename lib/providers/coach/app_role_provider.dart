import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole { user, coach }

/// true, jakmile je uložená role načtená z disku.
/// Do té doby RoleGate ukazuje loader (aby neproblikl výběr role).
final appRoleReadyProvider = StateProvider<bool>((ref) => false);

class AppRoleNotifier extends StateNotifier<AppRole?> {
  AppRoleNotifier(this._ref) : super(null) {
    _init();
  }

  final Ref _ref;

  static const _key = 'selected_role';
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);

      AppRole? restored;
      for (final r in AppRole.values) {
        if (r.name == saved) restored = r;
      }

      if (mounted && restored != null) {
        state = restored;
      }
    } finally {
      if (mounted) {
        _ref.read(appRoleReadyProvider.notifier).state = true;
      }
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
  return AppRoleNotifier(ref);
});
