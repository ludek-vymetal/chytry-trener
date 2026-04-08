import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/coach_inbody_entry.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
import '../../../services/coach/coach_storage_service.dart';

class AddInbodyEntryScreen extends ConsumerStatefulWidget {
  final String clientId;
  final int heightCm;

  const AddInbodyEntryScreen({
    super.key,
    required this.clientId,
    required this.heightCm,
  });

  @override
  ConsumerState<AddInbodyEntryScreen> createState() =>
      _AddInbodyEntryScreenState();
}

class _AddInbodyEntryScreenState extends ConsumerState<AddInbodyEntryScreen> {
  DateTime _date = DateTime.now();
  bool _saving = false;

  // Tělesná kompozice
  final weight = TextEditingController();
  final smm = TextEditingController();
  final fatKg = TextEditingController();
  final water = TextEditingController();
  final lean = TextEditingController();

  // Diagnóza obezity
  final bmi = TextEditingController();
  final pbf = TextEditingController();
  final whr = TextEditingController();
  final bmr = TextEditingController();

  // Segmentální svaly
  final mLA = TextEditingController();
  final mRA = TextEditingController();
  final mTR = TextEditingController();
  final mLL = TextEditingController();
  final mRL = TextEditingController();

  // Segmentální tuk
  final fLA = TextEditingController();
  final fRA = TextEditingController();
  final fTR = TextEditingController();
  final fLL = TextEditingController();
  final fRL = TextEditingController();

  // Nepovinné
  final visceral = TextEditingController();
  final score = TextEditingController();

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

  double? _d(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  bool get _valid =>
      _d(weight) != null &&
      _d(smm) != null &&
      _d(fatKg) != null &&
      _d(water) != null &&
      _d(lean) != null &&
      _d(bmi) != null &&
      _d(pbf) != null &&
      _d(whr) != null &&
      _d(bmr) != null &&
      _d(mLA) != null &&
      _d(mRA) != null &&
      _d(mTR) != null &&
      _d(mLL) != null &&
      _d(mRL) != null &&
      _d(fLA) != null &&
      _d(fRA) != null &&
      _d(fTR) != null &&
      _d(fLL) != null &&
      _d(fRL) != null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vyplň prosím všechny hodnoty podle InBody reportu.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final deviceId =
        await CoachStorageService.loadDeviceId() ?? 'local_device';

    final entry = CoachInbodyEntry(
      entryId: 'I${DateTime.now().millisecondsSinceEpoch}',
      clientId: widget.clientId,
      date: DateTime(_date.year, _date.month, _date.day),
      heightCm: widget.heightCm,
      weightKg: _d(weight)!,
      smmKg: _d(smm)!,
      fatKg: _d(fatKg)!,
      waterKg: _d(water)!,
      leanMassKg: _d(lean)!,
      bmi: _d(bmi)!,
      bodyFatPercent: _d(pbf)!,
      whr: _d(whr)!,
      bmr: _d(bmr)!,
      muscleLeftArmKg: _d(mLA)!,
      muscleRightArmKg: _d(mRA)!,
      muscleTrunkKg: _d(mTR)!,
      muscleLeftLegKg: _d(mLL)!,
      muscleRightLegKg: _d(mRL)!,
      fatLeftArmKg: _d(fLA)!,
      fatRightArmKg: _d(fRA)!,
      fatTrunkKg: _d(fTR)!,
      fatLeftLegKg: _d(fLL)!,
      fatRightLegKg: _d(fRL)!,
      visceralFatLevel: _d(visceral),
      inbodyScore: _d(score),
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: deviceId,
    );

    await ref.read(coachInbodyControllerProvider.notifier).addEntry(entry);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Přidat InBody')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Základ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text('Datum: ${_fmtDate(_date)}')),
                      TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Změnit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Výška klienta: ${widget.heightCm} cm'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tělesná kompozice',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _num(weight, 'Hmotnost (kg) *'),
          const SizedBox(height: 10),
          _num(smm, 'SMM – svalová hmota (kg) *'),
          const SizedBox(height: 10),
          _num(fatKg, 'Množství tuku v těle (kg) *'),
          const SizedBox(height: 10),
          _num(water, 'Celková voda v těle (kg/l) *'),
          const SizedBox(height: 10),
          _num(lean, 'Čistá hmota těla (kg) *'),
          const SizedBox(height: 14),
          const Text(
            'Diagnóza obezity',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _num(bmi, 'BMI *'),
          const SizedBox(height: 10),
          _num(pbf, '% tuku v těle *'),
          const SizedBox(height: 10),
          _num(whr, 'Poměr pas/boky (WHR) *'),
          const SizedBox(height: 10),
          _num(bmr, 'Bazální metabolismus (kcal) *'),
          const SizedBox(height: 14),
          const Text(
            'Segmentální svaly (kg)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _num(mLA, 'Levá ruka – svaly (kg) *'),
          const SizedBox(height: 10),
          _num(mRA, 'Pravá ruka – svaly (kg) *'),
          const SizedBox(height: 10),
          _num(mTR, 'Trup – svaly (kg) *'),
          const SizedBox(height: 10),
          _num(mLL, 'Levá noha – svaly (kg) *'),
          const SizedBox(height: 10),
          _num(mRL, 'Pravá noha – svaly (kg) *'),
          const SizedBox(height: 14),
          const Text(
            'Segmentální tuk (kg)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _num(fLA, 'Levá ruka – tuk (kg) *'),
          const SizedBox(height: 10),
          _num(fRA, 'Pravá ruka – tuk (kg) *'),
          const SizedBox(height: 10),
          _num(fTR, 'Trup – tuk (kg) *'),
          const SizedBox(height: 10),
          _num(fLL, 'Levá noha – tuk (kg) *'),
          const SizedBox(height: 10),
          _num(fRL, 'Pravá noha – tuk (kg) *'),
          const SizedBox(height: 14),
          const Text(
            'Nepovinné',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _num(visceral, 'Viscerální tuk (úroveň)'),
          const SizedBox(height: 10),
          _num(score, 'InBody skóre'),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Uložit InBody'),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  Widget _num(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}