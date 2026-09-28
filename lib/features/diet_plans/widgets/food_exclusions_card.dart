import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/coach_client_details.dart';
import '../../../providers/coach/coach_client_details_controller.dart';
import '../../../providers/food_exclusions_provider.dart';
import '../logic/food_catalog.dart';

/// Karta „Alergie a co nejí“ – co se zapíše, jídelníčky vynechají.
///
/// Bez [clientId] platí pro právě aktivního klienta (nebo vlastní profil).
class FoodExclusionsCard extends ConsumerWidget {
  final String? clientId;
  const FoodExclusionsCard({super.key, this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final String activeId = ref.watch(exclusionsClientIdProvider);
    final String id = clientId ?? activeId;
    final detailsAsync = ref.watch(coachClientDetailsForClientProvider(id));
    final d = detailsAsync.valueOrNull;

    final allergies = FoodCatalog.parseExclusions(d?.allergies ?? '');
    final intolerances = FoodCatalog.parseExclusions(d?.intolerances ?? '');
    final disliked = FoodCatalog.parseExclusions(d?.dislikedFoods ?? '');
    final empty = allergies.isEmpty && intolerances.isEmpty && disliked.isEmpty;

    Widget chips(List<String> items, Color bg, Color fg) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in items)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  i,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        );

    Widget line(String label, List<String> items, Color bg, Color fg) =>
        items.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    chips(items, bg, fg),
                  ],
                ),
              );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.no_food_outlined, color: cs.error),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Alergie a co klient nejí',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: d == null
                      ? null
                      : () => showFoodExclusionsEditor(context, ref, d),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(empty ? 'Zadat' : 'Upravit'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              empty
                  ? 'Nic nezadáno. Co sem zapíšeš, všechny jídelníčky '
                      'automaticky vynechají.'
                  : 'Tyto potraviny všechny jídelníčky automaticky vynechávají.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            line('Alergie', allergies, cs.errorContainer, cs.onErrorContainer),
            line('Nesnášenlivost', intolerances, cs.tertiaryContainer,
                cs.onTertiaryContainer),
            line('Nechce jíst', disliked, cs.surfaceContainerHighest,
                cs.onSurface),
          ],
        ),
      ),
    );
  }
}

/// Nejčastější alergeny na jedno klepnutí.
const _quickAllergens = [
  'mléko',
  'laktóza',
  'lepek',
  'vejce',
  'ořechy',
  'arašídy',
  'ryby',
  'korýši',
  'sója',
  'luštěniny',
];

Future<void> showFoodExclusionsEditor(
  BuildContext context,
  WidgetRef ref,
  CoachClientDetails details,
) async {
  final allergiesCtrl = TextEditingController(text: details.allergies);
  final intolCtrl = TextEditingController(text: details.intolerances);
  final dislikedCtrl = TextEditingController(text: details.dislikedFoods);

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final current = FoodCatalog.parseExclusions(
          '${allergiesCtrl.text}, ${intolCtrl.text}',
        );
        void toggle(String a) {
          final list = FoodCatalog.parseExclusions(allergiesCtrl.text);
          if (list.contains(a)) {
            list.remove(a);
          } else {
            list.add(a);
          }
          allergiesCtrl.text = list.join(', ');
          setState(() {});
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Alergie a co klient nejí',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Jídelníčky tyto potraviny vynechají. Piš je oddělené čárkou.',
                ),
                const SizedBox(height: 14),
                const Text(
                  'Rychlý výběr alergenů',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in _quickAllergens)
                      FilterChip(
                        label: Text(a),
                        selected: current.contains(a),
                        onSelected: (_) => toggle(a),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: allergiesCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Alergie',
                    hintText: 'např. ořechy, ryby',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: intolCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Nesnášenlivost',
                    hintText: 'např. laktóza, lepek',
                    prefixIcon: Icon(Icons.sick_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dislikedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nechce jíst / nechutná mu',
                    hintText: 'např. tuňák, cottage, batáty',
                    prefixIcon: Icon(Icons.thumb_down_alt_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Uložit'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  if (saved == true) {
    await ref.read(coachClientDetailsControllerProvider.notifier).upsert(
          details.copyWith(
            allergies: allergiesCtrl.text.trim(),
            intolerances: intolCtrl.text.trim(),
            dislikedFoods: dislikedCtrl.text.trim(),
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uloženo. Jídelníček vytvoř znovu, ať se změna projeví.',
          ),
        ),
      );
    }
  }
  allergiesCtrl.dispose();
  intolCtrl.dispose();
  dislikedCtrl.dispose();
}
