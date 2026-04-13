import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/user_profile_provider.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';
import '../providers/diet_plan_provider.dart';
import '../providers/saved_meal_plans_provider.dart';
import 'weekly_meal_plan_screen.dart';

class MonthlyTemplateBuilderScreen extends ConsumerStatefulWidget {
  const MonthlyTemplateBuilderScreen({super.key});

  @override
  ConsumerState<MonthlyTemplateBuilderScreen> createState() =>
      _MonthlyTemplateBuilderScreenState();
}

class _MonthlyTemplateBuilderScreenState
    extends ConsumerState<MonthlyTemplateBuilderScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;

  String? _week1Id;
  String? _week2Id;
  String? _week3Id;
  String? _week4Id;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: 'Měsíční jídelníček');
    _noteCtrl = TextEditingController(
      text: 'Další kontrola a vážení za 1 měsíc.',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _previewMonth(List<SavedMealPlan> plans) async {
    final monthlyPlan = _buildMonthlyPlan(plans);
    if (monthlyPlan == null) return;

    ref.read(dietPlanProvider.notifier).state = monthlyPlan;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyMealPlanScreen(
          mealPlan: monthlyPlan,
          titleOverride: _titleCtrl.text.trim().isEmpty
              ? 'Měsíční jídelníček'
              : _titleCtrl.text.trim(),
        ),
      ),
    );
  }

  Future<void> _saveMonth(List<SavedMealPlan> plans) async {
    final monthlyPlan = _buildMonthlyPlan(plans);
    if (monthlyPlan == null) return;

    final profile = ref.read(userProfileProvider);
    final title = _titleCtrl.text.trim();

    if (title.isEmpty) {
      _showSnack('Vyplň název měsíčního jídelníčku.');
      return;
    }

    await ref.read(savedMealPlansProvider.notifier).saveTemplate(
          name: title,
          plan: monthlyPlan,
          baseWeight: profile?.weight ?? 0,
          baseCalories: profile?.tdee ?? 0,
          durationDays: monthlyPlan.days.length,
          trainerNote: _noteCtrl.text.trim(),
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Měsíční jídelníček byl uložen.'),
      ),
    );

    Navigator.pop(context);
  }

  DietMealPlan? _buildMonthlyPlan(List<SavedMealPlan> plans) {
    final selectedWeeks = [
      _findPlan(plans, _week1Id),
      _findPlan(plans, _week2Id),
      _findPlan(plans, _week3Id),
      _findPlan(plans, _week4Id),
    ];

    if (selectedWeeks.any((e) => e == null)) {
      _showSnack('Vyber všechny 4 týdny.');
      return null;
    }

    final resolvedWeeks = selectedWeeks.whereType<SavedMealPlan>().toList();

    final days = <PlannedDay>[];
    for (var weekIndex = 0; weekIndex < resolvedWeeks.length; weekIndex++) {
      final week = resolvedWeeks[weekIndex];

      for (final day in week.plan.days) {
        days.add(
          day.copyWith(
            dayName: 'Týden ${weekIndex + 1} • ${day.dayName}',
          ),
        );
      }
    }

    final avgProtein = days.isEmpty
        ? 0.0
        : days.map((d) => d.protein).reduce((a, b) => a + b) / days.length;

    final avgCarbs = days.isEmpty
        ? 0.0
        : days.map((d) => d.carbs).reduce((a, b) => a + b) / days.length;

    final avgFats = days.isEmpty
        ? 0.0
        : days.map((d) => d.fats).reduce((a, b) => a + b) / days.length;

    return DietMealPlan(
      planType: 'Monthly',
      days: days,
      protein: avgProtein,
      carbs: avgCarbs,
      fats: avgFats,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
  }

  SavedMealPlan? _findPlan(List<SavedMealPlan> plans, String? id) {
    if (id == null) return null;
    try {
      return plans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allPlans = ref.watch(savedMealPlansProvider);

    final weeklyPlans = allPlans.where((p) => p.durationDays <= 8).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sestavit měsíční jídelníček'),
      ),
      body: weeklyPlans.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nejdřív si ulož alespoň jeden týdenní jídelníček.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
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
                            labelText: 'Název měsíčního jídelníčku',
                            border: OutlineInputBorder(),
                          ),
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
                _weekPickerCard(
                  context,
                  title: 'Týden 1',
                  plans: weeklyPlans,
                  value: _week1Id,
                  onChanged: (value) => setState(() => _week1Id = value),
                ),
                const SizedBox(height: 12),
                _weekPickerCard(
                  context,
                  title: 'Týden 2',
                  plans: weeklyPlans,
                  value: _week2Id,
                  onChanged: (value) => setState(() => _week2Id = value),
                ),
                const SizedBox(height: 12),
                _weekPickerCard(
                  context,
                  title: 'Týden 3',
                  plans: weeklyPlans,
                  value: _week3Id,
                  onChanged: (value) => setState(() => _week3Id = value),
                ),
                const SizedBox(height: 12),
                _weekPickerCard(
                  context,
                  title: 'Týden 4',
                  plans: weeklyPlans,
                  value: _week4Id,
                  onChanged: (value) => setState(() => _week4Id = value),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _previewMonth(weeklyPlans),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('NÁHLED MĚSÍČNÍHO PLÁNU'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _saveMonth(weeklyPlans),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('ULOŽIT MĚSÍČNÍ JÍDELNÍČEK'),
                ),
              ],
            ),
    );
  }

  Widget _weekPickerCard(
    BuildContext context, {
    required String title,
    required List<SavedMealPlan> plans,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = value == null ? null : _findPlan(plans, value);

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
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: value,
              decoration: const InputDecoration(
                labelText: 'Vyber uložený týden',
                border: OutlineInputBorder(),
              ),
              items: plans
                  .map(
                    (plan) => DropdownMenuItem<String>(
                      value: plan.id,
                      child: Text(plan.name),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
            if (selected != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Typ: ${selected.planType} • ${selected.durationDays} dní • základ ${selected.baseWeight.toStringAsFixed(1)} kg',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}