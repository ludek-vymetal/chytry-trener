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
  // Textová pole vlastní samotný list (_ExclusionsSheet) – uvolní je až
  // po zavření, jinak Flutter při animaci zavírání spadne.
  final result = await showModalBottomSheet<(String, String, String)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ExclusionsSheet(details: details),
  );
  if (result == null) return;

  await ref.read(coachClientDetailsControllerProvider.notifier).upsert(
        details.copyWith(
          allergies: result.$1,
          intolerances: result.$2,
          dislikedFoods: result.$3,
        ),
      );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Uloženo. Nové jídelníčky už tyto potraviny vynechají.',
        ),
      ),
    );
  }
}

class _ExclusionsSheet extends StatefulWidget {
  final CoachClientDetails details;
  const _ExclusionsSheet({required this.details});

  @override
  State<_ExclusionsSheet> createState() => _ExclusionsSheetState();
}

class _ExclusionsSheetState extends State<_ExclusionsSheet> {
  late final TextEditingController _allergies;
  late final TextEditingController _intol;
  late final TextEditingController _disliked;

  @override
  void initState() {
    super.initState();
    _allergies = TextEditingController(text: widget.details.allergies);
    _intol = TextEditingController(text: widget.details.intolerances);
    _disliked = TextEditingController(text: widget.details.dislikedFoods);
  }

  @override
  void dispose() {
    _allergies.dispose();
    _intol.dispose();
    _disliked.dispose();
    super.dispose();
  }

  void _toggle(String a) {
    final list = FoodCatalog.parseExclusions(_allergies.text);
    if (list.contains(a)) {
      list.remove(a);
    } else {
      list.add(a);
    }
    setState(() => _allergies.text = list.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final current = FoodCatalog.parseExclusions(
      '${_allergies.text}, ${_intol.text}',
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
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
                    onSelected: (_) => _toggle(a),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _allergies,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Alergie',
                hintText: 'např. ořechy, ryby',
                prefixIcon: Icon(Icons.warning_amber_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _intol,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nesnášenlivost',
                hintText: 'např. laktóza, lepek',
                prefixIcon: Icon(Icons.sick_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _disliked,
              decoration: const InputDecoration(
                labelText: 'Nechce jíst / nechutná mu',
                hintText: 'např. tuňák, cottage, batáty',
                prefixIcon: Icon(Icons.thumb_down_alt_outlined),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context, (
                  _allergies.text.trim(),
                  _intol.text.trim(),
                  _disliked.text.trim(),
                ));
              },
              icon: const Icon(Icons.check),
              label: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }
}
