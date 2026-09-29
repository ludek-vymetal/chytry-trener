import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/food_exclusions_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../logic/diet_macro_service.dart';
import '../logic/food_catalog.dart';
import '../logic/meal_plan_math.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';
import '../widgets/meal_plan_actions.dart';

/// Editor vlastního jídelníčku: dny → jídla → potraviny.
///
/// Makroživiny se počítají z potravin v katalogu (celé gramy), porce se
/// dají upravit tlačítky +/- nebo přesným číslem. Hotový jídelníček se
/// uloží s vlastním názvem – ke klientovi nebo jako šablona.
class CustomMealPlanEditorScreen extends ConsumerStatefulWidget {
  /// Výchozí jídelníček (např. vygenerovaný) – upraví se a uloží jako nový.
  final DietMealPlan? initialPlan;

  /// Upravovaný uložený jídelníček.
  final SavedMealPlan? existing;

  final String? suggestedName;

  const CustomMealPlanEditorScreen({
    super.key,
    this.initialPlan,
    this.existing,
    this.suggestedName,
  });

  @override
  ConsumerState<CustomMealPlanEditorScreen> createState() =>
      _CustomMealPlanEditorScreenState();
}

class _Slot {
  final String label;
  final String time;
  const _Slot(this.label, this.time);
}

const _slots = [
  _Slot('Snídaně', '7:00'),
  _Slot('Dopolední svačina', '10:00'),
  _Slot('Oběd', '12:30'),
  _Slot('Odpolední svačina', '15:30'),
  _Slot('Večeře', '18:30'),
  _Slot('Druhá večeře', '21:00'),
  _Slot('Před tréninkem', ''),
  _Slot('Po tréninku', ''),
];

class _Pick {
  final NutritionFood? food;
  const _Pick(this.food);
}

