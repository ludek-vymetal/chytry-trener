import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/subscription/subscription_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/food_exclusions_provider.dart';
import '../../../services/pdf/choice_meal_plan_pdf_service.dart';
import '../../help/help_button.dart';
import '../../paywall/paywall_screen.dart';
import '../logic/choice_meal_plan.dart';
import '../models/carb_cycling_plan.dart';

/// Výběrový stravovací plán – ke každému jídlu dne 10 možností se
/// stejnými makroživinami. Klient si vybírá podle chuti.
class ChoiceMealPlanScreen extends ConsumerWidget {
  const ChoiceMealPlanScreen({super.key});

  /// Ve zkušební verzi se u každého jídla ukážou jen první 3 možnosti.
  static const _freeOptions = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final access = ref.watch(accessProvider);
    // Při změně alergií se plán přepočítá.
    final excluded = ref.watch(activeFoodExclusionsProvider);

    if (profile == null || profile.goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Výběrový stravovací plán')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nejdřív vyplň profil a cíl – z nich se plán spočítá.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final plan = ChoiceMealPlan.forProfile(profile, l10n);
    final full = access.fullMealPlan;

    Future<void> doPrint({required bool share}) async {
      if (!await requireFull(context, ref, 'Tisk výběrového plánu')) return;
      if (share) {
        await ChoiceMealPlanPdfService.sharePlan(plan);
      } else {
        await ChoiceMealPlanPdfService.printPlan(plan);
      }
    }

    Widget macroChip(String label, String value) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(label,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        );

    return DefaultTabController(
      length: plan.groups.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Výběrový stravovací plán'),
          actions: [
            IconButton(
              tooltip: l10n.printPdf,
              icon: const Icon(Icons.print_outlined),
              onPressed: () => doPrint(share: false),
            ),
            IconButton(
              tooltip: l10n.sharePdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => doPrint(share: true),
            ),
            const HelpButton(topic: 'food'),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final g in plan.groups) Tab(text: g.slot.label)],
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: cs.primaryContainer,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Každý den si z každého jídla vyber jednu možnost. '
                    'Všechny možnosti mají téměř stejné kalorie i makroživiny, '
                    'takže je můžeš libovolně střídat.',
                    style: TextStyle(color: cs.onPrimaryContainer),
                  ),
                  if (excluded.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.no_food_outlined,
                            size: 18, color: cs.onPrimaryContainer),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Bez: ${excluded.join(', ')}',
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      macroChip('kcal / den', '${plan.kcal.round()}'),
                      macroChip('bílkoviny', '${plan.protein.round()} g'),
                      macroChip('sacharidy', '${plan.carbs.round()} g'),
                      macroChip('tuky', '${plan.fats.round()} g'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final g in plan.groups)
                    _GroupList(
                      group: g,
                      limit: full ? null : _freeOptions,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupList extends StatelessWidget {
  final ChoiceMealGroup group;
  final int? limit;

  const _GroupList({required this.group, required this.limit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lim = limit;
    final shown = lim == null ? group.options : group.options.take(lim).toList();
    final hidden = group.options.length - shown.length;

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
      const spacing = 12.0;
      final w = (c.maxWidth - 32 - spacing * (cols - 1)) / cols;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            '${group.slot.label} · vyber si 1 z ${group.options.length}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            'Cíl jídla: ~${group.kcal.round()} kcal · B ${group.protein.round()} g · '
            'S ${group.carbs.round()} g · T ${group.fats.round()} g',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (var i = 0; i < shown.length; i++)
                SizedBox(width: w, child: _OptionCard(meal: shown[i], n: i + 1)),
            ],
          ),
          if (hidden > 0) ...[
            const SizedBox(height: 16),
            LockedFeatureCard(
              feature: 'Dalších $hidden možností',
              description: 'V plné verzi uvidíš u každého jídla všech '
                  '${group.options.length} možností a plán vytiskneš.',
            ),
          ],
        ],
      );
    });
  }
}

class _OptionCard extends StatelessWidget {
  final PlannedMeal meal;
  final int n;
  const _OptionCard({required this.meal, required this.n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = meal.name.isEmpty
        ? meal.name
        : '${meal.name[0].toUpperCase()}${meal.name.substring(1)}';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  child: Text(
                    '$n',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final i in meal.ingredients)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        i.unit == 'ks'
                            ? '${i.amount.round()} ks'
                            : '${i.amount.round()} ${i.unit}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(child: Text(i.name)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${(meal.calories ?? 0).round()} kcal · '
              'B ${(meal.protein ?? 0).round()} g · '
              'S ${(meal.carbs ?? 0).round()} g · '
              'T ${(meal.fats ?? 0).round()} g',
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
