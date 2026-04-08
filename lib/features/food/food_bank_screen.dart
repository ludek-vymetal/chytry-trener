import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/meal.dart';
import '../../providers/food_bank_provider.dart';

class FoodBankScreen extends ConsumerStatefulWidget {
  const FoodBankScreen({super.key});

  @override
  ConsumerState<FoodBankScreen> createState() => _FoodBankScreenState();
}

class _FoodBankScreenState extends ConsumerState<FoodBankScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openMealDialog({Meal? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final calCtrl = TextEditingController(
        text: existing == null ? '' : existing.caloriesPer100g.toString());
    final pCtrl = TextEditingController(
        text: existing == null ? '' : existing.proteinPer100g.toString());
    final cCtrl = TextEditingController(
        text: existing == null ? '' : existing.carbsPer100g.toString());
    final fCtrl = TextEditingController(
        text: existing == null ? '' : existing.fatsPer100g.toString());
    final defaultGCtrl = TextEditingController(
        text: existing == null ? '250' : existing.defaultGrams.toString());

    void toast(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'Přidat jídlo' : 'Upravit jídlo'),
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
                  decoration: const InputDecoration(labelText: 'Kalorie na 100 g'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bílkoviny na 100 g'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sacharidy na 100 g'),
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
                  decoration: const InputDecoration(labelText: 'Default gramáž (g)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  toast('Vyplň název');
                  return;
                }

                final cal = int.tryParse(calCtrl.text.trim());
                final p = double.tryParse(pCtrl.text.trim().replaceAll(',', '.'));
                final c = double.tryParse(cCtrl.text.trim().replaceAll(',', '.'));
                final f = double.tryParse(fCtrl.text.trim().replaceAll(',', '.'));
                final dg = int.tryParse(defaultGCtrl.text.trim());

                if (cal == null || p == null || c == null || f == null || dg == null) {
                  toast('Vyplň všechna čísla');
                  return;
                }

                if (dg < 10 || dg > 3000) {
                  toast('Default gramáž musí být 10–3000 g');
                  return;
                }

                final meal = Meal(
                  name: name,
                  caloriesPer100g: cal,
                  proteinPer100g: p,
                  carbsPer100g: c,
                  fatsPer100g: f,
                  defaultGrams: dg,
                );

                ref.read(foodBankProvider.notifier).upsert(meal);
                Navigator.of(ctx).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(foodBankProvider);

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? bank
        : bank.where((m) => m.name.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banka jídel'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMealDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Přidat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Hledat jídlo',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Položek: ${filtered.length}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Nic nenalezeno'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final m = filtered[i];
                        return ListTile(
                          title: Text(m.name),
                          subtitle: Text(
                            '100 g: ${m.caloriesPer100g} kcal • '
                            'B ${m.proteinPer100g} / S ${m.carbsPer100g} / T ${m.fatsPer100g} • '
                            'Default ${m.defaultGrams} g',
                          ),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _openMealDialog(existing: m),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 70), // prostor pro FAB
          ],
        ),
      ),
    );
  }
}
