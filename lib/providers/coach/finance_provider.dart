import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/coach/client_pass.dart';
import '../../services/coach/extra_backup_service.dart';
import 'passes_provider.dart';

/// Kategorie příjmů.
const incomeCategories = [
  'Osobní trénink',
  'Masáže',
  'Online koučink',
  'Jídelníčky',
  'Ostatní',
];

/// Kategorie permanentky podle názvu.
String categoryForTitle(String title) {
  final t = title.toLowerCase();
  if (t.contains('masáž') || t.contains('masaz')) return 'Masáže';
  if (t.contains('koučink') || t.contains('koucink') || t.contains('online')) {
    return 'Online koučink';
  }
  if (t.contains('jídelní') || t.contains('jidelni') || t.contains('strav')) {
    return 'Jídelníčky';
  }
  if (t.contains('trénink') || t.contains('trenink') || t.contains('vstup')) {
    return 'Osobní trénink';
  }
  return 'Ostatní';
}

/// Jednorázová platba (mimo permanentky) – např. jedna masáž, jídelníček.
class Payment {
  final String id;
  final String? clientId;
  final String clientName;
  final double amount;
  final DateTime date;
  final String category;
  final String note;

  const Payment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.amount,
    required this.date,
    required this.category,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
        'note': note,
      };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: (j['id'] ?? '').toString(),
        clientId: j['clientId'] as String?,
        clientName: (j['clientName'] ?? '').toString(),
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse((j['date'] ?? '').toString()) ?? DateTime.now(),
        category: (j['category'] ?? 'Ostatní').toString(),
        note: (j['note'] ?? '').toString(),
      );
}

class PaymentsNotifier extends StateNotifier<List<Payment>> {
  PaymentsNotifier() : super(const []) {
    _load();
  }

  static const key = 'coach_payments_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        state = [
          for (final e in d)
            if (e is Map) Payment.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
    } catch (_) {}
  }

  Future<void> _save(List<Payment> next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode([for (final p in next) p.toJson()]));
    ExtraBackupService.schedulePush();
  }

  Future<void> add(Payment p) => _save([p, ...state]);

  Future<void> delete(String id) =>
      _save(state.where((e) => e.id != id).toList());
}

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, List<Payment>>(
  (ref) => PaymentsNotifier(),
);

/// Jeden příjem pro statistiky (zaplacená permanentka nebo platba).
class IncomeEntry {
  final String id;
  final DateTime date;
  final double amount;
  final String category;
  final String clientName;
  final String title;

  /// Ruční platba (jde smazat), jinak permanentka.
  final bool manual;

  const IncomeEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.clientName,
    required this.title,
    required this.manual,
  });
}

/// Všechny příjmy: zaplacené permanentky s cenou + jednorázové platby.
final incomeEntriesProvider = Provider<List<IncomeEntry>>((ref) {
  final passes = ref.watch(passesProvider);
  final payments = ref.watch(paymentsProvider);
  return [
    for (final ClientPass p in passes)
      if (p.paid && p.price != null && p.price! > 0 && p.paidAt != null)
        IncomeEntry(
          id: p.id,
          date: p.paidAt!,
          amount: p.price!,
          category: categoryForTitle(p.title),
          clientName: p.clientName,
          title: p.title,
          manual: false,
        ),
    for (final p in payments)
      IncomeEntry(
        id: p.id,
        date: p.date,
        amount: p.amount,
        category: p.category,
        clientName: p.clientName,
        title: p.note.isEmpty ? p.category : p.note,
        manual: true,
      ),
  ]..sort((a, b) => b.date.compareTo(a.date));
});
