import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/food_combo_seed.dart';
import '../../../models/food_combo.dart';
import '../../../models/meal.dart';
import '../../../providers/food_bank_provider.dart';
import '../../../providers/food_combo_provider.dart';
import 'create_food_combo_screen.dart';

class FoodComboLibraryScreen extends ConsumerStatefulWidget {
  const FoodComboLibraryScreen({super.key});

  @override
  ConsumerState<FoodComboLibraryScreen> createState() =>
      _FoodComboLibraryScreenState();
}

class _FoodComboLibraryScreenState
    extends ConsumerState<FoodComboLibraryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isSeedCombo(FoodCombo combo) {
    final normalized = combo.title.trim().toLowerCase();
    return FoodComboSeed.items.any(
      (seed) => seed.title.trim().toLowerCase() == normalized,
    );
  }

  Meal? _findMeal(List<Meal> bank, String mealName) {
    final normalized = mealName.trim().toLowerCase();

    try {
      return bank.firstWhere(
        (m) => m.name.trim().toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  double _totalCaloriesForBank(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.caloriesPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  double _totalProteinForBank(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.proteinPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  double _totalCarbsForBank(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.carbsPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  double _totalFatsForBank(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.fatsPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  List<String> _missingItemsForBank(FoodCombo combo, List<Meal> bank) {
    return combo.items
        .where((item) => _findMeal(bank, item.mealName) == null)
        .map((item) => item.mealName)
        .toList(growable: false);
  }

  String _buildDuplicateTitle(String baseTitle, List<FoodCombo> allCombos) {
    final existingTitles = allCombos
        .map((e) => e.title.trim().toLowerCase())
        .toSet();

    final baseCopy = '$baseTitle (kopie)';
    if (!existingTitles.contains(baseCopy.trim().toLowerCase())) {
      return baseCopy;
    }

    var index = 2;
    while (true) {
      final candidate = '$baseTitle (kopie $index)';
      if (!existingTitles.contains(candidate.trim().toLowerCase())) {
        return candidate;
      }
      index++;
    }
  }

  Future<void> _duplicateCombo(FoodCombo combo) async {
    final allCombos = ref.read(foodComboProvider);

    final duplicated = FoodCombo(
      title: _buildDuplicateTitle(combo.title, allCombos),
      time: combo.time,
      taste: combo.taste,
      items: combo.items
          .map(
            (item) => FoodComboItem(
              mealName: item.mealName,
              grams: item.grams,
            ),
          )
          .toList(),
    );

    await ref.read(foodComboProvider.notifier).upsertCustom(duplicated);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hotovka "${duplicated.title}" byla vytvořena jako kopie.'),
      ),
    );
  }

  Future<void> _deleteCombo(FoodCombo combo) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Smazat hotovku?'),
            content: Text(
              'Opravdu chceš smazat hotovku "${combo.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Zrušit'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Smazat'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await ref.read(foodComboProvider.notifier).removeCustomByTitle(combo.title);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hotovka "${combo.title}" byla smazána.')),
    );
  }

  Future<void> _editCombo(FoodCombo combo) async {
    final bank = ref.read(foodBankProvider);

    final resolvedItems = combo.items
        .map((item) {
          final meal = _findMeal(bank, item.mealName);
          if (meal == null) return null;

          return _EditableFoodComboItem(
            meal: meal,
            grams: item.grams,
          );
        })
        .whereType<_EditableFoodComboItem>()
        .toList();

    if (resolvedItems.length != combo.items.length) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Některé potraviny této hotovky už nejsou v databance. Editace není možná.',
          ),
        ),
      );
      return;
    }

    final updated = await showDialog<FoodCombo>(
      context: context,
      builder: (_) => _EditFoodComboDialog(
        initialCombo: combo,
        availableMeals: bank,
        initialItems: resolvedItems,
      ),
    );

    if (updated == null) return;

    await ref.read(foodComboProvider.notifier).upsertCustom(updated);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hotovka "${updated.title}" byla upravena.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final combos = ref.watch(foodComboProvider);
    final bank = ref.watch(foodBankProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = combos.where((combo) {
      if (query.isEmpty) return true;
      return combo.title.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Databanka hotovek'),
        actions: [
          IconButton(
            tooltip: 'Vytvořit hotovku',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateFoodComboScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Hledat hotovku',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Žádné hotovky neodpovídají hledání.'),
              ),
            )
          else
            ...filtered.map((combo) {
              final isSeed = _isSeedCombo(combo);

              final kcal = _totalCaloriesForBank(combo, bank).round();
              final protein =
                  _totalProteinForBank(combo, bank).toStringAsFixed(1);
              final carbs = _totalCarbsForBank(combo, bank).toStringAsFixed(1);
              final fats = _totalFatsForBank(combo, bank).toStringAsFixed(1);
              final missing = _missingItemsForBank(combo, bank);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            combo.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSeed
                                  ? colorScheme.surfaceContainerHighest
                                  : colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isSeed ? 'SEED' : 'CUSTOM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSeed
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_timeLabel(combo.time)} • ${_tasteLabel(combo.taste)} • ${combo.defaultGrams} g',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$kcal kcal • B $protein g • S $carbs g • T $fats g',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        combo.items
                            .map((e) => '${e.mealName} (${e.grams} g)')
                            .join(', '),
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      if (missing.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Chybí v databance: ${missing.join(', ')}',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _duplicateCombo(combo),
                            icon: const Icon(Icons.copy_outlined),
                            label: Text(isSeed ? 'Duplikovat' : 'Vytvořit kopii'),
                          ),
                          if (!isSeed)
                            OutlinedButton.icon(
                              onPressed: missing.isNotEmpty
                                  ? null
                                  : () => _editCombo(combo),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Upravit'),
                            ),
                          if (!isSeed)
                            OutlinedButton.icon(
                              onPressed: () => _deleteCombo(combo),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Smazat'),
                            ),
                        ],
                      ),
                      if (isSeed) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Seed hotovku nejdřív duplikuj. Kopii pak můžeš upravit nebo smazat.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _timeLabel(ComboMealTime time) {
    switch (time) {
      case ComboMealTime.breakfast:
        return 'Snídaně';
      case ComboMealTime.snack:
        return 'Svačina';
      case ComboMealTime.lunch:
        return 'Oběd';
      case ComboMealTime.dinner:
        return 'Večeře';
      case ComboMealTime.vegan:
        return 'Veganské';
    }
  }

  String _tasteLabel(ComboTaste taste) {
    switch (taste) {
      case ComboTaste.savory:
        return 'Slané';
      case ComboTaste.sweet:
        return 'Sladké';
      case ComboTaste.any:
        return 'Cokoliv';
    }
  }
}

