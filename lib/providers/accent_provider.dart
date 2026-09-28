import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Barva aplikace, kterou si trenér/ka nebo klient vybere v nastavení.
class AppAccent {
  final String id;
  final String name;
  final Color color;

  const AppAccent(this.id, this.name, this.color);

  static const emerald = AppAccent('emerald', 'Smaragdová', Color(0xFF0F766E));

  static const all = <AppAccent>[
    emerald,
    AppAccent('pink', 'Růžová', Color(0xFFD6336C)),
    AppAccent('violet', 'Fialová', Color(0xFF7C3AED)),
    AppAccent('blue', 'Modrá', Color(0xFF1D4ED8)),
    AppAccent('orange', 'Oranžová', Color(0xFFEA580C)),
    AppAccent('graphite', 'Grafitová', Color(0xFF334155)),
  ];

  static AppAccent byId(String? id) =>
      all.firstWhere((a) => a.id == id, orElse: () => emerald);
}

final accentProvider =
    NotifierProvider<AccentController, AppAccent>(AccentController.new);

class AccentController extends Notifier<AppAccent> {
  static const _key = 'app_accent';

  @override
  AppAccent build() {
    _load();
    return AppAccent.emerald;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppAccent.byId(prefs.getString(_key));
  }

  Future<void> setAccent(AppAccent accent) async {
    state = accent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, accent.id);
  }
}
