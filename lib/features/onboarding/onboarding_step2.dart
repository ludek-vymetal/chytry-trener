import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../l10n/app_localizations.dart';

import '../../providers/user_profile_provider.dart';

import 'onboarding_goal_screen.dart';

class OnboardingStep2
    extends ConsumerStatefulWidget {
  const OnboardingStep2({
    super.key,
  });

  @override
  ConsumerState<OnboardingStep2>
      createState() =>
          _OnboardingStep2State();
}

class _OnboardingStep2State
    extends ConsumerState<
        OnboardingStep2> {
  final TextEditingController
      _heightController =
          TextEditingController();

  final TextEditingController
      _weightController =
          TextEditingController();

  bool get isValid =>
      _heightController.text
              .isNotEmpty &&
      _weightController.text
              .isNotEmpty;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    final l10n =
        AppLocalizations.of(context)!;

    final height = int.tryParse(
      _heightController.text.trim(),
    );

    final weight =
        double.tryParse(
      _weightController.text
          .trim()
          .replaceAll(',', '.'),
    );

    if (height == null ||
        height < 120 ||
        height > 230) {
      _showError(
        l10n.enterValidHeight,
      );

      return;
    }

    if (weight == null ||
        weight < 30 ||
        weight > 300) {
      _showError(
        l10n.enterValidWeightRange,
      );

      return;
    }

    ref
        .read(
          userProfileProvider.notifier,
        )
        .setBodyMetrics(
          height: height,
          weight: weight,
        );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const OnboardingGoalScreen(),
      ),
    );
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.bodyMetrics,
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.swap_horiz,
          ),

          tooltip:
              l10n.changeMode,

          onPressed: () =>
              switchToRoleSelect(
            context,
            ref,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () =>
                switchToRoleSelect(
              context,
              ref,
            ),

            child: Text(
              l10n.changeMode,
            ),
          ),
        ],
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            Text(
              l10n.heightCm,

              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            TextField(
              controller:
                  _heightController,

              keyboardType:
                  TextInputType.number,

              decoration:
                  InputDecoration(
                border:
                    const OutlineInputBorder(),

                hintText:
                    l10n.heightExample,
              ),

              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              l10n.weightKg,

              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            TextField(
              controller:
                  _weightController,

              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration:
                  InputDecoration(
                border:
                    const OutlineInputBorder(),

                hintText:
                    l10n.weightExample,
              ),

              onChanged: (_) {
                setState(() {});
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed:
                    isValid
                        ? _saveAndContinue
                        : null,

                child: Text(
                  l10n.continueText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}