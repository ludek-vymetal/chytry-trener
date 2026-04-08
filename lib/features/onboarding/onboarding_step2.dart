import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../providers/user_profile_provider.dart';
import 'onboarding_goal_screen.dart';

class OnboardingStep2 extends ConsumerStatefulWidget {
  const OnboardingStep2({super.key});

  @override
  ConsumerState<OnboardingStep2> createState() => _OnboardingStep2State();
}

class _OnboardingStep2State extends ConsumerState<OnboardingStep2> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  bool get isValid => _heightController.text.isNotEmpty && _weightController.text.isNotEmpty;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    final height = int.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim().replaceAll(',', '.'));

    if (height == null || height < 120 || height > 230) {
      _showError('Zadej platnou výšku (120–230 cm)');
      return;
    }
    if (weight == null || weight < 30 || weight > 300) {
      _showError('Zadej platnou váhu (30–300 kg)');
      return;
    }

    ref.read(userProfileProvider.notifier).setBodyMetrics(
      height: height,
      weight: weight,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingGoalScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tělesné údaje'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Výška (cm)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Např. 180',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            const Text('Váha (kg)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Např. 85',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid ? _saveAndContinue : null,
                child: const Text('Pokračovat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}