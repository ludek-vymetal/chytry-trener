import '../../../l10n/app_localizations.dart';
import '../../../models/user_profile.dart';
import '../models/carb_cycling_plan.dart';
import 'diet_macro_service.dart';
import 'food_catalog.dart';
import 'meal_composer.dart';

/// Jedno jídlo dne a všechny možnosti, ze kterých si klient vybírá.
class ChoiceMealGroup {
  final MealSlot slot;
  final double protein;
  final double carbs;
  final double fats;
  final List<PlannedMeal> options;

  const ChoiceMealGroup({
    required this.slot,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.options,
  });

  double get kcal => protein * 4 + carbs * 4 + fats * 9;
}

/// Výběrový stravovací plán: místo pevného jídelníčku na každý den
/// dostane klient ke každému jídlu dne (snídaně, svačina, oběd…) až
/// 10 možností se stejnými makroživinami a sám si vybírá, na co má chuť.
class ChoiceMealPlan {
  final String clientName;
  final double protein;
  final double carbs;
  final double fats;
  final bool keto;
  final List<ChoiceMealGroup> groups;
  final DateTime createdAt;

  /// Vynechané potraviny (alergie, nesnášenlivost, nechce jíst).
  final List<String> excluded;

  const ChoiceMealPlan({
    required this.clientName,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.keto,
    required this.groups,
    required this.createdAt,
    this.excluded = const [],
  });

  double get kcal => protein * 4 + carbs * 4 + fats * 9;

  static ChoiceMealPlan forProfile(
    UserProfile profile,
    AppLocalizations l10n, {
    int count = 10,
  }) {
    final keto = profile.selectedPlan.toLowerCase() == 'keto';
    final t =
        keto ? DietMacroService.keto(profile) : DietMacroService.linear(profile);

    final slots = keto
        ? MealComposer.ketoSlots(
            breakfast: l10n.breakfast,
            snack: l10n.snack,
            lunch: l10n.lunch,
            dinner: l10n.dinner,
          )
        : MealComposer.standardSlots(
            breakfast: l10n.breakfast,
            snack: 'Dopolední svačina',
            lunch: l10n.lunch,
            snack2: 'Odpolední svačina',
            dinner: l10n.dinner,
          );

    final groups = <ChoiceMealGroup>[
      for (var i = 0; i < slots.length; i++)
        ChoiceMealGroup(
          slot: slots[i],
          protein: t.protein * slots[i].proteinShare,
          carbs: t.carbs * slots[i].carbsShare,
          fats: t.fats * slots[i].fatShare,
          options: MealComposer.composeOptions(
            slot: slots[i],
            protein: t.protein,
            carbs: t.carbs,
            fats: t.fats,
            style: keto ? DietStyle.keto : DietStyle.standard,
            preference: profile.diet,
            count: count,
            // Druhá svačina / večeře nezačínají stejnými jídly jako
            // první svačina / oběd.
            offset: i * 3,
          ),
        ),
    ];

    return ChoiceMealPlan(
      clientName: profile.displayName,
      protein: t.protein,
      carbs: t.carbs,
      fats: t.fats,
      keto: keto,
      groups: groups,
      createdAt: DateTime.now(),
      excluded: FoodCatalog.activeExclusions,
    );
  }
}
