import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../providers/user_profile_provider.dart';
import 'onboarding_step2.dart';

class OnboardingStep1 extends ConsumerStatefulWidget {
  const OnboardingStep1({super.key});

  @override
  ConsumerState<OnboardingStep1> createState() => _OnboardingStep1State();
}

class _OnboardingStep1State extends ConsumerState<OnboardingStep1> {
  final TextEditingController _ageController = TextEditingController();
  String? _gender;

  bool get isValid => _ageController.text.isNotEmpty && _gender != null;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    final age = int.tryParse(_ageController.text.trim());

    if (age == null || age < 10 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadej platný věk (10–100 let)')),
      );
      return;
    }

    ref.read(userProfileProvider.notifier).setBasicInfo(
      age: age,
      gender: _gender!,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingStep2()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Začneme základy'),
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
            const Text('Kolik ti je let?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Zadej věk',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            const Text('Pohlaví', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Muž'),
                  selected: _gender == 'male',
                  onSelected: (_) => setState(() => _gender = 'male'),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Žena'),
                  selected: _gender == 'female',
                  onSelected: (_) => setState(() => _gender = 'female'),
                ),
              ],
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