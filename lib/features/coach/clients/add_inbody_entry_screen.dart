import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../../../models/coach/coach_inbody_entry.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
import '../../../services/coach/coach_storage_service.dart';

class AddInbodyEntryScreen
    extends ConsumerStatefulWidget {
  final String clientId;
  final int heightCm;

  const AddInbodyEntryScreen({
    super.key,
    required this.clientId,
    required this.heightCm,
  });

  @override
  ConsumerState<AddInbodyEntryScreen>
      createState() =>
          _AddInbodyEntryScreenState();
}

class _AddInbodyEntryScreenState
    extends ConsumerState<AddInbodyEntryScreen> {
  DateTime _date = DateTime.now();

  bool _saving = false;

  // Tělesná kompozice
  final weight =
      TextEditingController();

  final smm =
      TextEditingController();

  final fatKg =
      TextEditingController();

  final water =
      TextEditingController();

  final lean =
      TextEditingController();

  // Diagnóza obezity
  final bmi =
      TextEditingController();

  final pbf =
      TextEditingController();

  final whr =
      TextEditingController();

  final bmr =
      TextEditingController();

  // Segmentální svaly
  final mLA =
      TextEditingController();

  final mRA =
      TextEditingController();

  final mTR =
      TextEditingController();

  final mLL =
      TextEditingController();

  final mRL =
      TextEditingController();

  // Segmentální tuk
  final fLA =
      TextEditingController();

  final fRA =
      TextEditingController();

  final fTR =
      TextEditingController();

  final fLL =
      TextEditingController();

  final fRL =
      TextEditingController();

  // Nepovinné
  final visceral =
      TextEditingController();

  final score =
      TextEditingController();

  @override
  void dispose() {
    for (final c in [
      weight,
      smm,
      fatKg,
      water,
      lean,
      bmi,
      pbf,
      whr,
      bmr,
      mLA,
      mRA,
      mTR,
      mLL,
      mRL,
      fLA,
      fRA,
      fTR,
      fLL,
      fRL,
      visceral,
      score,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  double? _d(
    TextEditingController c,
  ) {
    return double.tryParse(
      c.text
          .trim()
          .replaceAll(',', '.'),
    );
  }

  /// Povinná je jen hmotnost a jedno z: % tuku, množství tuku, čistá hmota
  /// (ostatní se dopočítá) – stačí i váha bez segmentální analýzy.
  bool get _valid =>
      (_d(weight) ?? 0) > 0 &&
      ((_d(pbf) ?? 0) > 0 || (_d(fatKg) ?? 0) > 0 || (_d(lean) ?? 0) > 0);

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked =
        await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate:
          DateTime(now.year - 10),
      lastDate:
          DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_valid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: const Text(
            'Vyplň aspoň hmotnost a % tuku (nebo množství tuku / čistou hmotu). '
            'Ostatní hodnoty jsou nepovinné.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    final now = DateTime.now();

    final deviceId =
        await CoachStorageService
                .loadDeviceId() ??
            'local_device';

    // Dopočítání chybějících hodnot (váha bez segmentální analýzy).
    final wKg = _d(weight)!;
    double fatMass = _d(fatKg) ?? 0;
    double pct = _d(pbf) ?? 0;
    double leanKg = _d(lean) ?? 0;
    if (fatMass <= 0 && pct > 0) fatMass = wKg * pct / 100;
    if (fatMass <= 0 && leanKg > 0) fatMass = wKg - leanKg;
    if (fatMass < 0) fatMass = 0;
    if (leanKg <= 0) leanKg = wKg - fatMass;
    if (pct <= 0 && wKg > 0) pct = fatMass / wKg * 100;
    final hM = widget.heightCm / 100.0;
    final bmiValue =
        (_d(bmi) ?? 0) > 0 ? _d(bmi)! : (hM > 0 ? wKg / (hM * hM) : 0.0);

    final entry =
        CoachInbodyEntry(
      entryId:
          'I${DateTime.now().millisecondsSinceEpoch}',

      clientId:
          widget.clientId,

      date: DateTime(
        _date.year,
        _date.month,
        _date.day,
      ),

      heightCm:
          widget.heightCm,

      weightKg:
          wKg,

      smmKg:
          (_d(smm) ?? 0),

      fatKg:
          fatMass,

      waterKg:
          (_d(water) ?? 0),

      leanMassKg:
          leanKg,

      bmi: bmiValue,

      bodyFatPercent:
          pct,

      whr: (_d(whr) ?? 0),

      bmr: (_d(bmr) ?? 0),

      muscleLeftArmKg:
          (_d(mLA) ?? 0),

      muscleRightArmKg:
          (_d(mRA) ?? 0),

      muscleTrunkKg:
          (_d(mTR) ?? 0),

      muscleLeftLegKg:
          (_d(mLL) ?? 0),

      muscleRightLegKg:
          (_d(mRL) ?? 0),

      fatLeftArmKg:
          (_d(fLA) ?? 0),

      fatRightArmKg:
          (_d(fRA) ?? 0),

      fatTrunkKg:
          (_d(fTR) ?? 0),

      fatLeftLegKg:
          (_d(fLL) ?? 0),

      fatRightLegKg:
          (_d(fRL) ?? 0),

      visceralFatLevel:
          _d(visceral),

      inbodyScore:
          _d(score),

      createdAt: now,

      updatedAt: now,

      deletedAt: null,

      version: 1,

      updatedByDeviceId:
          deviceId,
    );

    await ref
        .read(
          coachInbodyControllerProvider
              .notifier,
        )
        .addEntry(entry);

    if (!mounted) return;

    Navigator.of(context)
        .pop(true);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.addInbody,
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(
          16,
        ),

        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                12,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    l10n.basicData,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.date}: ${_fmtDate(_date)}',
                        ),
                      ),

                      TextButton.icon(
                        onPressed:
                            _pickDate,

                        icon:
                            const Icon(
                          Icons
                              .calendar_month,
                        ),

                        label: Text(
                          l10n.change,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    '${l10n.clientHeight}: ${widget.heightCm} cm',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            l10n.bodyComposition,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          _num(
            weight,
            '${l10n.weightKg} *',
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            smm,
            l10n.muscleMass,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            fatKg,
            l10n.bodyFatMass,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            water,
            l10n.bodyWater,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            lean,
            l10n.leanBodyMass,
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            l10n.obesityDiagnosis,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          _num(
            bmi,
            'BMI',
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            pbf,
            l10n.bodyFatPercentage,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            whr,
            l10n.waistHipRatio,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            bmr,
            l10n.basalMetabolism,
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            l10n.segmentalMuscles,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          _num(
            mLA,
            l10n.leftArmMuscle,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            mRA,
            l10n.rightArmMuscle,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            mTR,
            l10n.trunkMuscle,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            mLL,
            l10n.leftLegMuscle,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            mRL,
            l10n.rightLegMuscle,
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            l10n.segmentalFat,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          _num(
            fLA,
            l10n.leftArmFat,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            fRA,
            l10n.rightArmFat,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            fTR,
            l10n.trunkFat,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            fLL,
            l10n.leftLegFat,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            fRL,
            l10n.rightLegFat,
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            l10n.optionalValues,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          _num(
            visceral,
            l10n.visceralFat,
          ),

          const SizedBox(
            height: 10,
          ),

          _num(
            score,
            l10n.inbodyScore,
          ),

          const SizedBox(
            height: 18,
          ),

          ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.save,
                  ),

            label: Text(
              l10n.saveInbody,
            ),

            onPressed:
                _saving
                    ? null
                    : _save,
          ),
        ],
      ),
    );
  }

  Widget _num(
    TextEditingController ctrl,
    String label,
  ) {
    return TextField(
      controller: ctrl,

      keyboardType:
          const TextInputType
              .numberWithOptions(
        decimal: true,
      ),

      decoration:
          InputDecoration(
        labelText: label,

        border:
            const OutlineInputBorder(),
      ),

      onChanged: (_) {
        setState(() {});
      },
    );
  }

  static String _fmtDate(
    DateTime d,
  ) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}