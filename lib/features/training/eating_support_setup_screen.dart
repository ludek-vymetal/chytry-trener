import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

import '../../models/goal.dart';
import '../../providers/user_profile_provider.dart';

class EatingSupportSetupScreen extends ConsumerStatefulWidget {
  const EatingSupportSetupScreen({super.key});

  @override
  ConsumerState<EatingSupportSetupScreen> createState() =>
      _EatingSupportSetupScreenState();
}

class _EatingSupportSetupScreenState
    extends ConsumerState<EatingSupportSetupScreen> {
  bool avoidNumbers = true;
  bool hasMedicalSupport = false;
  String focus = 'energy'; // energy | strength | routine
  String note = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return Scaffold(
        body: Center(
          child: Text(l10n.setupProfileAndGoalFirst),
        ),
      );
    }

    final goal = profile.goal!;

    final isThisMode = goal.type == GoalType.weightGainSupport &&
        goal.reason == GoalReason.eatingDisorderSupport;

    if (!isThisMode) {
      return Scaffold(
        body: Center(
          child: Text(l10n.eatingSupportOnlyMode),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.safeModeTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.safeModeDescription,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.safetyAndPreferences,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: avoidNumbers,
                      title: Text(
                        l10n.hideNutritionNumbers,
                      ),
                      subtitle: Text(
                        l10n.hideNutritionNumbersDescription,
                      ),
                      onChanged: (v) => setState(() => avoidNumbers = v),
                    ),
                    SwitchListTile(
                      value: hasMedicalSupport,
                      title: Text(
                        l10n.medicalSupport,
                      ),
                      subtitle: Text(
                        l10n.medicalSupportDescription,
                      ),
                      onChanged: (v) =>
                          setState(() => hasMedicalSupport = v),
                    ),
                    const SizedBox(height: 10),
                    Text(l10n.focusQuestion),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: focus,
                      items: [
                        DropdownMenuItem(
                          value: 'energy',
                          child: Text(
                            l10n.focusEnergyRoutine,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'strength',
                          child: Text(
                            l10n.focusStrengthPerformance,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'routine',
                          child: Text(
                            l10n.focusGentleMode,
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => focus = v ?? 'energy'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.optionalNote,
                        helperText: l10n.optionalNoteDescription,
                      ),
                      minLines: 2,
                      maxLines: 5,
                      onChanged: (v) => note = v,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.amber.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n.mentalHealthWarning,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final mergedNote = [
                    goal.note,
                    'safeMode:avoidNumbers=$avoidNumbers',
                    'safeMode:hasSupport=$hasMedicalSupport',
                    'safeMode:focus=$focus',
                    if (note.trim().isNotEmpty)
                      'safeMode:userNote=${note.trim()}',
                  ]
                      .where(
                        (x) =>
                            x != null &&
                            x.toString().trim().isNotEmpty,
                      )
                      .join(' | ');

                  ref.read(userProfileProvider.notifier).setGoal(
                        goal.copyWith(
                          note: mergedNote,
                        ),
                      );

                  Navigator.pop(context);
                },
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}