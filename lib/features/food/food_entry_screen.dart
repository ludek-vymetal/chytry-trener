import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/daily_intake.dart';
import '../../models/food_combo.dart';
import '../../models/meal.dart';
import '../../providers/daily_intake_provider.dart';
import '../../providers/food_bank_provider.dart';
import '../../providers/food_combo_provider.dart';
import '../../services/food_combo_service.dart';

class FoodEntryScreen extends ConsumerStatefulWidget {
  const FoodEntryScreen({super.key});

  @override
  ConsumerState<FoodEntryScreen> createState() => _FoodEntryScreenState();
}

class _FoodEntryScreenState extends ConsumerState<FoodEntryScreen> {
  final _nameCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController();

  bool _knowsMacros = false;

  final _calPer100Ctrl = TextEditingController();
  final _protPer100Ctrl = TextEditingController();
  final _carbPer100Ctrl = TextEditingController();
  final _fatPer100Ctrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gramsCtrl.dispose();
    _calPer100Ctrl.dispose();
    _protPer100Ctrl.dispose();
    _carbPer100Ctrl.dispose();
    _fatPer100Ctrl.dispose();
    super.dispose();
  }

  int? _parseGramsOrNull() {
    final g = int.tryParse(_gramsCtrl.text.trim());
    if (g == null) return null;
    if (g < 10 || g > 3000) return null;
    return g;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  double _comboCalories(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.caloriesPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  double _comboProtein(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.proteinPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  double _comboCarbs(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.carbsPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  double _comboFats(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.fatsPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  List<String> _comboMissingItems(FoodCombo combo, List<Meal> bank) {
    return combo.items
        .where((item) => _findMeal(bank, item.mealName) == null)
        .map((item) => item.mealName)
        .toList();
  }

  void _addFoodLogItemToDay(FoodLogItem item) {
    ref.read(dailyIntakeProvider.notifier).addFood(item);
    Navigator.pop(context, true);
  }

  void _addPortionToDay(MealPortion portion) {
    final item = FoodLogItem(
      name: portion.name,
      grams: portion.grams,
      calories: portion.calories,
      protein: portion.protein.round(),
      carbs: portion.carbs.round(),
      fat: portion.fats.round(),
    );
    _addFoodLogItemToDay(item);
  }

  void _addComboToDay(FoodCombo combo, int grams) {
    final bank = ref.read(foodBankProvider);

    final defaultGrams =
        combo.defaultGrams <= 0 ? grams.toDouble() : combo.defaultGrams.toDouble();
    final factor = grams / defaultGrams;

    final calories = (_comboCalories(combo, bank) * factor).round();
    final protein = (_comboProtein(combo, bank) * factor).round();
    final carbs = (_comboCarbs(combo, bank) * factor).round();
    final fats = (_comboFats(combo, bank) * factor).round();

    final item = FoodLogItem(
      name: combo.title,
      grams: grams,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fats,
    );

    _addFoodLogItemToDay(item);
  }

  void _saveFromBankOrEstimate() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Zadej název jídla');
      return;
    }

    final bank = ref.read(foodBankProvider.notifier);

    final existing = bank.findByName(name);
    if (existing != null) {
      final grams = _parseGramsOrNull() ?? existing.defaultGrams;
      _addPortionToDay(existing.portion(grams));
      return;
    }

    final suggestions = bank.search(name);
    if (suggestions.isNotEmpty) {
      final best = suggestions.first;
      final grams = _parseGramsOrNull() ?? best.defaultGrams;

      final estimatedMeal = Meal(
        name: name,
        caloriesPer100g: best.caloriesPer100g,
        proteinPer100g: best.proteinPer100g,
        carbsPer100g: best.carbsPer100g,
        fatsPer100g: best.fatsPer100g,
        defaultGrams: grams,
      );

      bank.upsert(estimatedMeal);
      _addPortionToDay(estimatedMeal.portion(grams));
      return;
    }

    final grams = _parseGramsOrNull() ?? 350;

    const avg = Meal(
      name: 'Průměrné jídlo',
      caloriesPer100g: 170,
      proteinPer100g: 10,
      carbsPer100g: 18,
      fatsPer100g: 6,
      defaultGrams: 350,
    );

    final estimatedMeal = Meal(
      name: name,
      caloriesPer100g: avg.caloriesPer100g,
      proteinPer100g: avg.proteinPer100g,
      carbsPer100g: avg.carbsPer100g,
      fatsPer100g: avg.fatsPer100g,
      defaultGrams: grams,
    );

    bank.upsert(estimatedMeal);
    _addPortionToDay(estimatedMeal.portion(grams));
  }

  void _saveManualAndToBank() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Zadej název jídla');
      return;
    }

    final grams = _parseGramsOrNull();
    if (grams == null) {
      _toast('Zadej gramáž (10–3000 g)');
      return;
    }

    final cal = int.tryParse(_calPer100Ctrl.text.trim());
    final p = double.tryParse(_protPer100Ctrl.text.trim().replaceAll(',', '.'));
    final c = double.tryParse(_carbPer100Ctrl.text.trim().replaceAll(',', '.'));
    final f = double.tryParse(_fatPer100Ctrl.text.trim().replaceAll(',', '.'));

    if (cal == null || p == null || c == null || f == null) {
      _toast('Doplň hodnoty na 100 g (kcal/B/S/T)');
      return;
    }

    final meal = Meal(
      name: name,
      caloriesPer100g: cal,
      proteinPer100g: p,
      carbsPer100g: c,
      fatsPer100g: f,
      defaultGrams: grams,
    );

    ref.read(foodBankProvider.notifier).upsert(meal);
    _addPortionToDay(meal.portion(grams));
  }

  Future<void> _openAddToBankDialog({String? prefillName}) async {
    final nameCtrl =
        TextEditingController(text: (prefillName ?? _nameCtrl.text).trim());
    final calCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    final cCtrl = TextEditingController();
    final fCtrl = TextEditingController();
    final defaultGCtrl = TextEditingController(
      text: (_parseGramsOrNull() ?? 250).toString(),
    );

    final result = await showDialog<Meal?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Přidat jídlo do banky'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Název'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: calCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Kalorie na 100 g'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Bílkoviny na 100 g'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Sacharidy na 100 g'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tuky na 100 g'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: defaultGCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Default gramáž (g)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final cal = int.tryParse(calCtrl.text.trim());
                final p = double.tryParse(pCtrl.text.trim().replaceAll(',', '.'));
                final c = double.tryParse(cCtrl.text.trim().replaceAll(',', '.'));
                final f = double.tryParse(fCtrl.text.trim().replaceAll(',', '.'));
                final dg = int.tryParse(defaultGCtrl.text.trim());

                if (name.isEmpty ||
                    cal == null ||
                    p == null ||
                    c == null ||
                    f == null ||
                    dg == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Vyplň prosím všechna pole')),
                  );
                  return;
                }

                if (dg < 10 || dg > 3000) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Default gramáž musí být 10–3000 g'),
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop(
                  Meal(
                    name: name,
                    caloriesPer100g: cal,
                    proteinPer100g: p,
                    carbsPer100g: c,
                    fatsPer100g: f,
                    defaultGrams: dg,
                  ),
                );
              },
              child: const Text('Uložit'),
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();
    calCtrl.dispose();
    pCtrl.dispose();
    cCtrl.dispose();
    fCtrl.dispose();
    defaultGCtrl.dispose();

    if (!mounted) return;
    if (result == null) return;

    ref.read(foodBankProvider.notifier).upsert(result);
    _toast('Uloženo do banky ✅');

    final grams = _parseGramsOrNull() ?? result.defaultGrams;

    final add = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Přidat i do dne?'),
        content: Text('Chceš teď přidat „${result.name}“ ($grams g) do dne?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ne'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ano'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (add == true) {
      _addPortionToDay(result.portion(grams));
    }
  }

  Future<void> _openComboPicker() async {
    final combos = ref.read(foodComboProvider);
    final bank = ref.read(foodBankProvider);

    ComboMealTime time = ComboMealTime.lunch;
    ComboTaste taste = ComboTaste.any;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final filtered = FoodComboService.filter(
              combos,
              time: time,
              taste: taste,
            );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.75,
                  child: Column(
                    children: [
                      const Text(
                        'Vyber hotovku',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ComboMealTime.values.map((t) {
                          final selected = time == t;
                          return ChoiceChip(
                            label: Text(FoodComboService.timeLabel(t)),
                            selected: selected,
                            onSelected: (_) => setLocal(() => time = t),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      if (time == ComboMealTime.breakfast ||
                          time == ComboMealTime.snack)
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Slané'),
                              selected: taste == ComboTaste.savory,
                              onSelected: (_) =>
                                  setLocal(() => taste = ComboTaste.savory),
                            ),
                            ChoiceChip(
                              label: const Text('Sladké'),
                              selected: taste == ComboTaste.sweet,
                              onSelected: (_) =>
                                  setLocal(() => taste = ComboTaste.sweet),
                            ),
                            ChoiceChip(
                              label: const Text('Cokoliv'),
                              selected: taste == ComboTaste.any,
                              onSelected: (_) =>
                                  setLocal(() => taste = ComboTaste.any),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('V této kategorii zatím nic není.'),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final c = filtered[i];
                                  final kcal = _comboCalories(c, bank).round();
                                  final protein =
                                      _comboProtein(c, bank).toStringAsFixed(1);
                                  final carbs =
                                      _comboCarbs(c, bank).toStringAsFixed(1);
                                  final fats =
                                      _comboFats(c, bank).toStringAsFixed(1);
                                  final missing = _comboMissingItems(c, bank);

                                  return ListTile(
                                    title: Text(c.title),
                                    subtitle: Text(
                                      missing.isNotEmpty
                                          ? 'Chybí potraviny v databance: ${missing.join(', ')}'
                                          : '${c.defaultGrams} g (default) • '
                                              '$kcal kcal • '
                                              'B $protein / S $carbs / T $fats',
                                    ),
                                    trailing: const Icon(Icons.add),
                                    onTap: missing.isNotEmpty
                                        ? null
                                        : () async {
                                            final grams = await _askGrams(
                                              context: ctx,
                                              initial: c.defaultGrams,
                                            );

                                            if (!ctx.mounted) return;
                                            if (grams == null) return;

                                            Navigator.of(ctx).pop();
                                            if (!mounted) return;

                                            _addComboToDay(c, grams);
                                          },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<int?> _askGrams({
    required BuildContext context,
    required int initial,
  }) async {
    final ctrl = TextEditingController(text: initial.toString());

    final res = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kolik gramů?'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Gramáž',
            hintText: 'např. 350',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () {
              final g = int.tryParse(ctrl.text.trim());
              if (g == null || g < 10 || g > 3000) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Zadej 10–3000 g')),
                );
                return;
              }
              Navigator.pop(ctx, g);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    ctrl.dispose();
    return res;
  }

  void _pickSuggestion(Meal m) {
    _nameCtrl.text = m.name;
    if (_gramsCtrl.text.trim().isEmpty) {
      _gramsCtrl.text = m.defaultGrams.toString();
    }
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bankList = ref.watch(foodBankProvider);
    final query = _nameCtrl.text.trim();

    final bank = ref.read(foodBankProvider.notifier);
    final picked = bank.findByName(query);
    final suggestions = query.isEmpty ? <Meal>[] : bank.search(query);

    final showSuggestions =
        query.isNotEmpty && picked == null && suggestions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Přidat jídlo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openComboPicker,
              icon: const Icon(Icons.restaurant),
              label: const Text(
                'Přidat hotovku (snídaně/svačina/oběd/večeře)',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Název jídla',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (showSuggestions) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final m = suggestions[i];
                  return ListTile(
                    dense: true,
                    title: Text(m.name),
                    subtitle: Text(
                      '${m.caloriesPer100g} kcal/100g • '
                      'B ${m.proteinPer100g} / S ${m.carbsPer100g} / T ${m.fatsPer100g}',
                    ),
                    onTap: () => _pickSuggestion(m),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _gramsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Gramáž',
              hintText: picked != null
                  ? 'Doporučeno: ${picked.defaultGrams} g'
                  : 'Např. 350',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Znám hodnoty (na 100 g)'),
            value: _knowsMacros,
            onChanged: (v) => setState(() => _knowsMacros = v),
          ),
          const SizedBox(height: 8),
          if (_knowsMacros) ...[
            _numField('Kalorie na 100 g', _calPer100Ctrl),
            _numField('Bílkoviny na 100 g', _protPer100Ctrl),
            _numField('Sacharidy na 100 g', _carbPer100Ctrl),
            _numField('Tuky na 100 g', _fatPer100Ctrl),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: query.isEmpty ? null : _saveManualAndToBank,
                child: const Text('Uložit (přesně) + přidat do dne'),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: query.isEmpty ? null : _saveFromBankOrEstimate,
                child: const Text('Přidat do dne (auto / odhad)'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openAddToBankDialog(prefillName: query),
            icon: const Icon(Icons.library_add),
            label: const Text('Přidat jídlo do banky'),
          ),
          const SizedBox(height: 20),
          Text(
            'Banka jídel: ${bankList.length} položek',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}