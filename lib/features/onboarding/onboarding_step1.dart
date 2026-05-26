import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../l10n/app_localizations.dart';

import '../../providers/user_profile_provider.dart';

import 'onboarding_step2.dart';

class OnboardingStep1
    extends ConsumerStatefulWidget {
  const OnboardingStep1({
    super.key,
  });

  @override
  ConsumerState<OnboardingStep1>
      createState() =>
          _OnboardingStep1State();
}

class _OnboardingStep1State
    extends ConsumerState<
        OnboardingStep1> {
  final TextEditingController
      _ageController =
          TextEditingController();

  String? _gender;

  bool get isValid =>
      _ageController.text
              .isNotEmpty &&
      _gender != null;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    final l10n =
        AppLocalizations.of(context)!;

    final age = int.tryParse(
      _ageController.text.trim(),
    );

    if (age == null ||
        age < 10 ||
        age > 100) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.enterValidAge,
          ),
        ),
      );

      return;
    }

    ref
        .read(
          userProfileProvider.notifier,
        )
        .setBasicInfo(
          age: age,
          gender: _gender!,
        );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const OnboardingStep2(),
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
          l10n.startWithBasics,
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
              l10n.howOldAreYou,

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
                  _ageController,

              keyboardType:
                  TextInputType.number,

              decoration:
                  InputDecoration(
                hintText:
                    l10n.enterAge,

                border:
                    const OutlineInputBorder(),
              ),

              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              l10n.gender,

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

            Row(
              children: [
                ChoiceChip(
                  label: Text(
                    l10n.male,
                  ),

                  selected:
                      _gender ==
                          'male',

                  onSelected: (_) {
                    setState(() {
                      _gender =
                          'male';
                    });
                  },
                ),

                const SizedBox(
                  width: 12,
                ),

                ChoiceChip(
                  label: Text(
                    l10n.female,
                  ),

                  selected:
                      _gender ==
                          'female',

                  onSelected: (_) {
                    setState(() {
                      _gender =
                          'female';
                    });
                  },
                ),
              ],
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