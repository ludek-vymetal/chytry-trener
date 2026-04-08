import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/coach_body_diagnostic_entry.dart';
import '../../../providers/coach/coach_diagnostic_controller.dart';

class AddDiagnosticEntryScreen extends ConsumerStatefulWidget {
  final String clientId;
  final int heightCm;

  const AddDiagnosticEntryScreen({
    super.key,
    required this.clientId,
    required this.heightCm,
  });

  @override
  ConsumerState<AddDiagnosticEntryScreen> createState() =>
      _AddDiagnosticEntryScreenState();
}

class _AddDiagnosticEntryScreenState
    extends ConsumerState<AddDiagnosticEntryScreen> {
  final _weightCtrl = TextEditingController();
  final _smmCtrl = TextEditingController();
  final _fatKgCtrl = TextEditingController();
  final _fatPctCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();

  final _ffmCtrl = TextEditingController();
  final _whrCtrl = TextEditingController();
  final _bmrCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _smmCtrl.dispose();
    _fatKgCtrl.dispose();
    _fatPctCtrl.dispose();
    _waterCtrl.dispose();
    _ffmCtrl.dispose();
    _whrCtrl.dispose();
    _bmrCtrl.dispose();
    super.dispose();
  }

  double? _d(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  int? _i(TextEditingController c) => int.tryParse(c.text.trim());

  double? get _weight => _d(_weightCtrl);
  double? get _smm => _d(_smmCtrl);
  double? get _fatKg => _d(_fatKgCtrl);
  double? get _fatPct => _d(_fatPctCtrl);
  double? get _water => _d(_waterCtrl);

  double? get _ffm => _d(_ffmCtrl);
  double? get _whr => _d(_whrCtrl);
  int? get _bmr => _i(_bmrCtrl);

  bool get _valid {
    final w = _weight;
    final smm = _smm;
    final water = _water;

    if (w == null || w < 30 || w > 300) return false;
    if (smm == null || smm < 10 || smm > 80) return false;
    if (water == null || water < 10 || water > 80) return false;

    final hasFatKg = _fatKg != null;
    final hasFatPct = _fatPct != null;
    if (!hasFatKg && !hasFatPct) return false;

    if (hasFatPct && (_fatPct! < 2 || _fatPct! > 70)) return false;
    if (hasFatKg && (_fatKg! < 1 || _fatKg! > w)) return false;

    if (_whr != null && (_whr! < 0.5 || _whr! > 1.5)) return false;
    if (_bmr != null && (_bmr! < 800 || _bmr! > 4000)) return false;

    return true;
  }

  double? _calcFatKg(double weightKg, double? fatKg, double? fatPct) {
    if (fatKg != null) return fatKg;
    if (fatPct == null) return null;
    return weightKg * (fatPct / 100.0);
  }

  double? _calcFatPct(double weightKg, double? fatKg, double? fatPct) {
    if (fatPct != null) return fatPct;
    if (fatKg == null || weightKg <= 0) return null;
    return (fatKg / weightKg) * 100.0;
  }

  double? get _waterPctPreview {
    final w = _weight;
    final water = _water;
    if (w == null || water == null || w <= 0) return null;
    return (water / w) * 100.0;
  }

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
          content: Text(
            'Zkontroluj hodnoty. Hmotnost, SMM a voda musí být vyplněné. Tuk stačí zadat buď v kg, nebo v %.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final w = _weight!;
      final fatKg = _calcFatKg(w, _fatKg, _fatPct)!;
      final fatPct = _calcFatPct(w, _fatKg, _fatPct)!;
      final now = DateTime.now();

      final entry = CoachBodyDiagnosticEntry(
        entryId: 'D${now.millisecondsSinceEpoch}',
        clientId: widget.clientId,
        date: DateTime(_date.year, _date.month, _date.day),
        heightCm: widget.heightCm,
        weightKg: w,
        muscleKg: _smm!,
        fatKg: fatKg,
        fatPercent: fatPct,
        waterKg: _water!,
        fatFreeMassKg: _ffm,
        waistHipRatio: _whr,
        bmrKcal: _bmr,
        createdAt: now,
        updatedAt: now,
        updatedByDeviceId: 'local',
      );

      await ref.read(coachDiagnosticControllerProvider.notifier).addEntry(entry);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final waterPct = _waterPctPreview;

    return Scaffold(
      appBar: AppBar(title: const Text('Přidat InBody měření')),
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
                  Text('Výška: ${widget.heightCm} cm'),
                  const SizedBox(height: 10),
                  Text(
                    waterPct == null
                        ? 'Tip: po zadání hmotnosti a vody uvidíš i procento vody z váhy.'
                        : 'Voda tvoří cca ${waterPct.toStringAsFixed(1)} % z tělesné váhy (orientačně).',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _numField(_weightCtrl, 'Hmotnost (kg)'),
          const SizedBox(height: 10),
          _numField(_smmCtrl, 'SMM – kosterní svalovina (kg)'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tuk',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stačí vyplnit jednu hodnotu (kg nebo %). Druhá se dopočítá.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _numField(_fatKgCtrl, 'Tuk (kg)')),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_fatPctCtrl, 'Tuk (%)')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _numField(_waterCtrl, 'Celková voda v těle (kg)'),
          const SizedBox(height: 14),
          const Text(
            'Volitelné (pokud máš na výtisku)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _numField(_ffmCtrl, 'Čistá hmotnost těla (kg)'),
          const SizedBox(height: 10),
          _numField(_whrCtrl, 'Poměr pas/boky (WHR)'),
          const SizedBox(height: 10),
          TextField(
            controller: _bmrCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Bazální metabolismus (kcal)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Uložit měření'),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label) {
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