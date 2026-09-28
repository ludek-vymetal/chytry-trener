import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/diet_plans/logic/food_catalog.dart';
import 'coach/active_client_provider.dart';
import 'coach/coach_client_details_controller.dart';

/// Klient, jehož jídelníčky se právě počítají (bez vybraného klienta
/// = vlastní profil uživatele).
final exclusionsClientIdProvider = Provider<String>((ref) {
  final id = ref.watch(activeClientIdProvider).valueOrNull;
  return (id == null || id.trim().isEmpty) ? 'local_user' : id;
});

/// Alergie, nesnášenlivosti a neoblíbená jídla aktivního klienta.
///
/// Zároveň je předá do [FoodCatalog.activeExclusions], takže je
/// automaticky vynechávají všechny generátory jídelníčků.
final activeFoodExclusionsProvider = Provider<List<String>>((ref) {
  final id = ref.watch(exclusionsClientIdProvider);
  final d = ref.watch(coachClientDetailsForClientProvider(id)).valueOrNull;
  final list = d == null
      ? const <String>[]
      : FoodCatalog.parseExclusions(
          '${d.allergies}, ${d.intolerances}, ${d.dislikedFoods}',
        );
  FoodCatalog.activeExclusions = list;
  return list;
});
