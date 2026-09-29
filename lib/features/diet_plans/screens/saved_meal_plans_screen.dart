import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../coaching/workout_widgets.dart';
import '../models/custom_meal_plan_models.dart';
import '../models/saved_meal_plan.dart';
import '../providers/custom_meal_plan_templates_provider.dart';
import '../providers/saved_meal_plans_provider.dart';
import '../widgets/meal_plan_actions.dart';
import 'custom_meal_plan_editor_screen.dart';
import 'daily_meal_plan_editor_screen.dart';

enum _Filter { all, templates, clients }

/// Knihovna jídelníčků. Každý uložený jídelníček (obecná šablona i
/// jídelníček klienta) jde otevřít, upravit, vytisknout a přepočítat
/// pro jiného klienta.
class SavedMealPlansScreen extends ConsumerStatefulWidget {
  const SavedMealPlansScreen({super.key});

  @override
  ConsumerState<SavedMealPlansScreen> createState() =>
      _SavedMealPlansScreenState();
}

class _SavedMealPlansScreenState extends ConsumerState<SavedMealPlansScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plans = ref.watch(savedMealPlansProvider);
    final dailyTemplates = ref.watch(customMealPlanTemplatesProvider);
    final readOnly = ref.watch(clientLinkProvider).valueOrNull != null;
    final coach = MealPlanActions.isCoach(ref);

    final q = _query.trim().toLowerCase();
    final shown = plans.where((p) {
      if (_filter == _Filter.templates && !p.isTemplate) return false;
      if (_filter == _Filter.clients && p.isTemplate) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.clientName ?? '').toLowerCase().contains(q) ||
          (p.trainerNote ?? '').toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(readOnly ? 'Moje jídelníčky' : 'Knihovna jídelníčků'),
      ),
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomMealPlanEditorScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nový jídelníček'),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          if (!readOnly)
            Card(
              elevation: 0,
              color: cs.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  coach
                      ? 'Každý uložený jídelníček je zároveň šablona. Tlačítkem '
                          '„Použít pro klienta“ ho přepočítáš na kalorie jiného '
                          'klienta – porce se zaokrouhlí a makra spočítají v '
                          'celých gramech.'
                      : 'Uložené jídelníčky můžeš kdykoli otevřít, upravit '
                          'nebo přepočítat na svůj aktuální cíl.',
                  style: TextStyle(color: cs.onSecondaryContainer),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Hledat podle názvu, klienta nebo poznámky',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          if (coach && !readOnly) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final f in _Filter.values)
                  ChoiceChip(
                    label: Text(switch (f) {
                      _Filter.all => 'Vše (${plans.length})',
                      _Filter.templates =>
                        'Šablony (${plans.where((p) => p.isTemplate).length})',
                      _Filter.clients =>
                        'Klientské (${plans.where((p) => !p.isTemplate).length})',
                    }),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                readOnly
                    ? 'Trenér ti zatím žádný jídelníček neposlal.'
                    : 'Zatím tu nic není. Vytvoř vlastní jídelníček '
                        'tlačítkem „Nový jídelníček“, nebo otevři svůj '
                        'jídelníček a ulož ho ikonou diskety.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Nic neodpovídá hledání.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          for (final p in shown)
            _PlanCard(plan: p, readOnly: readOnly, coach: coach),
          if (!readOnly && dailyTemplates.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Denní šablony (starší)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final t in dailyTemplates) _DailyTemplateTile(item: t),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final SavedMealPlan plan;
  final bool readOnly;
  final bool coach;

  const _PlanCard({
    required this.plan,
    required this.readOnly,
    required this.coach,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final p = plan;

    Widget chip(String text, {Color? bg, Color? fg, IconData? icon}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg ?? cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(text, style: TextStyle(fontSize: 12, color: fg)),
            ],
          ),
        );

    Future<void> edit() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomMealPlanEditorScreen(existing: p),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => MealPlanActions.open(context, ref, p),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      switch (v) {
                        case 'pdf':
                          await MealPlanActions.printPlan(context, p);
                        case 'share':
                          await MealPlanActions.printPlan(context, p,
                              share: true);
                        case 'edit':
                          await edit();
                        case 'rename':
                          await MealPlanActions.rename(context, ref, p);
                        case 'template':
                          await ref
                              .read(savedMealPlansProvider.notifier)
                              .duplicateAsTemplate(p);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Uloženo jako obecná šablona.'),
                              ),
                            );
                          }
                        case 'delete':
                          await MealPlanActions.confirmDelete(context, ref, p);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Text('Tisk / PDF'),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('Sdílet PDF'),
                      ),
                      if (!readOnly) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Upravit'),
                        ),
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Přejmenovat'),
                        ),
                        if (!p.isTemplate)
                          const PopupMenuItem(
                            value: 'template',
                            child: Text('Uložit jako obecnou šablonu'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Smazat'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (!readOnly)
                    p.isTemplate
                        ? chip('Šablona',
                            icon: Icons.bookmark_outline,
                            bg: cs.tertiaryContainer,
                            fg: cs.onTertiaryContainer)
                        : chip(p.clientName ?? 'Klient',
                            icon: Icons.person_outline,
                            bg: cs.primaryContainer,
                            fg: cs.onPrimaryContainer),
                  chip(MealPlanActions.summary(p)),
                  chip('Upraveno ${MealPlanActions.date(p.updatedAt)}'),
                ],
              ),
              if ((p.trainerNote ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  p.trainerNote!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => MealPlanActions.open(context, ref, p),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Otevřít'),
                  ),
                  if (!readOnly)
                    FilledButton.icon(
                      onPressed: () =>
                          MealPlanActions.useForClient(context, ref, p),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(
                        coach ? 'Použít pro klienta' : 'Přepočítat na můj cíl',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyTemplateTile extends ConsumerWidget {
  final DailyMealTemplate item;
  const _DailyTemplateTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        title: Text(item.title.isEmpty ? l10n.untitled : item.title),
        subtitle: Text('${l10n.meals}: ${item.entries.length}'
            '${(item.clientName ?? '').isEmpty ? '' : ' · ${item.clientName}'}'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailyMealPlanEditorScreen(initialTemplate: item),
          ),
        ),
        trailing: IconButton(
          tooltip: l10n.delete,
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.deleteDailyTemplateQuestion),
                content: Text(l10n.confirmDeleteTemplate(
                  item.title.isEmpty ? l10n.untitled : item.title,
                )),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.no),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.yes),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await ref
                  .read(customMealPlanTemplatesProvider.notifier)
                  .remove(item.id);
            }
          },
        ),
      ),
    );
  }
}
