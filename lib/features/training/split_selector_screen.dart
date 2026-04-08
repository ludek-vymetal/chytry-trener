import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/training/training_split.dart';
import '../../providers/user_profile_provider.dart';

class SplitSelectorScreen extends ConsumerWidget {
  const SplitSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('Profil nenalezen')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Výběr splitu'),
      ),
      body: RadioGroup<TrainingSplit>(
        groupValue: profile.preferredSplit,
        onChanged: (TrainingSplit? value) {
          if (value == null) {
            return;
          }

          ref.read(userProfileProvider.notifier).setPreferredSplit(value);
          Navigator.pop(context);
        },
        child: ListView(
          children: TrainingSplit.values.map((split) {
            return RadioListTile<TrainingSplit>(
              title: Text(split.label),
              value: split,
            );
          }).toList(),
        ),
      ),
    );
  }
}