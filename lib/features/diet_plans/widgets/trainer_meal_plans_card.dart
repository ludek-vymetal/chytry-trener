import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coaching/workout_widgets.dart';
import '../providers/saved_meal_plans_provider.dart';
import 'meal_plan_actions.dart';

/// U klienta s online koučinkem: jídelníčky, které mu připravil trenér.
/// Bez propojení s trenérem se nezobrazí.
class TrainerMealPlansCard extends ConsumerWidget {
  const TrainerMealPlansCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(clientLinkProvider).valueOrNull;
    if (link == null) return const SizedBox.shrink();
    final plans = ref.watch(clientMealPlansProvider(link.clientId));
    if (plans.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final coach = (link.coachName ?? '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: cs.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book, color: cs.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      coach.isEmpty
                          ? 'Jídelníček od trenéra'
                          : 'Jídelníček od trenéra ($coach)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              for (final p in plans)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  subtitle: Text(
                    MealPlanActions.summary(p),
                    style: TextStyle(color: cs.onPrimaryContainer),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: cs.onPrimaryContainer),
                  onTap: () => MealPlanActions.open(context, ref, p),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
