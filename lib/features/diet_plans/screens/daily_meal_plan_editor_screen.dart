import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/food_combo.dart';
import '../../../models/goal.dart';
import '../../../providers/food_combo_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../models/custom_meal_plan_models.dart';
import '../providers/custom_meal_plan_templates_provider.dart';

class DailyMealPlanEditorScreen extends ConsumerStatefulWidget {
  final DailyMealTemplate? initialTemplate;

  const DailyMealPlanEditorScreen({
    super.key,
    this.initialTemplate,
  });

  @override
  ConsumerState<DailyMealPlanEditorScreen> createState() =>
      _DailyMealPlanEditorScreenState();
}

class _DailyMealPlanEditorScreenState
    extends ConsumerState<DailyMealPlanEditorScreen> {
  late DailyMealTemplate _template;
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  late String _phaseLabel;

  @override
  void initState() {
    super.initState();

    final profile = ref.read(userProfileProvider);

    _template = widget.initialTemplate ??
        DailyMealTemplate.empty(
          clientId: profile?.clientId,
          clientName: profile?.displayName,
          phaseLabel: _resolvePhaseLabel(profile?.goal?.phase),
        );

    _titleCtrl = TextEditingController(text: _template.title);
    _noteCtrl = TextEditingController(text: _template.note);
    _phaseLabel = _template.phaseLabel;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _resolvePhaseLabel(GoalPhase? phase) {
    switch (phase) {
      case GoalPhase.build:
        return 'Nabírací fáze';
      case GoalPhase.cut:
        return 'Shazovací fáze';
      case GoalPhase.maintain:
        return 'Udržovací fáze';
      case GoalPhase.strength:
        return 'Silová fáze';
      case null:
        return 'Bez fáze';
    }
  }

  String _slotLabel(CustomMealSlot slot) {
    switch (slot) {
      case CustomMealSlot.breakfast:
        return 'Snídaně';
      case CustomMealSlot.snack1:
        return 'Svačina';
      case CustomMealSlot.lunch:
        return 'Oběd';
      case CustomMealSlot.snack2:
        return 'Svačina 2';
      case CustomMealSlot.dinner:
        return 'Večeře';
    }
  }

  ComboMealTime _comboTimeForSlot(CustomMealSlot slot) {
    switch (slot) {
      case CustomMealSlot.breakfast:
        return ComboMealTime.breakfast;
      case CustomMealSlot.snack1:
      case CustomMealSlot.snack2:
        return ComboMealTime.snack;
      case CustomMealSlot.lunch:
        return ComboMealTime.lunch;
      case CustomMealSlot.dinner:
        return ComboMealTime.dinner;
    }
  }

  List<FoodCombo> _combosForSlot(CustomMealSlot slot, List<FoodCombo> all) {
    final time = _comboTimeForSlot(slot);
    return all.where((c) => c.time == time).toList();
  }

  void _updateEntry(CustomMealEntry updated) {
    setState(() {
      _template = _template.copyWith(
        entries: _template.entries
            .map((e) => e.slot == updated.slot ? updated : e)
            .toList(),
      );
    });
  }

  Future<void> _saveTemplate() async {
    final title = _titleCtrl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyplň název jídelníčku.')),
      );
      return;
    }

    final saved = _template.copyWith(
      title: title,
      note: _noteCtrl.text.trim(),
      phaseLabel: _phaseLabel,
      updatedAt: DateTime.now(),
    );

    await ref.read(customMealPlanTemplatesProvider.notifier).upsert(saved);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Denní jídelníček byl uložen.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final combos = ref.watch(foodComboProvider);
    final profile = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor denního jídelníčku'),
        actions: [
          IconButton(
            onPressed: _saveTemplate,
            icon: const Icon(Icons.save),
            tooltip: 'Uložit',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Klient',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile?.displayName ?? 'Bez aktivního klienta',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Název jídelníčku',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _phaseLabel,
                    decoration: const InputDecoration(
                      labelText: 'Fáze',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'Bez fáze',
                        child: Text('Bez fáze'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Shazovací fáze',
                        child: Text('Shazovací fáze'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Nabírací fáze',
                        child: Text('Nabírací fáze'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Udržovací fáze',
                        child: Text('Udržovací fáze'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Silová fáze',
                        child: Text('Silová fáze'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _phaseLabel = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Poznámka trenéra',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final entry in _template.entries) ...[
            _MealSlotCard(
              label: _slotLabel(entry.slot),
              entry: entry,
              combos: _combosForSlot(entry.slot, combos),
              onChanged: _updateEntry,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saveTemplate,
            icon: const Icon(Icons.save),
            label: const Text('ULOŽIT DENNÍ JÍDELNÍČEK'),
          ),
        ],
      ),
    );
  }
}

class _MealSlotCard extends StatelessWidget {
  final String label;
  final CustomMealEntry entry;
  final List<FoodCombo> combos;
  final ValueChanged<CustomMealEntry> onChanged;

  const _MealSlotCard({
    required this.label,
    required this.entry,
    required this.combos,
    required this.onChanged,
  });

  Future<void> _pickCombo(BuildContext context) async {
    final selected = await showDialog<FoodCombo?>(
      context: context,
      builder: (_) => _ComboPickerDialog(
        title: label,
        combos: combos,
        initialSelectedTitle: entry.comboTitle,
      ),
    );

    if (selected == null) return;

    onChanged(
      entry.copyWith(
        comboTitle: selected.title,
        clearComboTitle: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final selectedCombo = entry.comboTitle == null
        ? null
        : combos.cast<FoodCombo?>().firstWhere(
              (e) => e?.title == entry.comboTitle,
              orElse: () => null,
            );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickCombo(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Vyber hotové jídlo',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                child: Text(
                  selectedCombo?.title ?? 'Klikni pro výběr a hledání hotovky',
                  style: TextStyle(
                    color: selectedCombo != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (selectedCombo != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    onChanged(
                      entry.copyWith(
                        comboTitle: null,
                        clearComboTitle: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Vymazat výběr'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              initialValue: entry.portionMultiplier.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Násobek porce',
                helperText:
                    '1.00 = základ, 1.25 = větší porce, 0.80 = menší porce',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return;

                onChanged(
                  entry.copyWith(portionMultiplier: parsed),
                );
              },
            ),
            if (selectedCombo != null) ...[
              const SizedBox(height: 12),
              Text(
                'Výběr: ${selectedCombo.title}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Základní porce: ${selectedCombo.defaultGrams} g',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                'Po úpravě: ${(selectedCombo.defaultGrams * entry.portionMultiplier).round()} g',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComboPickerDialog extends StatefulWidget {
  final String title;
  final List<FoodCombo> combos;
  final String? initialSelectedTitle;

  const _ComboPickerDialog({
    required this.title,
    required this.combos,
    required this.initialSelectedTitle,
  });

  @override
  State<_ComboPickerDialog> createState() => _ComboPickerDialogState();
}

class _ComboPickerDialogState extends State<_ComboPickerDialog> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FoodCombo> get _filteredCombos {
    final query = _searchCtrl.text.trim().toLowerCase();
    final source = [...widget.combos]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    if (query.isEmpty) {
      return source.take(30).toList();
    }

    return source
        .where((combo) => combo.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCombos;

    return AlertDialog(
      title: Text('Vyber hotovku – ${widget.title}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Hledat hotovku',
                hintText: 'Začni psát, např. v, vej, skyr...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('Nic nenalezeno.'),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final combo = filtered[index];
                        final isSelected =
                            combo.title == widget.initialSelectedTitle;

                        return ListTile(
                          title: Text(combo.title),
                          subtitle: Text(
                            '${combo.defaultGrams} g',
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_outline)
                              : const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pop(combo),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zrušit'),
        ),
      ],
    );
  }
}