class _CustomMealPlanEditorScreenState
    extends ConsumerState<CustomMealPlanEditorScreen> {
  late List<PlannedDay> _days;
  late String _planType;
  String? _note;
  int _day = 0;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final source = widget.existing?.plan ?? widget.initialPlan;
    if (source == null || source.days.isEmpty) {
      _planType = source?.planType ?? 'Custom';
      _note = source?.note;
      _days = [_emptyDay('Den 1')];
    } else {
      _planType = source.planType;
      _note = source.note;
      _days = [
        for (final d in source.days)
          _withTotals(
            d,
            [
              for (final m in d.meals)
                MealPlanMath.normalizeMeal(m, fillName: false),
            ],
          ),
      ];
    }
  }

  // ------------------------------------------------------------------
  // Pomocné
  // ------------------------------------------------------------------

  PlannedMeal _emptyMeal(_Slot s) => PlannedMeal(
        label: s.label,
        name: '',
        description: '',
        ingredients: const [],
        time: s.time.isEmpty ? null : s.time,
        calories: 0,
        protein: 0,
        carbs: 0,
        fats: 0,
      );

  PlannedDay _emptyDay(String name) => PlannedDay(
        dayName: name,
        meals: [for (final s in _slots.take(5)) _emptyMeal(s)],
        protein: 0,
        carbs: 0,
        fats: 0,
      );

  PlannedDay _withTotals(PlannedDay d, List<PlannedMeal> meals) {
    final t = MealPlanMath.totalsOf(meals);
    return PlannedDay(
      dayName: d.dayName,
      meals: meals,
      protein: t.protein.roundToDouble(),
      carbs: t.carbs.roundToDouble(),
      fats: t.fats.roundToDouble(),
    );
  }

  PlannedDay get _current => _days[_day];

  void _setMeals(List<PlannedMeal> meals) {
    setState(() {
      _days[_day] = _withTotals(_current, meals);
      _dirty = true;
    });
  }

  void _setMeal(int index, PlannedMeal meal) {
    final meals = [..._current.meals];
    if (meal.ingredients.isEmpty) {
      meals[index] = PlannedMeal(
        label: meal.label,
        name: meal.name,
        description: '',
        ingredients: const [],
        time: meal.time,
        calories: 0,
        protein: 0,
        carbs: 0,
        fats: 0,
      );
    } else {
      meals[index] = MealPlanMath.normalizeMeal(
        meal,
        rebuildText: true,
        fillName: false,
      );
    }
    _setMeals(meals);
  }

  void _setIngredients(int mealIndex, List<MealIngredient> items) {
    final m = _current.meals[mealIndex];
    _setMeal(mealIndex, m.copyWith(ingredients: items));
  }

  DietDayTargets? _target() {
    final p = ref.read(userProfileProvider);
    if (p == null || p.goal == null || p.weight <= 0) return null;
    return p.selectedPlan.toLowerCase() == 'keto'
        ? DietMacroService.keto(p)
        : DietMacroService.linear(p);
  }

  String _amountText(MealIngredient i) {
    final unit = i.unit.trim().toLowerCase();
    if (unit == 'ks') {
      final piece = MealPlanMath.foodFor(i.name)?.pieceGrams;
      return piece == null
          ? '${i.amount.round()} ks'
          : '${i.amount.round()} ks (${(i.amount * piece).round()} g)';
    }
    return '${i.amount.round()} ${i.unit}';
  }

  Future<double?> _askNumber(String title, double initial, String unit) async {
    final ctrl = TextEditingController(text: initial.round().toString());
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (s) => Navigator.pop(ctx, s),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (v == null) return null;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return null;
    return n;
  }

  Future<bool> _confirm(String title, String text, String ok) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ok),
          ),
        ],
      ),
    );
    return r == true;
  }

  // ------------------------------------------------------------------
  // Potraviny
  // ------------------------------------------------------------------

  Future<void> _addIngredient(int mealIndex) async {
    final excluded = FoodCatalog.activeExclusions;
    var query = '';
    final pick = await showModalBottomSheet<_Pick>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final cs = Theme.of(ctx).colorScheme;
          final q = query.trim().toLowerCase();
          final foods = FoodCatalog.all
              .where((f) =>
                  q.isEmpty || f.displayName.toLowerCase().contains(q))
              .toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName));
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.85,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Přidat potravinu',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Hledat (kuřecí, rýže, vejce…)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setLocal(() => query = v),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      itemCount: foods.length,
                      itemBuilder: (_, i) {
                        final f = foods[i];
                        final banned = FoodCatalog.isExcluded(f, excluded);
                        return ListTile(
                          dense: true,
                          title: Text(f.displayName),
                          subtitle: Text(
                            '${f.kcal.round()} kcal · B ${f.protein.round()} · '
                            'S ${f.carbs.round()} · T ${f.fat.round()} g / 100 g'
                            '${f.pieceGrams == null ? '' : ' · 1 ks ≈ ${f.pieceGrams!.round()} g'}',
                          ),
                          trailing: banned
                              ? Chip(
                                  label: const Text('vyloučeno'),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: cs.errorContainer,
                                  labelStyle:
                                      TextStyle(color: cs.onErrorContainer),
                                )
                              : null,
                          onTap: () => Navigator.pop(ctx, _Pick(f)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, const _Pick(null)),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Vlastní položka (mimo katalog)'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (pick == null || !mounted) return;

    final items = [..._current.meals[mealIndex].ingredients];
    final food = pick.food;
    if (food == null) {
      final item = await _customItemDialog();
      if (item == null) return;
      items.add(item);
      _setIngredients(mealIndex, items);
      return;
    }

    if (FoodCatalog.isExcluded(food, excluded)) {
      final go = await _confirm(
        'Vyloučená potravina',
        '${food.displayName} má klient vyloučenou (alergie / nesnášenlivost). '
            'Opravdu ji chceš přidat?',
        'Přesto přidat',
      );
      if (!go || !mounted) return;
    }

    final base = MealPlanMath.ingredientFor(food, MealPlanMath.defaultAmount(food));
    final amount = await _askNumber(food.displayName, base.amount, base.unit);
    if (amount == null) return;
    items.add(base.copyWith(
      amount: MealPlanMath.roundAmount(amount, base.unit, food: food),
    ));
    _setIngredients(mealIndex, items);
  }

  Future<MealIngredient?> _customItemDialog() async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '100');
    var unit = 'g';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Vlastní položka'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Název (např. Protein tyčinka)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Množství',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'g', label: Text('g')),
                        ButtonSegment(value: 'ml', label: Text('ml')),
                        ButtonSegment(value: 'ks', label: Text('ks')),
                      ],
                      selected: {unit},
                      onSelectionChanged: (s) =>
                          setLocal(() => unit = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Položka není v katalogu, proto makra tohoto jídla '
                  'zadáš ručně (menu jídla → Makra ručně).',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Zrušit'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Přidat'),
            ),
          ],
        ),
      ),
    );
    final name = nameCtrl.text.trim();
    final amount =
        double.tryParse(amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (ok != true || name.isEmpty || amount <= 0) return null;
    return MealIngredient(
      name: name,
      amount: MealPlanMath.roundAmount(amount, unit),
      unit: unit,
    );
  }

  void _stepIngredient(int mealIndex, int i, int dir) {
    final items = [..._current.meals[mealIndex].ingredients];
    final it = items[i];
    final step = MealPlanMath.stepFor(it);
    final next = it.amount + step * dir;
    if (next <= 0) return;
    items[i] = it.copyWith(
      amount: MealPlanMath.roundAmount(next, it.unit,
          food: MealPlanMath.foodFor(it.name)),
    );
    _setIngredients(mealIndex, items);
  }

  Future<void> _editAmount(int mealIndex, int i) async {
    final it = _current.meals[mealIndex].ingredients[i];
    final v = await _askNumber(it.name, it.amount, it.unit);
    if (v == null) return;
    final items = [..._current.meals[mealIndex].ingredients];
    items[i] = it.copyWith(
      amount: MealPlanMath.roundAmount(v, it.unit,
          food: MealPlanMath.foodFor(it.name)),
    );
    _setIngredients(mealIndex, items);
  }

  // ------------------------------------------------------------------
  // Jídla
  // ------------------------------------------------------------------

  Future<void> _addMeal() async {
    final used = _current.meals.map((m) => m.label).toSet();
    final slot = await showModalBottomSheet<_Slot>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in _slots)
              ListTile(
                leading: Icon(
                  used.contains(s.label)
                      ? Icons.check_circle_outline
                      : Icons.restaurant_outlined,
                ),
                title: Text(s.label),
                subtitle: s.time.isEmpty ? null : Text(s.time),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (slot == null) return;
    final meals = [..._current.meals, _emptyMeal(slot)];
    int order(PlannedMeal m) {
      final i = _slots.indexWhere((s) => s.label == m.label);
      return i < 0 ? 99 : i;
    }

    // Standardní jídla řadíme podle dne, tréninková nechá trenér na konci.
    if (slot.time.isNotEmpty) meals.sort((a, b) => order(a).compareTo(order(b)));
    _setMeals(meals);
  }

  Future<void> _editMealHeader(int index) async {
    final m = _current.meals[index];
    final labelCtrl = TextEditingController(text: m.label);
    final nameCtrl = TextEditingController(text: m.name);
    final timeCtrl = TextEditingController(text: m.time ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upravit jídlo'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jídlo dne (Snídaně, Oběd…)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Název jídla',
                  hintText: 'prázdné = doplní se z potravin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Čas (nepovinné)',
                  hintText: 'např. 7:00',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final meals = [..._current.meals];
    final time = timeCtrl.text.trim();
    meals[index] = PlannedMeal(
      label: labelCtrl.text.trim().isEmpty ? m.label : labelCtrl.text.trim(),
      name: nameCtrl.text.trim(),
      description: m.description,
      ingredients: m.ingredients,
      time: time.isEmpty ? null : time,
      calories: m.calories,
      protein: m.protein,
      carbs: m.carbs,
      fats: m.fats,
      grams: m.grams,
    );
    _setMeals(meals);
  }

  Future<void> _manualMacros(int index) async {
    final m = _current.meals[index];
    final p = TextEditingController(text: (m.protein ?? 0).round().toString());
    final c = TextEditingController(text: (m.carbs ?? 0).round().toString());
    final f = TextEditingController(text: (m.fats ?? 0).round().toString());
    Widget field(String label, TextEditingController ctrl) => Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              suffixText: 'g',
              border: const OutlineInputBorder(),
            ),
          ),
        );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Makroživiny jídla'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Jídlo obsahuje položku mimo katalog, makra proto zadej ručně '
                '(celé gramy). Kalorie se dopočítají.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  field('Bílkoviny', p),
                  const SizedBox(width: 8),
                  field('Sacharidy', c),
                  const SizedBox(width: 8),
                  field('Tuky', f),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    double n(TextEditingController t) =>
        (double.tryParse(t.text.trim().replaceAll(',', '.')) ?? 0)
            .roundToDouble()
            .clamp(0, 1000)
            .toDouble();
    final meals = [..._current.meals];
    meals[index] = PlannedMeal(
      label: m.label,
      name: m.name,
      description: m.description,
      ingredients: m.ingredients,
      time: m.time,
      protein: n(p),
      carbs: n(c),
      fats: n(f),
      calories: n(p) * 4 + n(c) * 4 + n(f) * 9,
      grams: m.grams,
    );
    _setMeals(meals);
  }

  void _moveMeal(int index, int dir) {
    final to = index + dir;
    if (to < 0 || to >= _current.meals.length) return;
    final meals = [..._current.meals];
    final m = meals.removeAt(index);
    meals.insert(to, m);
    _setMeals(meals);
  }

  // ------------------------------------------------------------------
  // Dny
  // ------------------------------------------------------------------

  void _addDay({required bool copy}) {
    setState(() {
      final name = 'Den ${_days.length + 1}';
      _days.add(copy
          ? _withTotals(_current, _current.meals).copyWith(dayName: name)
          : _emptyDay(name));
      _day = _days.length - 1;
      _dirty = true;
    });
  }

  Future<void> _renameDay() async {
    final ctrl = TextEditingController(text: _current.dayName);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Název dne'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'např. Pondělí / Tréninkový den',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (s) => Navigator.pop(ctx, s),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
    if (v == null || v.trim().isEmpty) return;
    setState(() {
      _days[_day] = _current.copyWith(dayName: v.trim());
      _dirty = true;
    });
  }

  Future<void> _dayAction(String action) async {
    final target = _target();
    switch (action) {
      case 'rename':
        await _renameDay();
      case 'copyAll':
        if (!await _confirm(
          'Kopírovat do všech dnů?',
          'Jídla ze dne „${_current.dayName}“ se nastaví do všech ostatních '
              'dnů (jejich názvy zůstanou).',
          'Kopírovat',
        )) {
          return;
        }
        setState(() {
          final meals = _current.meals;
          _days = [
            for (final d in _days) _withTotals(d, meals),
          ];
          _dirty = true;
        });
      case 'fitDay':
        if (target == null) return;
        setState(() {
          _days[_day] = _fit(_current, target.kcal);
          _dirty = true;
        });
      case 'fitAll':
        if (target == null) return;
        setState(() {
          _days = [for (final d in _days) _fit(d, target.kcal)];
          _dirty = true;
        });
      case 'delete':
        if (_days.length <= 1) return;
        if (!await _confirm(
          'Smazat den?',
          'Den „${_current.dayName}“ se odstraní i se všemi jídly.',
          'Smazat',
        )) {
          return;
        }
        setState(() {
          _days.removeAt(_day);
          _day = _day.clamp(0, _days.length - 1);
          _dirty = true;
        });
    }
  }

  PlannedDay _fit(PlannedDay d, double kcal) {
    final scaled = MealPlanMath.scaleDayToKcal(d, kcal);
    return _withTotals(scaled, [
      for (final m in scaled.meals)
        m.ingredients.isEmpty ? m : MealPlanMath.normalizeMeal(m, fillName: false),
    ]);
  }

  // ------------------------------------------------------------------
  // Uložení
  // ------------------------------------------------------------------

  Future<void> _save() async {
    final days = [
      for (final d in _days)
        d.copyWith(
          meals: [
            for (final m in d.meals)
              if (m.ingredients.isNotEmpty || (m.calories ?? 0) > 0) m,
          ],
        ),
    ].where((d) => d.meals.isNotEmpty).toList();

    if (days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Přidej aspoň jedno jídlo s potravinami.'),
        ),
      );
      return;
    }

    final plan = MealPlanMath.normalizePlan(
      DietMealPlan(
        planType: _planType,
        days: days,
        protein: 0,
        carbs: 0,
        fats: 0,
        note: _note,
      ),
    );

    final saved = await MealPlanActions.saveDialog(
      context,
      ref,
      plan,
      existing: widget.existing,
      suggestedName: widget.suggestedName,
    );
    if (saved == null || !mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved.isTemplate
              ? 'Uloženo do knihovny jako „${saved.name}“.'
              : 'Uloženo u klienta ${saved.clientName ?? ''} jako „${saved.name}“.',
        ),
      ),
    );
    Navigator.pop(context, saved);
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Alergie aktivního klienta (pro označení vyloučených potravin).
    ref.watch(activeFoodExclusionsProvider);
    ref.watch(userProfileProvider);
    final target = _target();
    final day = _current;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirm(
          'Odejít bez uložení?',
          'Změny v jídelníčku se neuloží.',
          'Odejít',
        );
        if (leave && context.mounted) {
          setState(() => _dirty = false);
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing?.name ?? 'Vlastní jídelníček'),
          actions: [
            IconButton(
              tooltip: 'Uložit',
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Uložit jídelníček'),
        ),
        body: Column(
          children: [
            _TargetBar(day: day, target: target),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  for (var i = 0; i < _days.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(_days[i].dayName),
                        selected: i == _day,
                        onSelected: (_) => setState(() => _day = i),
                      ),
                    ),
                  PopupMenuButton<bool>(
                    tooltip: 'Přidat den',
                    onSelected: (copy) => _addDay(copy: copy),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: true, child: Text('Kopie tohoto dne')),
                      PopupMenuItem(value: false, child: Text('Prázdný den')),
                    ],
                    child: Chip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Den'),
                      backgroundColor: cs.secondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          day.dayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Možnosti dne',
                        onSelected: _dayAction,
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('Přejmenovat den'),
                          ),
                          if (_days.length > 1)
                            const PopupMenuItem(
                              value: 'copyAll',
                              child: Text('Kopírovat do všech dnů'),
                            ),
                          if (target != null) ...[
                            PopupMenuItem(
                              value: 'fitDay',
                              child: Text(
                                'Doladit den na cíl '
                                '(${MealPlanActions.kcalText(target.kcal)})',
                              ),
                            ),
                            if (_days.length > 1)
                              const PopupMenuItem(
                                value: 'fitAll',
                                child: Text('Doladit všechny dny na cíl'),
                              ),
                          ],
                          if (_days.length > 1)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Smazat den'),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < day.meals.length; i++)
                    _mealCard(context, i, day.meals[i]),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addMeal,
                    icon: const Icon(Icons.add),
                    label: const Text('Přidat jídlo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealCard(BuildContext context, int index, PlannedMeal m) {
    final cs = Theme.of(context).colorScheme;
    final excluded = FoodCatalog.activeExclusions;
    final known = m.ingredients.isEmpty ||
        MealPlanMath.macrosOf(m.ingredients) != null;
    final kcal = (m.calories ?? 0).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _editMealHeader(index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.time == null ? m.label : '${m.time} · ${m.label}',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          m.name.trim().isNotEmpty
                              ? m.name
                              : (m.ingredients.isEmpty
                                  ? 'Zatím prázdné'
                                  : MealPlanMath.autoName(m.ingredients)),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: m.name.trim().isEmpty
                                ? cs.onSurfaceVariant
                                : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        _editMealHeader(index);
                      case 'macros':
                        _manualMacros(index);
                      case 'up':
                        _moveMeal(index, -1);
                      case 'down':
                        _moveMeal(index, 1);
                      case 'dup':
                        _setMeals([..._current.meals]..insert(index + 1, m));
                      case 'delete':
                        _setMeals([..._current.meals]..removeAt(index));
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Název a čas')),
                    if (!known)
                      const PopupMenuItem(
                          value: 'macros', child: Text('Makra ručně')),
                    if (index > 0)
                      const PopupMenuItem(
                          value: 'up', child: Text('Posunout nahoru')),
                    if (index < _current.meals.length - 1)
                      const PopupMenuItem(
                          value: 'down', child: Text('Posunout dolů')),
                    const PopupMenuItem(value: 'dup', child: Text('Duplikovat')),
                    const PopupMenuItem(value: 'delete', child: Text('Smazat')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$kcal kcal · B ${(m.protein ?? 0).round()} g · '
              'S ${(m.carbs ?? 0).round()} g · T ${(m.fats ?? 0).round()} g'
              '${known ? '' : ' · zadáno ručně'}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < m.ingredients.length; i++)
              _ingredientRow(context, index, i, m.ingredients[i], excluded),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addIngredient(index),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Potravina'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientRow(
    BuildContext context,
    int mealIndex,
    int i,
    MealIngredient it,
    List<String> excluded,
  ) {
    final cs = Theme.of(context).colorScheme;
    final food = MealPlanMath.foodFor(it.name);
    final mm = MealPlanMath.macrosOfIngredient(it);
    final banned = food != null && FoodCatalog.isExcluded(food, excluded);
    const dense = VisualDensity(horizontal: -4, vertical: -4);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: banned ? cs.error : null,
                    fontWeight: banned ? FontWeight.w700 : null,
                  ),
                ),
                Text(
                  banned
                      ? 'vyloučeno u klienta!'
                      : mm == null
                          ? 'mimo katalog'
                          : '${mm.kcal.round()} kcal · B ${mm.protein.round()} · '
                              'S ${mm.carbs.round()} · T ${mm.fats.round()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: banned ? cs.error : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: dense,
            tooltip: 'Méně',
            onPressed: () => _stepIngredient(mealIndex, i, -1),
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
          InkWell(
            onTap: () => _editAmount(mealIndex, i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minWidth: 64),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _amountText(it),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            visualDensity: dense,
            tooltip: 'Více',
            onPressed: () => _stepIngredient(mealIndex, i, 1),
            icon: const Icon(Icons.add_circle_outline, size: 20),
          ),
          IconButton(
            visualDensity: dense,
            tooltip: 'Odebrat',
            onPressed: () {
              final items = [..._current.meals[mealIndex].ingredients]
                ..removeAt(i);
              _setIngredients(mealIndex, items);
            },
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Horní lišta: součty dne vs. cíl klienta.
class _TargetBar extends StatelessWidget {
  final PlannedDay day;
  final DietDayTargets? target;

  const _TargetBar({required this.day, required this.target});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = MealPlanMath.totalsOf(day.meals);

    Color colorFor(double got, double want) {
      if (want <= 0) return cs.onPrimaryContainer;
      final diff = (got - want).abs() / want;
      if (diff <= 0.05) return Colors.green.shade700;
      if (diff <= 0.12) return Colors.orange.shade800;
      return cs.error;
    }

    Widget cell(String label, double got, double? want, String unit) {
      return Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer)),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${got.round()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: want == null
                          ? cs.onPrimaryContainer
                          : colorFor(got, want),
                    ),
                  ),
                  TextSpan(
                    text: want == null
                        ? ' $unit'
                        : ' / ${want.round()} $unit',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final tg = target;
    return Container(
      width: double.infinity,
      color: cs.primaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            runSpacing: 6,
            children: [
              cell('Kalorie', t.kcal, tg?.kcal, 'kcal'),
              cell('Bílkoviny', t.protein, tg?.protein, 'g'),
              cell('Sacharidy', t.carbs, tg?.carbs, 'g'),
              cell('Tuky', t.fats, tg?.fats, 'g'),
            ],
          ),
          if (tg == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Klient nemá nastavený cíl – porovnání s cílem se neukáže.',
                style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer),
              ),
            ),
        ],
      ),
    );
  }
}
