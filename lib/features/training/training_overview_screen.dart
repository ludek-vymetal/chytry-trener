import 'package:flutter/material.dart';
import '../help/help_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/training_service.dart';
import 'custom_training_plan_screen.dart';
import 'split_selector_screen.dart';
import 'today_training_screen.dart';
import 'training_plan_screen.dart';
import 'training_setup_screen.dart';

class TrainingOverviewScreen extends ConsumerWidget {
  const TrainingOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;

    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.setGoalFirst,
          ),
        ),
      );
    }

    if (profile.trainingIntake == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.trainingMode,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.trainingSetupNeeded,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TrainingSetupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.openTrainingSetup,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final prescription =
        TrainingService.calculate(profile);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.trainingMode,
        ),
        actions: const [HelpButton(topic: 'training')],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      prescription.title,

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      prescription.note,

                      style: TextStyle(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            _ParamCard(
              title: l10n.repetitions,
              value: prescription.reps,
              icon: Icons.repeat,
            ),

            _ParamCard(
              title:
                  l10n.weeklySetsPerMuscle,
              value: prescription.sets,
              icon:
                  Icons.format_list_numbered,
            ),

            _ParamCard(
              title: l10n.rirReserve,
              value: prescription.rir,
              icon: Icons.speed,
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CustomTrainingPlanScreen(),
                    ),
                  );
                },

                child: Text(
                  l10n.buildCustomTraining,
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (prescription.deloadRecommended)
              _InfoBox(
                text:
                    l10n.deloadRecommendation,

                backgroundColor:
                    colorScheme
                        .tertiaryContainer,

                foregroundColor:
                    colorScheme
                        .onTertiaryContainer,

                icon: Icons.warning,
              ),

            if (prescription.peakMode)
              _InfoBox(
                text:
                    l10n.peakModeDescription,

                backgroundColor:
                    colorScheme
                        .secondaryContainer,

                foregroundColor:
                    colorScheme
                        .onSecondaryContainer,

                icon: Icons.trending_up,
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const TrainingPlanScreen(),
                    ),
                  );
                },

                child: Text(
                  l10n.weeklyPlan,
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const TodayTrainingScreen(),
                    ),
                  );
                },

                child: Text(
                  l10n.todayTraining,
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SplitSelectorScreen(),
                    ),
                  );
                },

                child: Text(
                  l10n.changeTrainingSplit,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              l10n.note,

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              l10n.trainingPlanDescription,

              style: TextStyle(
                color:
                    colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParamCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ParamCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: colorScheme.primary,
        ),

        title: Text(
          title,

          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),

        subtitle: Text(
          value,

          style: TextStyle(
            color:
                colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  const _InfoBox({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(8),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: foregroundColor,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,

              style: TextStyle(
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}