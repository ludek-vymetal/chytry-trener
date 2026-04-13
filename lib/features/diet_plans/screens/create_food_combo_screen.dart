import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/food_combo.dart';
import '../../../models/meal.dart';
import '../../../providers/food_bank_provider.dart';
import '../../../providers/food_combo_provider.dart';

class CreateFoodComboScreen extends ConsumerStatefulWidget {
  const CreateFoodComboScreen({super.key});

  @override
  ConsumerState<CreateFoodComboScreen> createState() =>
      _CreateFoodComboScreenState();
}

class _CreateFoodComboScreenState extends ConsumerState<CreateFoodComboScreen> {
  final _titleCtrl = TextEditingController();

  ComboMealTime _mealTime = ComboMealTime.lunch;
  ComboTaste _taste = ComboTaste.any;

  final List<_DraftComboItem> _items = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final item in _items) {
      item.gramsCtrl.dispose();
    }
    super.dispose();
  }

  void _addMeal(Meal meal) {
    final existingIndex = _items.indexWhere(
      (e) => e.meal.name.trim().toLowerCase() == meal.name.trim().toLowerCase(),
    );

    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${meal.name} už ve skladbě je.')),
      );
      return;
    }

    setState(() {
      _items.add(
        _DraftComboItem(
          meal: meal,
          gramsCtrl: TextEditingController(
            text: meal.defaultGrams.toString(),
          ),
        ),
      );
    });
  }

  void _removeItem(_DraftComboItem item) {
    setState(() {
      _items.remove(item);
      item.gramsCtrl.dispose();
    });
  }

  int _gramsOf(_DraftComboItem item) {
    return int.tryParse(item.gramsCtrl.text.trim()) ?? 0;
  }

  int get _totalGrams {
    return _items.fold<int>(0, (sum, item) => sum + _gramsOf(item));
  }

  double get _totalCalories {
    double sum = 0;
    for (final item in _items) {
      final grams = _gramsOf(item);
      sum += (item.meal.caloriesPer100g * grams) / 100.0;
    }
    return sum;
  }

  double get _totalProtein {
    double sum = 0;
    for (final item in _items) {
      final grams = _gramsOf(item);
      sum += (item.meal.proteinPer100g * grams) / 100.0;
    }
    return sum;
  }

  double get _totalCarbs {
    double sum = 0;
    for (final item in _items) {
      final grams = _gramsOf(item);
      sum += (item.meal.carbsPer100g * grams) / 100.0;
    }
    return sum;
  }

  double get _totalFats {
    double sum = 0;
    for (final item in _items) {
      final grams = _gramsOf(item);
      sum += (item.meal.fatsPer100g * grams) / 100.0;
    }
    return sum;
  }

  double get _caloriesPer100g {
    if (_totalGrams <= 0) return 0;
    return (_totalCalories / _totalGrams) * 100.0;
  }

  double get _proteinPer100g {
    if (_totalGrams <= 0) return 0;
    return (_totalProtein / _totalGrams) * 100.0;
  }

  double get _carbsPer100g {
    if (_totalGrams <= 0) return 0;
    return (_totalCarbs / _totalGrams) * 100.0;
  }

  double get _fatsPer100g {
    if (_totalGrams <= 0) return 0;
    return (_totalFats / _totalGrams) * 100.0;
  }

  Future<void> _saveCombo() async {
    final title = _titleCtrl.text.trim();

    if (title.isEmpty) {
      _toast('Vyplň název hotovky.');
      return;
    }

    if (_items.isEmpty) {
      _toast('Přidej alespoň jednu potravinu.');
      return;
    }

    for (final item in _items) {
      final grams = _gramsOf(item);
      if (grams <= 0) {
        _toast('Každá položka musí mít gramáž větší než 0.');
        return;
      }
    }

    final combo = FoodCombo(
      title: title,
      time: _mealTime,
      taste: _taste,
      items: _items
          .map(
            (e) => FoodComboItem(
              mealName: e.meal.name,
              grams: _gramsOf(e),
            ),
          )
          .toList(),
    );

    await ref.read(foodComboProvider.notifier).upsertCustom(combo);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hotovka "$title" byla uložena.')),
    );

    Navigator.pop(context);
  }

  Future<void> _openCreateFoodDialog() async {
    final createdMeal = await showDialog<Meal>(
      context: context,
      builder: (dialogContext) => const _CreateMealDialog(),
    );

    if (createdMeal == null) return;

    final existing = ref.read(foodBankProvider.notifier).findByName(
          createdMeal.name,
        );

    if (existing != null) {
      _toast('Potravina "${createdMeal.name}" už v databance existuje.');
      _addMeal(existing);
      return;
    }

    await ref.read(foodBankProvider.notifier).upsert(createdMeal);

    if (!mounted) return;

    _addMeal(createdMeal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Potravina "${createdMeal.name}" byla uložena do databanky.'),
      ),
    );
  }

  Future<void> _openMealPicker(List<Meal> bank) async {
    final selected = await showDialog<Meal?>(
      context: context,
      builder: (_) => _MealPickerDialog(meals: bank),
    );

    if (selected == null) return;
    if (!mounted) return;

    _addMeal(selected);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(foodBankProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vytvořit hotovku'),
        actions: [
          IconButton(
            onPressed: _saveCombo,
            icon: const Icon(Icons.save),
            tooltip: 'Uložit hotovku',
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => _openMealPicker(bank),
                    borderRadius: BorderRadius.circular(12),
                    child: const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Přidat potravinu z databanky',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: Icon(Icons.chevron_right),
                      ),
                      child: Text('Klikni pro hledání a výběr potraviny'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _openCreateFoodDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Vytvořit novou potravinu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
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
                  const Text(
                    'Složení hotovky',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    const Text('Zatím jsi nepřidal žádnou potravinu.')
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
                              child: TextField(
                                controller: item.gramsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'g',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
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
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _macroChip('Celkem', '${_totalCalories.round()} kcal'),
                  _macroChip('B', '${_totalProtein.toStringAsFixed(1)} g'),
                  _macroChip('S', '${_totalCarbs.toStringAsFixed(1)} g'),
                  _macroChip('T', '${_totalFats.toStringAsFixed(1)} g'),
                  _macroChip('Gramáž', '$_totalGrams g'),
                  _macroChip(
                    'Na 100 g',
                    '${_caloriesPer100g.round()} kcal | B ${_proteinPer100g.toStringAsFixed(1)} | S ${_carbsPer100g.toStringAsFixed(1)} | T ${_fatsPer100g.toStringAsFixed(1)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saveCombo,
            icon: const Icon(Icons.save),
            label: const Text('ULOŽIT HOTOVKU'),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: $value'),
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

class _DraftComboItem {
  final Meal meal;
  final TextEditingController gramsCtrl;

  _DraftComboItem({
    required this.meal,
    required this.gramsCtrl,
  });
}

class _MealPickerDialog extends StatefulWidget {
  final List<Meal> meals;

  const _MealPickerDialog({
    required this.meals,
  });

  @override
  State<_MealPickerDialog> createState() => _MealPickerDialogState();
}

class _MealPickerDialogState extends State<_MealPickerDialog> {
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
        height: 460,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Hledat potravinu',
                hintText: 'Začni psát, např. v, vej, kuře...',
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

class _CreateMealDialog extends StatefulWidget {
  const _CreateMealDialog();

  @override
  State<_CreateMealDialog> createState() => _CreateMealDialogState();
}

class _CreateMealDialogState extends State<_CreateMealDialog> {
  final _nameCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatsCtrl = TextEditingController();
  final _defaultGramsCtrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatsCtrl.dispose();
    _defaultGramsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final calories = int.tryParse(_caloriesCtrl.text.trim());
    final protein = double.tryParse(_proteinCtrl.text.trim().replaceAll(',', '.'));
    final carbs = double.tryParse(_carbsCtrl.text.trim().replaceAll(',', '.'));
    final fats = double.tryParse(_fatsCtrl.text.trim().replaceAll(',', '.'));
    final defaultGrams = int.tryParse(_defaultGramsCtrl.text.trim());

    if (name.isEmpty) {
      _showError('Vyplň název potraviny.');
      return;
    }

    if (calories == null || calories < 0) {
      _showError('Vyplň platné kcal / 100 g.');
      return;
    }

    if (protein == null || protein < 0) {
      _showError('Vyplň platné bílkoviny / 100 g.');
      return;
    }

    if (carbs == null || carbs < 0) {
      _showError('Vyplň platné sacharidy / 100 g.');
      return;
    }

    if (fats == null || fats < 0) {
      _showError('Vyplň platné tuky / 100 g.');
      return;
    }

    if (defaultGrams == null || defaultGrams <= 0) {
      _showError('Vyplň platnou default gramáž.');
      return;
    }

    Navigator.of(context).pop(
      Meal(
        name: name,
        caloriesPer100g: calories,
        proteinPer100g: protein,
        carbsPer100g: carbs,
        fatsPer100g: fats,
        defaultGrams: defaultGrams,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vytvořit novou potravinu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Název potraviny',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caloriesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'kcal / 100 g',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _proteinCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Bílkoviny / 100 g',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _carbsCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Sacharidy / 100 g',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatsCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Tuky / 100 g',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _defaultGramsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Default gramáž',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
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
}