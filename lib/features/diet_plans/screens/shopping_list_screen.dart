import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../providers/diet_settings_provider.dart';
import '../logic/keto_calculator.dart';
import '../models/carb_cycling_food_logic.dart';
import '../models/carb_cycling_plan.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  final CarbCyclingPlan? plan;
  final DietMealPlan? mealPlan;
  final List<List<Map<String, String>>>? weeklyKetoMenu;
  final List<List<Map<String, String>>>? weeklyFastingMenu;
  final bool isKeto;
  final bool isFasting;

  const ShoppingListScreen({
    super.key,
    this.plan,
    this.mealPlan,
    this.weeklyKetoMenu,
    this.weeklyFastingMenu,
    this.isKeto = false,
    this.isFasting = false,
  });

  @override
  ConsumerState<ShoppingListScreen> createState() =>
      _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  late List<ShoppingListItem> items;
  final List<String> checkedItems = [];

  void _generateList() {
    final excluded = ref.read(excludedIngredientsProvider);

    if (widget.mealPlan != null) {
      items = widget.mealPlan!.buildShoppingList();
      return;
    }

    if (widget.isFasting && widget.weeklyFastingMenu != null) {
      final map = <String, double>{};
      for (final day in widget.weeklyFastingMenu!) {
        for (final meal in day) {
          final name = (meal['name'] ?? '').trim();
          if (name.isEmpty) continue;
          map[name] = (map[name] ?? 0) + 1;
        }
      }
      items = map.entries
          .map((e) => ShoppingListItem(name: e.key, amount: e.value, unit: 'x'))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return;
    }

    if (widget.isKeto && widget.weeklyKetoMenu != null) {
      final raw = KetoCalculator.getShoppingList(widget.weeklyKetoMenu!);
      items = raw.entries
          .map((e) => ShoppingListItem(name: e.key, amount: e.value, unit: 'x'))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return;
    }

    if (widget.plan != null) {
      final rawItems = MealGenerator.generateShoppingList(
        widget.plan!,
        isKeto: false,
        excluded: excluded,
      );

      items = rawItems.entries.map((e) {
        final key = e.key;
        if (key.contains('(') && key.contains(')')) {
          final name = key.substring(0, key.indexOf('(')).trim();
          final unit = key.substring(key.indexOf('(') + 1, key.indexOf(')')).trim();
          return ShoppingListItem(name: name, amount: e.value, unit: unit);
        }
        return ShoppingListItem(name: key, amount: e.value, unit: 'g');
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return;
    }

    items = [];
  }

  void _shareList() {
    final title = widget.isKeto
        ? '🛒 MŮJ KETO NÁKUPNÍ SEZNAM'
        : widget.isFasting
            ? '🛒 MŮJ FASTING NÁKUPNÍ SEZNAM'
            : '🛒 MŮJ NÁKUPNÍ SEZNAM';

    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln();

    for (final item in items) {
      buffer.writeln('☐ ${item.name} (${item.formattedAmount})');
    }

    buffer.writeln();
    buffer.writeln('Generováno tvým chytrým trenérem 🍏');

    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    _generateList();

    final colorScheme = Theme.of(context).colorScheme;
    final isSpecial = widget.isKeto || widget.isFasting;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isKeto
              ? 'Keto nákup'
              : (widget.isFasting ? 'Fasting nákup' : 'Týdenní nákup'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareList,
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Seznam je prázdný.'))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: isSpecial
                      ? colorScheme.secondaryContainer
                      : colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_basket),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Seznam obsahuje všechny ingredience ze všech dní a slučuje duplicity.',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isChecked = checkedItems.contains(item.name);

                      return Card(
                        elevation: isChecked ? 0 : 1,
                        color: isChecked
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surface,
                        child: CheckboxListTile(
                          activeColor: colorScheme.primary,
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(item.formattedAmount),
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                checkedItems.add(item.name);
                              } else {
                                checkedItems.remove(item.name);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}