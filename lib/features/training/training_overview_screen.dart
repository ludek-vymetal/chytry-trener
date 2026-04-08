import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_provider.dart';
import '../../services/training_service.dart';
import 'training_plan_screen.dart';
import 'split_selector_screen.dart';
import 'training_setup_screen.dart';
import 'today_training_screen.dart';
import 'custom_training_plan_screen.dart';

class TrainingOverviewScreen extends ConsumerWidget {
  const TrainingOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return const Scaffold(
        body: Center(child: Text('Nejprve nastav cíl.')),
      );
    }

    if (profile.trainingIntake == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tréninkový režim')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Než vygenerujeme trénink, potřebuji krátké nastavení.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingSetupScreen(),
                      ),
                    );
                  },
                  child: const Text('Otevřít nastavení tréninku'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final prescription = TrainingService.calculate(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Tréninkový režim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prescription.note,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            _ParamCard(
              title: 'Opakování',
              value: prescription.reps,
              icon: Icons.repeat,
            ),
            _ParamCard(
              title: 'Série na partii (týdně)',
              value: prescription.sets,
              icon: Icons.format_list_numbered,
            ),
            _ParamCard(
              title: 'Rezerva (RIR)',
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
                      builder: (_) => const CustomTrainingPlanScreen(),
                    ),
                  );
                },
                child: const Text('Sestavit vlastní trénink'),
              ),
            ),

            const SizedBox(height: 16),

            if (prescription.deloadRecommended)
              _InfoBox(
                text:
                    'Doporučení: deload – pokud cítíš únavu, sniž objem o 30–40 % na 1 týden.',
                color: Colors.orangeAccent,
                icon: Icons.warning,
              ),

            if (prescription.peakMode)
              _InfoBox(
                text:
                    'Režim vrcholu (peak): technika > objem, delší pauzy, nízké opakování.',
                color: Colors.lightBlueAccent,
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
                      builder: (_) => const TrainingPlanScreen(),
                    ),
                  );
                },
                child: const Text('Týdenní plán'),
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
                      builder: (_) => const TodayTrainingScreen(),
                    ),
                  );
                },
                child: const Text('Dnešní trénink'),
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
                      builder: (_) => const SplitSelectorScreen(),
                    ),
                  );
                },
                child: const Text('Změnit rozložení tréninků'),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Poznámka',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Plán se generuje automaticky podle cíle a času.\n'
              'Vlastní plán slouží pro klienty se specifickými potřebami, omezeními nebo individuálním rozpisem.',
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
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _InfoBox({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}