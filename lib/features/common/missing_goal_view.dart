import 'package:flutter/material.dart';

import '../onboarding/onboarding_goal_screen.dart';

/// Obrazovka, když chybí cíl. Vždy má cestu dál: nastavit cíl nebo
/// se vrátit zpět (dřív tu uživatel uvízl bez tlačítek).
class MissingGoalScaffold extends StatelessWidget {
  final String title;
  final String? message;

  const MissingGoalScaffold({
    super.key,
    this.title = '',
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined, size: 48, color: cs.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Nejdřív je potřeba nastavit cíl',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message ??
                          'Z cíle (hubnutí, postava, síla…) se počítá trénink '
                              'i jídelníček. Zabere to minutu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingGoalScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.flag),
                      label: const Text('Nastavit cíl'),
                    ),
                    if (canPop) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Zpět'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
