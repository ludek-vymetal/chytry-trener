import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nutrition/hollywood_prep.dart';
import '../../l10n/app_localizations.dart';
import '../../models/diet_preference.dart';
import '../../models/custom_training_plan.dart';
import '../../models/goal.dart';
import '../../models/user_profile.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../providers/diet_settings_provider.dart';
import '../../providers/user_profile_provider.dart';
import 'logic/keto_calculator.dart';
import 'providers/diet_plan_provider.dart';
import 'models/carb_cycling_plan.dart';
import 'screens/carb_cycling_logic.dart';
import 'screens/carb_cycling_result_screen.dart';
import 'screens/carb_cycling_survey_screen.dart';
import 'screens/daily_menu_screen.dart';
import 'screens/keto_result_screen.dart';
import 'screens/saved_meal_plans_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/weekly_meal_plan_screen.dart';
import 'screens/choice_meal_plan_screen.dart';
import 'widgets/food_exclusions_card.dart';

class DietStrategyScreen extends ConsumerWidget {
  const DietStrategyScreen({super.key});

  /// Když má klient aktivní jídelníček programu (Hollywood, Bikini,
  /// Kulatý zadek, Silová příprava), jeho změna přepočítá makra v celé
  /// aplikaci – proto se nejdřív zeptáme. U ostatních stylů bez dotazu.
  Future<bool> _confirmLeaveProgram(
    BuildContext context,
    UserProfile current,
    String newPlan,
    AppLocalizations l10n,
  ) async {
    final currentProgram = ProgramDiets.nameFor(current.selectedPlan);
    if (currentProgram == null || current.selectedPlan == newPlan) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changeMealPlanTitle),
        content: Text(l10n.changeMealPlanBody(currentProgram)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.changeMealPlanConfirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _selectStartTime(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.read(userProfileProvider);

    if (profile == null) return;

    if (!await _confirmLeaveProgram(context, profile, 'Fasting', l10n)) {
      return;
    }
    if (!context.mounted) return;

    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    final selectedHours = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.fastingLengthQuestion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fastingOption(
              dialogContext,
              12,
              l10n.fastingBeginner,
            ),
            _fastingOption(
              dialogContext,
              14,
              l10n.fastingIntermediate,
            ),
            _fastingOption(
              dialogContext,
              16,
              l10n.fastingClassic,
            ),
            _fastingOption(
              dialogContext,
              18,
              l10n.fastingAdvanced,
            ),
            _fastingOption(
              dialogContext,
              20,
              l10n.fastingWarrior,
            ),
          ],
        ),
      ),
    );

    if (selectedHours == null) return;
    if (!context.mounted) return;

    final picked = await showTimePicker(
      context: context,
      initialTime:
          profile.fastingStartTime ??
          const TimeOfDay(hour: 10, minute: 0),
      helpText: l10n.fastingWindowQuestion,
    );

    if (picked != null) {
      final currentProfile = ref.read(userProfileProvider);

      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          fastingStartTime: picked,
          isFasting: true,
          selectedPlan: 'Fasting',
          fastingDuration: selectedHours,
        );

        ref
            .read(userProfileProvider.notifier)
            .updateProfile(updatedProfile);

        final fastingPlan =
            CarbCyclingCalculator.generateFastingMealPlan(
          profile: updatedProfile,
          l10n: l10n,
          excluded: ref.read(excludedIngredientsProvider),
        );

        ref.read(dietPlanProvider.notifier).state =
            fastingPlan;
      }

      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.fastingConfigured(
              selectedHours,
              picked.format(context),
            ),
          ),
          backgroundColor: colorScheme.primary,
        ),
      );
    }
  }

  Widget _fastingOption(
    BuildContext context,
    int hours,
    String label,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(label),
      leading: Icon(
        Icons.timer_outlined,
        color: colorScheme.secondary,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pop(context, hours),
    );
  }

  void _showIngredientCheck(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (dialogContext, dialogRef, child) {
          final currentExcluded =
              dialogRef.watch(excludedIngredientsProvider);

          return AlertDialog(
            title: Text(l10n.ingredientsWeekTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.ingredientsExcludeTitle),

                const Divider(),

                CheckboxListTile(
                  value: currentExcluded.contains('Losos'),
                  onChanged: (_) => dialogRef
                      .read(
                        excludedIngredientsProvider.notifier,
                      )
                      .toggleIngredient('Losos'),
                  title: Text(l10n.salmonOption),
                  contentPadding: EdgeInsets.zero,
                ),

                CheckboxListTile(
                  value: currentExcluded.contains('Vejce'),
                  onChanged: (_) => dialogRef
                      .read(
                        excludedIngredientsProvider.notifier,
                      )
                      .toggleIngredient('Vejce'),
                  title: Text(l10n.eggs),
                  contentPadding: EdgeInsets.zero,
                ),

                CheckboxListTile(
                  value: currentExcluded.contains(
                    'Hovězí maso',
                  ),
                  onChanged: (_) => dialogRef
                      .read(
                        excludedIngredientsProvider.notifier,
                      )
                      .toggleIngredient('Hovězí maso'),
                  title: Text(l10n.beef),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: Text(
                  l10n.cancel.toUpperCase(),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  final profile =
                      dialogRef.read(userProfileProvider);

                  if (profile == null) {
                    Navigator.pop(dialogContext);
                    return;
                  }

                  dialogRef
                      .read(userProfileProvider.notifier)
                      .updateProfile(
                        profile.copyWith(selectedPlan: 'Keto'),
                      );

                  final ketoMacros =
                      KetoCalculator.calculateMacros(
                    profile,
                    l10n,
                  );

                  final ketoPlan =
                      KetoCalculator.generateWeeklyKetoMealPlan(
                    protein:
                        ketoMacros['protein'] ?? 0,
                    fats:
                        ketoMacros['fats'] ?? 0,
                    carbs:
                        ketoMacros['carbs'] ?? 30,
                    excludedFoods: dialogRef.read(
                      excludedIngredientsProvider,
                    ),
                    l10n: l10n,
                    preference: profile.diet,
                    budget: profile.budget,
                  );

                  ref
                      .read(dietPlanProvider.notifier)
                      .state = ketoPlan;

                  Navigator.pop(dialogContext);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KetoResultScreen(
                        macros: ketoMacros,
                        plan: ketoPlan,
                      ),
                    ),
                  );
                },
                child: Text(
                  l10n.generatePlanButton,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _activateLinearPlan(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final current = ref.read(userProfileProvider);

    if (current == null) return;

    if (!await _confirmLeaveProgram(context, current, 'Linear', l10n)) return;
    if (!context.mounted) return;

    final linearPlan =
        CarbCyclingCalculator.createLinearPlan(
      profile: current,
      l10n: l10n,
    );

    ref.read(userProfileProvider.notifier).updateProfile(
          current.copyWith(selectedPlan: 'Linear'),
        );

    ref.read(dietPlanProvider.notifier).state =
        linearPlan.mealPlan;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CarbCyclingResultScreen(plan: linearPlan),
      ),
    );
  }

  /// Výběr data natáčení / závodu pro jídelníček programu.
  ///
  /// Předvyplní se [saved] (z profilu), jinak datum z tréninkového plánu
  /// klienta ([fromPlan]), jinak dnešek + délka přípravy (dnes = 1. týden).
  Future<DateTime?> _pickProgramDate(
    BuildContext context, {
    required DateTime? saved,
    required DateTime? fromPlan,
    required int totalWeeks,
    required String helpText,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = today.add(const Duration(days: 730));

    var initialDate =
        saved ?? fromPlan ?? today.add(Duration(days: totalWeeks * 7 - 1));
    if (initialDate.isBefore(today)) initialDate = today;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
      helpText: helpText,
    );
  }

  /// Datum z nejnovějšího tréninkového plánu klienta daného typu.
  DateTime? _dateFromTrainingPlan(
    WidgetRef ref,
    String? clientId,
    bool Function(CustomTrainingPlan plan) isType,
  ) {
    final plans = ref
        .read(customTrainingPlanProvider)
        .where(
          (p) => p.clientId == clientId && isType(p) && p.meetDate != null,
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return plans.isEmpty ? null : plans.first.meetDate;
  }

  void _openProgramPlan(
    BuildContext context,
    WidgetRef ref,
    UserProfile updated,
    CarbCyclingPlan plan,
  ) {
    ref.read(userProfileProvider.notifier).updateProfile(updated);
    ref.read(dietPlanProvider.notifier).state = plan.mealPlan;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarbCyclingResultScreen(plan: plan),
      ),
    );
  }

  /// Hollywood training: datum natáčení → jídelníček podle fáze přípravy.
  Future<void> _activateHollywoodPlan(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final current = ref.read(userProfileProvider);

    if (current == null) return;

    if (!await _confirmLeaveProgram(context, current, HollywoodPrep.planKey, l10n)) return;
    if (!context.mounted) return;

    final picked = await _pickProgramDate(
      context,
      saved: current.hollywoodShootDate,
      fromPlan: _dateFromTrainingPlan(
        ref,
        current.clientId,
        (p) => p.isHollywoodPrep,
      ),
      totalWeeks: HollywoodPrep.totalWeeks,
      helpText: l10n.hollywoodShootDate,
    );

    if (picked == null || !context.mounted) return;

    final updated = current.copyWith(
      selectedPlan: HollywoodPrep.planKey,
      hollywoodShootDate: picked,
    );

    _openProgramPlan(
      context,
      ref,
      updated,
      CarbCyclingCalculator.createHollywoodPlan(profile: updated, l10n: l10n),
    );
  }

  /// Bikini fitness: datum závodu → jídelníček podle fáze přípravy.
  Future<void> _activateBikiniPlan(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final current = ref.read(userProfileProvider);

    if (current == null) return;

    if (!await _confirmLeaveProgram(context, current, BikiniPrep.planKey, l10n)) return;
    if (!context.mounted) return;

    final picked = await _pickProgramDate(
      context,
      saved: current.bikiniMeetDate,
      fromPlan: _dateFromTrainingPlan(
        ref,
        current.clientId,
        (p) => p.isBikiniMeetPrep,
      ),
      totalWeeks: BikiniPrep.totalWeeks,
      helpText: l10n.meetDate,
    );

    if (picked == null || !context.mounted) return;

    final updated = current.copyWith(
      selectedPlan: BikiniPrep.planKey,
      bikiniMeetDate: picked,
    );

    _openProgramPlan(
      context,
      ref,
      updated,
      CarbCyclingCalculator.createBikiniPlan(profile: updated, l10n: l10n),
    );
  }

  /// Silová příprava: údržba s vysokými sacharidy (bench / trojboj).
  Future<void> _activateStrengthPlan(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final current = ref.read(userProfileProvider);

    if (current == null) return;

    if (!await _confirmLeaveProgram(context, current, StrengthPlan.planKey, l10n)) return;
    if (!context.mounted) return;

    final updated = current.copyWith(selectedPlan: StrengthPlan.planKey);

    _openProgramPlan(
      context,
      ref,
      updated,
      CarbCyclingCalculator.createStrengthPlan(profile: updated, l10n: l10n),
    );
  }

  /// Kulatý zadek: mírný přebytek pro růst hýždí.
  Future<void> _activateGlutePlan(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final current = ref.read(userProfileProvider);

    if (current == null) return;

    if (!await _confirmLeaveProgram(context, current, GlutePlan.planKey, l10n)) return;
    if (!context.mounted) return;

    final updated = current.copyWith(selectedPlan: GlutePlan.planKey);

    _openProgramPlan(
      context,
      ref,
      updated,
      CarbCyclingCalculator.createGlutePlan(profile: updated, l10n: l10n),
    );
  }

  Future<void> _activateKetoPlan(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(userProfileProvider);

    if (current == null) return;

    if (!await _confirmLeaveProgram(context, current, 'Keto', l10n)) return;
    if (!context.mounted) return;

    // Styl stravy se přepne až po potvrzení v dialogu (zrušení nic nemění).
    _showIngredientCheck(context, ref);
  }

  /// Aktuální jídelníček podle zvoleného stylu stravy. Výpočet je
  /// deterministický (v rámci týdne stejný), takže se dá kdykoli znovu
  /// otevřít – bez nutnosti plán „aktivovat“ znovu.
  DietMealPlan? _currentMealPlan(
    WidgetRef ref,
    UserProfile profile,
    AppLocalizations l10n,
  ) {
    final excluded = ref.read(excludedIngredientsProvider);

    switch (profile.selectedPlan) {
      case 'Linear':
        return CarbCyclingCalculator.createLinearPlan(
          profile: profile,
          l10n: l10n,
        ).mealPlan;
      case 'Vlny':
        return CarbCyclingCalculator.calculate(
          profile: profile,
          l10n: l10n,
        ).mealPlan;
      case 'Keto':
        final m = KetoCalculator.calculateMacros(profile, l10n);
        return KetoCalculator.generateWeeklyKetoMealPlan(
          protein: m['protein'] ?? 0,
          fats: m['fats'] ?? 0,
          carbs: m['carbs'] ?? 30,
          excludedFoods: excluded,
          l10n: l10n,
          preference: profile.diet,
          budget: profile.budget,
        );
      case 'Fasting':
        return CarbCyclingCalculator.generateFastingMealPlan(
          profile: profile,
          l10n: l10n,
          excluded: excluded,
        );
      case HollywoodPrep.planKey:
        return CarbCyclingCalculator.createHollywoodPlan(
          profile: profile,
          l10n: l10n,
        ).mealPlan;
      case BikiniPrep.planKey:
        return CarbCyclingCalculator.createBikiniPlan(
          profile: profile,
          l10n: l10n,
        ).mealPlan;
      case GlutePlan.planKey:
        return CarbCyclingCalculator.createGlutePlan(
          profile: profile,
          l10n: l10n,
        ).mealPlan;
      case StrengthPlan.planKey:
        return CarbCyclingCalculator.createStrengthPlan(
          profile: profile,
          l10n: l10n,
        ).mealPlan;
    }
    return null;
  }

  String _planName(String selectedPlan, AppLocalizations l10n) {
    switch (selectedPlan) {
      case 'Linear':
        return l10n.linearPlanTitle;
      case 'Vlny':
        return l10n.carbCyclingTitle;
      case 'Keto':
        return l10n.ketoDietTitle;
      case 'Fasting':
        return l10n.fastingTitle;
    }
    return ProgramDiets.nameFor(selectedPlan) ?? selectedPlan;
  }

  /// Karta „Můj jídelníček“: celý týden, nákupní seznam a uložené
  /// jídelníčky na jednom místě.
  Widget _myPlanCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    AppLocalizations l10n,
  ) {
    void openWith(Widget Function(DietMealPlan plan) builder) {
      final plan = _currentMealPlan(ref, profile, l10n);
      if (plan == null) return;
      ref.read(dietPlanProvider.notifier).state = plan;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => builder(plan)),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.myMealPlan}: ${_planName(profile.selectedPlan, l10n)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => openWith(
                    (plan) => WeeklyMealPlanScreen(mealPlan: plan),
                  ),
                  icon: const Icon(Icons.calendar_view_week),
                  label: Text(l10n.openMealPlan),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => openWith(
                    (plan) => ShoppingListScreen(mealPlan: plan),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(l10n.shoppingList),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedMealPlansScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.bookmark_outline),
                  label: Text(l10n.savedMealPlans),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(userProfileProvider);

    final isFastingSelected =
        profile?.selectedPlan == 'Fasting';

    // Podpora při poruše příjmu potravy: žádné restriktivní diety
    // (keto, přerušovaný půst).
    final restrictiveBlocked =
        profile?.goal?.reason == GoalReason.eatingDisorderSupport;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dietPlanSelection),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile != null) ...[
            _myPlanCard(context, ref, profile, l10n),
            const SizedBox(height: 16),
            const FoodExclusionsCard(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dietPreferenceTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.dietPreferenceHint),
                    const SizedBox(height: 12),
                    SegmentedButton<DietPreference>(
                      segments: [
                        ButtonSegment(
                          value: DietPreference.none,
                          label: Text(l10n.dietNone),
                        ),
                        ButtonSegment(
                          value: DietPreference.vegetarian,
                          label: Text(l10n.dietVegetarian),
                        ),
                        ButtonSegment(
                          value: DietPreference.vegan,
                          label: Text(l10n.dietVegan),
                        ),
                      ],
                      selected: {profile.diet},
                      onSelectionChanged: (selection) {
                        ref.read(userProfileProvider.notifier).updateProfile(
                              profile.copyWith(
                                dietPreference: selection.first,
                              ),
                            );
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.savings_outlined),
                      title: Text(l10n.budgetMealsTitle),
                      subtitle: Text(l10n.budgetMealsHint),
                      value: profile.budget,
                      onChanged: (value) {
                        ref.read(userProfileProvider.notifier).updateProfile(
                              profile.copyWith(budgetMeals: value),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _StrategyCard(
            title: l10n.linearPlanTitle,
            description:
                l10n.linearPlanDescription,
            icon: Icons.horizontal_rule,
            isActive:
                profile?.selectedPlan == 'Linear',
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () =>
                      _activateLinearPlan(
                    context,
                    ref,
                    l10n,
                  ),
                  child: Text(
                    l10n.activateAndOpenPlan,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _StrategyCard(
            title: 'Výběrový stravovací plán',
            description:
                'Místo pevného jídelníčku ke každému jídlu dne až 10 možností '
                'se stejnými kaloriemi a makroživinami – snídaně, svačiny, '
                'oběd i večeře. Tiskne se jako brožura: každé jídlo na vlastní '
                'stránce a klient si vybírá podle toho, na co má zrovna chuť.',
            icon: Icons.menu_book_outlined,
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChoiceMealPlanScreen(),
                    ),
                  ),
                  child: const Text('Otevřít výběrový plán'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _StrategyCard(
            title: l10n.carbCyclingTitle,
            description:
                l10n.carbCyclingDescription,
            icon: Icons.show_chart,
            isActive:
                profile?.selectedPlan == 'Vlny',
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CarbCyclingSurveyScreen(),
                      ),
                    );
                  },
                  child: Text(
                    l10n.startAnalysisAndCycling,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _StrategyCard(
            title: GlutePlan.name,
            description: l10n.gluteDietDescription,
            icon: Icons.favorite_outline,
            isActive: profile?.selectedPlan == GlutePlan.planKey,
            actions: [
              _fullWidthButton(
                child: FilledButton.icon(
                  onPressed: () => _activateGlutePlan(
                    context,
                    ref,
                    l10n,
                  ),
                  icon: const Icon(Icons.restaurant_menu),
                  label: Text(l10n.gluteActivate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _StrategyCard(
            title: StrengthPlan.name,
            description: l10n.strengthDietDescription,
            icon: Icons.fitness_center,
            isActive: profile?.selectedPlan == StrengthPlan.planKey,
            actions: [
              _fullWidthButton(
                child: FilledButton.icon(
                  onPressed: () => _activateStrengthPlan(
                    context,
                    ref,
                    l10n,
                  ),
                  icon: const Icon(Icons.restaurant_menu),
                  label: Text(l10n.strengthActivate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (restrictiveBlocked)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.restrictiveDietsHidden),
              ),
            )
          else ...[
          _StrategyCard(
            title: l10n.ketoDietTitle,
            description:
                l10n.ketoDietDescription,
            icon: Icons.ac_unit,
            isActive:
                profile?.selectedPlan == 'Keto',
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () =>
                      _activateKetoPlan(
                    context,
                    ref,
                  ),
                  child: Text(
                    l10n.selectKetoAndPreferences,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _StrategyCard(
            title: l10n.fastingTitle,
            description:
                l10n.fastingDescription,
            icon: Icons.timer,
            isActive: isFastingSelected,
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () =>
                      _selectStartTime(
                    context,
                    ref,
                  ),
                  child: Text(
                    profile?.fastingStartTime !=
                            null
                        ? l10n.editTime(
                            profile!
                                .fastingStartTime!
                                .format(context),
                          )
                        : l10n.setMealTimes,
                  ),
                ),
              ),

              if (isFastingSelected &&
                  profile?.fastingStartTime !=
                      null) ...[
                const SizedBox(height: 12),

                _fullWidthButton(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const DailyMenuScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.restaurant_menu,
                    ),
                    label: Text(
                      l10n.enterMealPlan,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          _StrategyCard(
            title: l10n.hollywoodTitle,
            description: l10n.hollywoodDescription,
            icon: Icons.movie_filter_outlined,
            isActive:
                profile?.selectedPlan == HollywoodPrep.planKey,
            actions: [
              _fullWidthButton(
                child: FilledButton.icon(
                  onPressed: () => _activateHollywoodPlan(
                    context,
                    ref,
                    l10n,
                  ),
                  icon: const Icon(Icons.event),
                  label: Text(l10n.hollywoodSelectDate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _StrategyCard(
            title: BikiniPrep.name,
            description: l10n.bikiniDietDescription,
            icon: Icons.emoji_events_outlined,
            isActive: profile?.selectedPlan == BikiniPrep.planKey,
            actions: [
              _fullWidthButton(
                child: FilledButton.icon(
                  onPressed: () => _activateBikiniPlan(
                    context,
                    ref,
                    l10n,
                  ),
                  icon: const Icon(Icons.event),
                  label: Text(l10n.bikiniSelectDate),
                ),
              ),
            ],
          ),
          ],
        ],
      ),
    );
  }

  Widget _fullWidthButton({
    required Widget child,
  }) {
    return SizedBox(
      width: double.infinity,
      child: child,
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isActive;
  final List<Widget> actions;

  const _StrategyCard({
    required this.title,
    required this.description,
    required this.icon,
    this.isActive = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: isActive ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme
                          .onSurfaceVariant,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment:
                            WrapCrossAlignment
                                .center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                              color: colorScheme
                                  .onSurface,
                            ),
                          ),

                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        description,
                        style: TextStyle(
                          color: colorScheme
                              .onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
}