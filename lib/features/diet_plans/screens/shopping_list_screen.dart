import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../logic/keto_calculator.dart';
import '../models/carb_cycling_food_logic.dart';
import '../models/carb_cycling_plan.dart';
import '../providers/diet_settings_provider.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  final CarbCyclingPlan? plan;
  final List<List<Map<String, String>>>? weeklyKetoMenu;
  final List<List<Map<String, String>>>? weeklyFastingMenu;
  final bool isKeto;
  final bool isFasting;

  const ShoppingListScreen({
    super.key,
    this.plan,
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
  late Map<String, double> items;
  List<String> checkedItems = [];

  Map<String, double> _calculateFastingItems(
    List<List<Map<String, String>>> menu,
  ) {
    final Map<String, double> totals = {};

    for (final day in menu) {
      for (final meal in day) {
        final String name = meal['name'] ?? 'Neznámé';
        totals[name] = (totals[name] ?? 0) + 1;
      }
    }

    return totals;
  }

  void _generateList() {
    final excluded = ref.read(excludedIngredientsProvider);

    if (widget.isFasting && widget.weeklyFastingMenu != null) {
      final rawItems = _calculateFastingItems(widget.weeklyFastingMenu!);
      items = rawItems;
    } else if (widget.isKeto && widget.weeklyKetoMenu != null) {
      items = KetoCalculator.getShoppingList(widget.weeklyKetoMenu!);
    } else if (widget.plan != null) {
      items = MealGenerator.generateShoppingList(
        widget.plan!,
        isKeto: false,
        excluded: excluded,
      );
    } else {
      items = {};
    }
  }

  void _shareToWhatsApp() {
    String titul = '🛒 *MŮJ NÁKUPNÍ SEZNAM*\n';
    if (widget.isKeto) {
      titul = '🛒 *MŮJ KETO NÁKUPNÍ SEZNAM*\n\n';
    }
    if (widget.isFasting) {
      titul = '🛒 *MŮJ FASTING NÁKUPNÍ SEZNAM*\n\n';
    }

    String textSeznamu = titul;

    items.forEach((name, weight) {
      final String amountStr;
      if (widget.isFasting) {
        amountStr = '${weight.toInt()}x porce';
      } else {
        amountStr = weight >= 1000
            ? '${(weight / 1000).toStringAsFixed(2)} kg'
            : '${weight.toInt()} g';
      }
      textSeznamu += '☐ $name ($amountStr)\n';
    });

    textSeznamu += '\n_Generováno tvým chytrým trenérem_ 🍏';
    Share.share(textSeznamu);
  }

  @override
  Widget build(BuildContext context) {
    _generateList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isKeto
              ? 'Keto nákup'
              : (widget.isFasting ? 'Fasting nákup' : 'Týdenní nákup'),
        ),
        backgroundColor: widget.isKeto || widget.isFasting
            ? Colors.indigo[700]
            : Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareToWhatsApp,
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Seznam je prázdný.'))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: widget.isKeto || widget.isFasting
                      ? Colors.indigo[50]
                      : Colors.green[50],
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_basket,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.isFasting
                              ? 'Seznam obsahuje všechna jídla pro tvé okno jídla na 7 dní.'
                              : 'Množství odpovídá tvému 7dennímu plánu.',
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
                      final String name = items.keys.elementAt(index);
                      final double weight = items[name]!;
                      final bool isChecked = checkedItems.contains(name);

                      final String displayAmount = widget.isFasting
                          ? '${weight.toInt()}x v týdnu'
                          : (weight >= 1000
                              ? '${(weight / 1000).toStringAsFixed(2)} kg'
                              : '${weight.toInt()} g');

                      return Card(
                        elevation: isChecked ? 0 : 2,
                        color: isChecked ? Colors.grey[200] : Colors.white,
                        child: CheckboxListTile(
                          activeColor: Colors.indigo,
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(displayAmount),
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                checkedItems.add(name);
                              } else {
                                checkedItems.remove(name);
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