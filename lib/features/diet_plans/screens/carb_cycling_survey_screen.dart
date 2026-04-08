import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  SurveyResult _evaluate() {
    if (_hasHealthIssues) {
      return SurveyResult(
        isEligible: false,
        message:
            'Vzhledem ke zdravotním rizikům (cukrovka/historie PPP) pro tebe nejsou vlny vhodné. Bezpečnost klienta je pro nás prioritou.',
      );
    }

    if (_stressLevel >= 8) {
      return SurveyResult(
        isEligible: false,
        message:
            'Máš teď příliš vysokou úroveň stresu. Sacharidové vlny jsou pro tělo další zátěží. Doporučujeme nejdříve stabilizovat režim na standardní stravě.',
      );
    }

    if (_sleepQuality < 6) {
      return SurveyResult(
        isEligible: false,
        message:
            'Spánek pod 6 hodin denně znemožňuje správnou regeneraci, kterou vlny vyžadují. Zaměř se nejdříve na odpočinek.',
      );
    }

    if (_trainingFrequency < 3) {
      return SurveyResult(
        isEligible: false,
        message:
            'Sacharidové vlny vyžadují alespoň 3 silové tréninky týdně, aby tělo dokázalo efektivně využít vysoké dny sacharidů.',
      );
    }

    String bonusMessage = '';
    if (!_drinksEnough) {
      bonusMessage =
          '\n\nPozor: Vlny výrazně hýbou s vodou v těle. Musíš začít víc pít!';
    }

    return SurveyResult(
      isEligible: true,
      message:
          'Gratulujeme! Jsi připraven na sacharidové vlny. Tvé tělo má dobré předpoklady pro cyklování živin.$bonusMessage',
      score: _disciplineScore + _trainingFrequency - (_stressLevel ~/ 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analýza připravenosti')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tento dotazník vyhodnotí, zda je pro tvé tělo bezpečné přejít na systém sacharidových vln.',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.blueGrey,
              ),
            ),
            const Divider(height: 40),
            _sectionTitle('Zdravotní stav'),
            SwitchListTile(
              title: const Text(
                'Cukrovka nebo historie PPP (poruchy příjmu potravy)?',
              ),
              subtitle: const Text(
                'Z důvodu bezpečnosti je toto přísné kritérium.',
              ),
              value: _hasHealthIssues,
              onChanged: (v) => setState(() => _hasHealthIssues = v),
              activeThumbColor: Colors.red,
            ),
            const SizedBox(height: 20),
            _sectionTitle('Aktuální úroveň stresu (1 = klid, 10 = vyhoření)'),
            Slider(
              value: _stressLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: 'Stres: $_stressLevel',
              onChanged: (v) => setState(() => _stressLevel = v.toInt()),
              activeColor: _stressLevel > 7 ? Colors.red : Colors.orange,
            ),
            _valueText('Úroveň stresu: $_stressLevel / 10'),
            const SizedBox(height: 20),
            _sectionTitle('Průměrná délka spánku'),
            Slider(
              value: _sleepQuality.toDouble(),
              min: 3,
              max: 10,
              divisions: 7,
              label: '$_sleepQuality hodin',
              onChanged: (v) => setState(() => _sleepQuality = v.toInt()),
              activeColor: _sleepQuality < 6 ? Colors.red : Colors.green,
            ),
            _valueText('Spánek: $_sleepQuality hodin'),
            const SizedBox(height: 20),
            _sectionTitle('Počet silových tréninků týdně'),
            Slider(
              value: _trainingFrequency.toDouble(),
              min: 0,
              max: 7,
              divisions: 7,
              label: '$_trainingFrequency tréninky',
              onChanged: (v) => setState(() => _trainingFrequency = v.toInt()),
            ),
            _valueText('Tréninky: $_trainingFrequency'),
            const SizedBox(height: 20),
            _sectionTitle('Pitný režim'),
            CheckboxListTile(
              title: const Text('Vypiji denně alespoň 2-3 litry vody?'),
              value: _drinksEnough,
              onChanged: (v) => setState(() => _drinksEnough = v ?? false),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final result = _evaluate();
                  _showResultDialog(result);
                },
                child: const Text(
                  'VYHODNOTIT PŘIPRAVENOST',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  void _showResultDialog(SurveyResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Icon(
          result.isEligible ? Icons.check_circle : Icons.warning,
          color: result.isEligible ? Colors.green : Colors.red,
          size: 50,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.isEligible ? 'SCHVÁLENO' : 'NEDOPORUČENO',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 15),
            Text(result.message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                if (result.isEligible) {
                  final profile = ref.read(userProfileProvider);

                  if (profile != null) {
                    final plan = CarbCyclingCalculator.calculate(
                      profile: profile,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CarbCyclingResultScreen(plan: plan),
                      ),
                    );
                  }
                }
              },
              child: const Text('Rozumím'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}