class _EditableFoodComboItem {
  final Meal meal;
  final int grams;

  const _EditableFoodComboItem({
    required this.meal,
    required this.grams,
  });

  _EditableFoodComboItem copyWith({
    Meal? meal,
    int? grams,
  }) {
    return _EditableFoodComboItem(
      meal: meal ?? this.meal,
      grams: grams ?? this.grams,
    );
  }
}

class _EditFoodComboDialog extends StatefulWidget {
  final FoodCombo initialCombo;
  final List<Meal> availableMeals;
  final List<_EditableFoodComboItem> initialItems;

  const _EditFoodComboDialog({
    required this.initialCombo,
    required this.availableMeals,
    required this.initialItems,
  });

  @override
  State<_EditFoodComboDialog> createState() => _EditFoodComboDialogState();
}

class _EditFoodComboDialogState extends State<_EditFoodComboDialog> {
  late final TextEditingController _titleCtrl;
  late ComboMealTime _mealTime;
  late ComboTaste _taste;
  late List<_EditableFoodComboItem> _items;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialCombo.title);
    _mealTime = widget.initialCombo.time;
    _taste = widget.initialCombo.taste;
    _items = List<_EditableFoodComboItem>.from(widget.initialItems);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMeal() async {
    final selected = await showDialog<Meal>(
      context: context,
      builder: (_) => _EditMealPickerDialog(meals: widget.availableMeals),
    );

    if (selected == null) return;

    final exists = _items.any(
      (e) =>
          e.meal.name.trim().toLowerCase() ==
          selected.name.trim().toLowerCase(),
    );

    if (exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.name} už ve skladbě je.')),
      );
      return;
    }

    setState(() {
      _items = [
        ..._items,
        _EditableFoodComboItem(
          meal: selected,
          grams: selected.defaultGrams,
        ),
      ];
    });
  }

  void _removeItem(_EditableFoodComboItem item) {
    setState(() {
      _items = _items.where((e) => e != item).toList();
    });
  }

  void _updateGrams(_EditableFoodComboItem item, String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return;

    setState(() {
      _items = _items
          .map((e) => e == item ? e.copyWith(grams: parsed) : e)
          .toList();
    });
  }

  void _submit() {
    final title = _titleCtrl.text.trim();

    if (title.isEmpty) {
      _toast('Vyplň název hotovky.');
      return;
    }

    if (_items.isEmpty) {
      _toast('Přidej alespoň jednu potravinu.');
      return;
    }

    if (_items.any((e) => e.grams <= 0)) {
      _toast('Každá položka musí mít gramáž větší než 0.');
      return;
    }

    Navigator.of(context).pop(
      FoodCombo(
        title: title,
        time: _mealTime,
        taste: _taste,
        items: _items
            .map(
              (e) => FoodComboItem(
                mealName: e.meal.name,
                grams: e.grams,
              ),
            )
            .toList(),
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upravit hotovku'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Název hotovky',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ComboMealTime>(
                initialValue: _mealTime,
                decoration: const InputDecoration(
                  labelText: 'Typ jídla',
                  border: OutlineInputBorder(),
                ),
                items: ComboMealTime.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(_timeLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _mealTime = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ComboTaste>(
                initialValue: _taste,
                decoration: const InputDecoration(
                  labelText: 'Chuťový typ',
                  border: OutlineInputBorder(),
                ),
                items: ComboTaste.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(_tasteLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _taste = value);
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickMeal,
                  icon: const Icon(Icons.add),
                  label: const Text('Přidat potravinu'),
                ),
              ),
              const SizedBox(height: 12),
              if (_items.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Zatím bez položek.'),
                )
              else
                ..._items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(item.meal.name),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: item.grams.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'g',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => _updateGrams(item, value),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeItem(item),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zrušit'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Uložit'),
        ),
      ],
    );
  }

  String _timeLabel(ComboMealTime time) {
    switch (time) {
      case ComboMealTime.breakfast:
        return 'Snídaně';
      case ComboMealTime.snack:
        return 'Svačina';
      case ComboMealTime.lunch:
        return 'Oběd';
      case ComboMealTime.dinner:
        return 'Večeře';
      case ComboMealTime.vegan:
        return 'Veganské';
    }
  }

  String _tasteLabel(ComboTaste taste) {
    switch (taste) {
      case ComboTaste.savory:
        return 'Slané';
      case ComboTaste.sweet:
        return 'Sladké';
      case ComboTaste.any:
        return 'Cokoliv';
    }
  }
}

class _EditMealPickerDialog extends StatefulWidget {
  final List<Meal> meals;

  const _EditMealPickerDialog({
    required this.meals,
  });

  @override
  State<_EditMealPickerDialog> createState() => _EditMealPickerDialogState();
}

class _EditMealPickerDialogState extends State<_EditMealPickerDialog> {
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

  List<Meal> get _filteredMeals {
    final query = _searchCtrl.text.trim().toLowerCase();
    final source = [...widget.meals]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (query.isEmpty) {
      return source.take(40).toList();
    }

    return source
        .where((meal) => meal.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMeals;

    return AlertDialog(
      title: const Text('Vyber potravinu'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Hledat potravinu',
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
                        final meal = filtered[index];

                        return ListTile(
                          title: Text(meal.name),
                          subtitle: Text(
                            '100 g: ${meal.caloriesPer100g} kcal • B ${meal.proteinPer100g} / S ${meal.carbsPer100g} / T ${meal.fatsPer100g}',
                          ),
                          trailing: Text('${meal.defaultGrams} g'),
                          onTap: () => Navigator.of(context).pop(meal),
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