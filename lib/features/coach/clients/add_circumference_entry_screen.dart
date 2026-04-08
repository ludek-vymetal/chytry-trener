import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/coach_circumference_entry.dart';
import '../../../providers/coach/coach_circumference_controller.dart';
import '../../../services/coach/id_service.dart';

class AddCircumferenceEntryScreen extends ConsumerStatefulWidget {
  final String clientId;

  const AddCircumferenceEntryScreen({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<AddCircumferenceEntryScreen> createState() =>
      _AddCircumferenceEntryScreenState();
}

class _AddCircumferenceEntryScreenState
    extends ConsumerState<AddCircumferenceEntryScreen> {
  final neckCtrl = TextEditingController();
  final chestCtrl = TextEditingController();
  final waistCtrl = TextEditingController();
  final hipsCtrl = TextEditingController();
  final armCtrl = TextEditingController();
  final thighCtrl = TextEditingController();
  final calfCtrl = TextEditingController();

  DateTime date = DateTime.now();
  bool loading = false;

  @override
  void dispose() {
    neckCtrl.dispose();
    chestCtrl.dispose();
    waistCtrl.dispose();
    hipsCtrl.dispose();
    armCtrl.dispose();
    thighCtrl.dispose();
    calfCtrl.dispose();
    super.dispose();
  }

  double? _d(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  bool get valid {
    return _d(neckCtrl) != null &&
        _d(chestCtrl) != null &&
        _d(waistCtrl) != null &&
        _d(hipsCtrl) != null &&
        _d(armCtrl) != null &&
        _d(thighCtrl) != null &&
        _d(calfCtrl) != null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: date,
    );
    if (picked != null) {
      setState(() => date = picked);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> save() async {
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyplň prosím všechny obvody správně.')),
      );
      return;
    }

    if (loading) return;
    setState(() => loading = true);

    try {
      debugPrint(
        'SCREEN SAVE CIRC -> clientId=${widget.clientId} date=${date.toIso8601String()} '
        'neck=${_d(neckCtrl)} chest=${_d(chestCtrl)} waist=${_d(waistCtrl)} '
        'hips=${_d(hipsCtrl)} arm=${_d(armCtrl)} thigh=${_d(thighCtrl)} calf=${_d(calfCtrl)}',
      );

      final entry = CoachCircumferenceEntry(
        entryId: IdService.newId('CIRC'),
        clientId: widget.clientId,
        date: DateTime(date.year, date.month, date.day),
        neckCm: _d(neckCtrl)!,
        chestCm: _d(chestCtrl)!,
        waistCm: _d(waistCtrl)!,
        hipsCm: _d(hipsCtrl)!,
        armCm: _d(armCtrl)!,
        thighCm: _d(thighCtrl)!,
        calfCm: _d(calfCtrl)!,
      );

      await ref
          .read(coachCircumferenceControllerProvider.notifier)
          .addEntry(entry);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nepodařilo se uložit obvody: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Přidat obvody')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Datum měření'),
            subtitle: Text(_fmtDate(date)),
            trailing: TextButton(
              onPressed: _pickDate,
              child: const Text('Změnit'),
            ),
          ),
          const SizedBox(height: 8),
          _num(neckCtrl, 'Krk (cm)'),
          const SizedBox(height: 12),
          _num(chestCtrl, 'Hrudník (cm)'),
          const SizedBox(height: 12),
          _num(waistCtrl, 'Pas (cm)'),
          const SizedBox(height: 12),
          _num(hipsCtrl, 'Boky (cm)'),
          const SizedBox(height: 12),
          _num(armCtrl, 'Paže (cm)'),
          const SizedBox(height: 12),
          _num(thighCtrl, 'Stehno (cm)'),
          const SizedBox(height: 12),
          _num(calfCtrl, 'Lýtko (cm)'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: loading ? null : save,
            icon: const Icon(Icons.save),
            label: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Uložit'),
          ),
        ],
      ),
    );
  }

  Widget _num(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}