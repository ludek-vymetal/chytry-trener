import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/coach_client.dart';
import '../models/saved_meal_plan.dart';
import '../providers/saved_meal_plans_provider.dart';
import '../screens/custom_meal_plan_editor_screen.dart';
import '../screens/saved_meal_plans_screen.dart';
import '../../help/help_button.dart';
import 'meal_plan_actions.dart';

/// Karta v detailu klienta (záložka Strava): jídelníčky s vlastním
/// názvem, nový jídelníček, přepočet ze šablony.
class ClientMealPlansCard extends ConsumerWidget {
  final CoachClient client;

  const ClientMealPlansCard({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final plans = ref.watch(clientMealPlansProvider(client.clientId));

    Future<void> openEditor({SavedMealPlan? existing}) async {
      await MealPlanActions.activateClient(ref, client);
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomMealPlanEditorScreen(
            existing: existing,
            suggestedName: existing == null ? 'Jídelníček – ${client.firstName}' : null,
          ),
        ),
      );
    }

    Future<void> fromTemplate() async {
      final tpl = await MealPlanActions.pickPlan(
        context,
        ref,
        title: 'Šablona pro ${client.firstName}',
      );
      if (tpl == null || !context.mounted) return;
      await MealPlanActions.useForClient(context, ref, tpl, client: client);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jídelníčky klienta',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (plans.isNotEmpty)
                  Text('${plans.length}',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                const HelpButton(topic: 'meal_editor'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Jídelníčky s vlastním názvem. Klient s online koučinkem je '
              'uvidí ve své aplikaci v sekci Jídlo.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nový jídelníček'),
                ),
                FilledButton.tonalIcon(
                  onPressed: fromTemplate,
                  icon: const Icon(Icons.auto_awesome_motion_outlined),
                  label: const Text('Ze šablony'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedMealPlansScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.bookmarks_outlined),
                  label: const Text('Knihovna'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Zatím žádný uložený jídelníček.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            for (final p in plans)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restaurant_menu),
                title: Text(p.name),
                subtitle: Text(
                  '${MealPlanActions.summary(p)}\n'
                  'Upraveno ${MealPlanActions.date(p.updatedAt)}',
                ),
                isThreeLine: true,
                onTap: () => MealPlanActions.open(context, ref, p),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'edit':
                        await openEditor(existing: p);
                      case 'pdf':
                        await MealPlanActions.printPlan(context, p);
                      case 'share':
                        await MealPlanActions.printPlan(context, p,
                            share: true);
                      case 'rename':
                        await MealPlanActions.rename(context, ref, p);
                      case 'template':
                        await ref
                            .read(savedMealPlansProvider.notifier)
                            .duplicateAsTemplate(p);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Uloženo do knihovny jako obecná šablona.',
                              ),
                            ),
                          );
                        }
                      case 'delete':
                        await MealPlanActions.confirmDelete(context, ref, p);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Upravit')),
                    PopupMenuItem(value: 'pdf', child: Text('Tisk / PDF')),
                    PopupMenuItem(value: 'share', child: Text('Sdílet PDF')),
                    PopupMenuItem(value: 'rename', child: Text('Přejmenovat')),
                    PopupMenuItem(
                      value: 'template',
                      child: Text('Uložit jako obecnou šablonu'),
                    ),
                    PopupMenuItem(value: 'delete', child: Text('Smazat')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
