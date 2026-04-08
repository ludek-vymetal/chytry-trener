import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../models/goal.dart';
import 'goal_detail_screen.dart';

class OnboardingGoalScreen extends ConsumerWidget {
  const OnboardingGoalScreen({super.key});

  void _openDetail(BuildContext context, GoalType type, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalDetailScreen(type: type, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tvůj cíl'),
        leading: IconButton(
          icon: const Icon(Icons.swap_horiz),
          tooltip: 'Změnit režim',
          onPressed: () => switchToRoleSelect(context, ref),
        ),
        actions: [
          TextButton(
            onPressed: () => switchToRoleSelect(context, ref),
            child: const Text('Změnit režim'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _goal('Síla', GoalType.strength, context),
            _goal('Postava', GoalType.physique, context),
            _goal('Hubnutí', GoalType.weightLoss, context),
            _goal('Vytrvalost', GoalType.endurance, context),
            _goal('Nabírání / podpora příjmu', GoalType.weightGainSupport, context),
          ],
        ),
      ),
    );
  }

  Widget _goal(String title, GoalType type, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _openDetail(context, type, title),
      ),
    );
  }
}