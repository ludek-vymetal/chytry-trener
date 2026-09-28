import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/user_profile_provider.dart';
import '../models/survey_result.dart';
import 'carb_cycling_logic.dart';
import 'carb_cycling_result_screen.dart';

class CarbCyclingSurveyScreen extends ConsumerStatefulWidget {
  const CarbCyclingSurveyScreen({super.key});

  @override
  ConsumerState<CarbCyclingSurveyScreen> createState() =>
      _CarbCyclingSurveyScreenState();
}

class _CarbCyclingSurveyScreenState
    extends ConsumerState<CarbCyclingSurveyScreen> {
  bool _hasHealthIssues = false;
  int _trainingFrequency = 3;
  final int _disciplineScore = 5;
  int _stressLevel = 5;
  int _sleepQuality = 7;
  bool _drinksEnough = true;

  SurveyResult _evaluate(AppLocalizations l10n) {
    if (_hasHealthIssues) {
      return SurveyResult(
        isEligible: false,
        message: l10n.carbCyclingHealthWarning,
      );
    }

    if (_stressLevel >= 8) {
      return SurveyResult(
        isEligible: false,
        message: l10n.carbCyclingStressWarning,
      );
    }

    if (_sleepQuality < 6) {
      return SurveyResult(
        isEligible: false,
        message: l10n.carbCyclingSleepWarning,
      );
    }

    if (_trainingFrequency < 3) {
      return SurveyResult(
        isEligible: false,
        message: l10n.carbCyclingTrainingWarning,
      );
    }

    String bonusMessage = '';

    if (!_drinksEnough) {
      bonusMessage =
          '\n\n${l10n.carbCyclingWaterWarning}';
    }

    return SurveyResult(
      isEligible: true,
      message:
          '${l10n.carbCyclingApprovedMessage}$bonusMessage',
      score:
          _disciplineScore +
          _trainingFrequency -
          (_stressLevel ~/ 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.carbCyclingReadinessTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              l10n.carbCyclingIntro,
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.blueGrey,
              ),
            ),

            const Divider(height: 40),

            _sectionTitle(
              l10n.healthState,
            ),

            SwitchListTile(
              title: Text(
                l10n.healthIssuesQuestion,
              ),
              subtitle: Text(
                l10n.healthIssuesDescription,
              ),
              value: _hasHealthIssues,
              onChanged: (v) {
                setState(() {
                  _hasHealthIssues = v;
                });
              },
              activeThumbColor: Colors.red,
            ),

            const SizedBox(height: 20),

            _sectionTitle(
              l10n.stressLevelQuestion,
            ),

            Slider(
              value: _stressLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label:
                  '${l10n.stressLabel}: $_stressLevel',
              onChanged: (v) {
                setState(() {
                  _stressLevel = v.toInt();
                });
              },
              activeColor:
                  _stressLevel > 7
                      ? Colors.red
                      : Colors.orange,
            ),

            _valueText(
              '${l10n.stressLevelValue}: $_stressLevel / 10',
            ),

            const SizedBox(height: 20),

            _sectionTitle(
              l10n.averageSleepLength,
            ),

            Slider(
              value: _sleepQuality.toDouble(),
              min: 3,
              max: 10,
              divisions: 7,
              label:
                  '$_sleepQuality ${l10n.hoursLabel}',
              onChanged: (v) {
                setState(() {
                  _sleepQuality = v.toInt();
                });
              },
              activeColor:
                  _sleepQuality < 6
                      ? Colors.red
                      : Colors.green,
            ),

            _valueText(
              '${l10n.sleepLabel}: $_sleepQuality ${l10n.hoursLabel}',
            ),

            const SizedBox(height: 20),

            _sectionTitle(
              l10n.trainingFrequencyTitle,
            ),

            Slider(
              value:
                  _trainingFrequency.toDouble(),
              min: 0,
              max: 7,
              divisions: 7,
              label:
                  '$_trainingFrequency ${l10n.trainingUnits}',
              onChanged: (v) {
                setState(() {
                  _trainingFrequency = v.toInt();
                });
              },
            ),

            _valueText(
              '${l10n.trainingLabel}: $_trainingFrequency',
            ),

            const SizedBox(height: 20),

            _sectionTitle(
              l10n.hydrationTitle,
            ),

            CheckboxListTile(
              title: Text(
                l10n.hydrationQuestion,
              ),
              value: _drinksEnough,
              onChanged: (v) {
                setState(() {
                  _drinksEnough = v ?? false;
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                onPressed: () {
                  final result =
                      _evaluate(l10n);

                  _showResultDialog(
                    result,
                    l10n,
                  );
                },
                child: Text(
                  l10n.evaluateReadiness,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _valueText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.orange,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showResultDialog(
    SurveyResult result,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
        title: Icon(
          result.isEligible
              ? Icons.check_circle
              : Icons.warning,
          color:
              result.isEligible
                  ? Colors.green
                  : Colors.red,
          size: 50,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.isEligible
                  ? l10n.approved
                  : l10n.notRecommended,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              result.message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                if (result.isEligible) {
                  final profile =
                      ref.read(
                    userProfileProvider,
                  );

                  if (profile != null) {
                    final plan =
                        CarbCyclingCalculator
                            .calculate(
                      profile: profile,
                      l10n: l10n,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CarbCyclingResultScreen(
                          plan: plan,
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(
                l10n.iUnderstand,
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}