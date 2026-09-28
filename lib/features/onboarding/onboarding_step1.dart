import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/user_profile_provider.dart';

import 'onboarding_goal_screen.dart';

/// Úvodní nastavení na jedné obrazovce: věk, pohlaví, výška a váha.
/// Potom rovnou výběr cíle.
class OnboardingStep1 extends ConsumerStatefulWidget {
  const OnboardingStep1({super.key});

  @override
  ConsumerState<OnboardingStep1> createState() => _OnboardingStep1State();
}

class _OnboardingStep1State extends ConsumerState<OnboardingStep1> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _gender;

  bool get _isValid =>
      _ageController.text.trim().isNotEmpty &&
      _gender != null &&
      _heightController.text.trim().isNotEmpty &&
      _weightController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _saveAndContinue() {
    final l10n = AppLocalizations.of(context)!;

    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 10 || age > 100) {
      _showError(l10n.enterValidAge);
      return;
    }

    final height = int.tryParse(_heightController.text.trim());
    if (height == null || height < 120 || height > 230) {
      _showError(l10n.enterValidHeight);
      return;
    }

    final weight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    if (weight == null || weight < 30 || weight > 300) {
      _showError(l10n.enterValidWeightRange);
      return;
    }

    final notifier = ref.read(userProfileProvider.notifier);
    notifier.setBasicInfo(age: age, gender: _gender!);
    notifier.setBodyMetrics(height: height, weight: weight);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingGoalScreen()),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String hint, {
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.startWithBasics),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => switchToRoleSelect(context, ref),
            child: Text(l10n.changeMode),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label(l10n.gender),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: Text(l10n.female),
                  selected: _gender == 'female',
                  onSelected: (_) => setState(() => _gender = 'female'),
                ),
                ChoiceChip(
                  label: Text(l10n.male),
                  selected: _gender == 'male',
                  onSelected: (_) => setState(() => _gender = 'male'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _label(l10n.howOldAreYou),
            _numberField(_ageController, l10n.enterAge),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(l10n.heightCm),
                      _numberField(_heightController, l10n.heightExample),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(l10n.weightKg),
                      _numberField(
                        _weightController,
                        l10n.weightExample,
                        decimal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isValid ? _saveAndContinue : null,
                child: Text(l10n.continueText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
