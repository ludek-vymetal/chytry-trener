import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/coach/client_pass.dart';
import '../../services/coach/extra_backup_service.dart';

/// Permanentky a platby klientů (uloženo v zařízení trenéra,
/// zálohuje se do cloudu s ostatními daty).
class PassesNotifier extends StateNotifier<List<ClientPass>> {
  PassesNotifier() : super(const []) {
    _load();
  }

  static const key = 'coach_passes_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (!mounted || raw == null || raw.isEmpty) return;
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        state = [
          for (final e in d)
            if (e is Map) ClientPass.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
    } catch (_) {}
  }

  Future<void> _save(List<ClientPass> next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode([for (final p in next) p.toJson()]),
    );
    ExtraBackupService.schedulePush();
  }

  Future<void> upsert(ClientPass p) async {
    final exists = state.any((e) => e.id == p.id);
    await _save(
      exists ? [for (final e in state) e.id == p.id ? p : e] : [p, ...state],
    );
  }

  Future<void> delete(String id) =>
      _save(state.where((e) => e.id != id).toList());

  /// Odečte jeden vstup (dnešním datem, nebo zadaným).
  Future<void> useVisit(String id, {DateTime? date}) async {
    final p = state.firstWhere((e) => e.id == id);
    if (p.isUsedUp) return;
    await upsert(p.copyWith(uses: [...p.uses, date ?? DateTime.now()]));
  }

  /// Vrátí poslední odečtený vstup.
  Future<void> undoVisit(String id) async {
    final p = state.firstWhere((e) => e.id == id);
    if (p.uses.isEmpty) return;
    final uses = [...p.uses]..removeLast();
    await upsert(p.copyWith(uses: uses));
  }

  Future<void> markPaid(String id, bool paid) async {
    final p = state.firstWhere((e) => e.id == id);
    await upsert(
      paid
          ? p.copyWith(paid: true, paidAt: DateTime.now())
          : p.copyWith(paid: false, clearPaidAt: true),
    );
  }
}

final passesProvider =
    StateNotifierProvider<PassesNotifier, List<ClientPass>>(
  (ref) => PassesNotifier(),
);

/// Permanentky jednoho klienta (nejnovější první).
final clientPassesProvider =
    Provider.family<List<ClientPass>, String>((ref, clientId) {
  final list = [
    for (final p in ref.watch(passesProvider))
      if (p.clientId == clientId) p,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
});
