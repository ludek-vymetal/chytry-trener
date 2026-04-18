import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../models/coach/coach_circumference_entry.dart';
import '../../../providers/coach/coach_circumference_controller.dart';

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
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();

  final _neckController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _armController = TextEditingController();
  final _thighController = TextEditingController();
  final _calfController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _neckController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _armController.dispose();
    _thighController.dispose();
    _calfController.dispose();
    super.dispose();
  }

  double _parseDouble(TextEditingController controller) {
    final raw = controller.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0.0;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();

      final entry = CoachCircumferenceEntry(
        entryId: _uuid.v4(),
        clientId: widget.clientId,
        date: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
        neckCm: _parseDouble(_neckController),
        chestCm: _parseDouble(_chestController),
        waistCm: _parseDouble(_waistController),
        hipsCm: _parseDouble(_hipsController),
        armCm: _parseDouble(_armController),
        thighCm: _parseDouble(_thighController),
        calfCm: _parseDouble(_calfController),
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        version: 1,
        updatedByDeviceId: 'local',
      );

      await ref
          .read(coachCircumferenceControllerProvider.notifier)
          .addEntry(entry);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nepodařilo se uložit míry: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _optionalNumberValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;

    final normalized = text.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);

    if (parsed == null) {
      return 'Zadej číslo';
    }

    if (parsed < 0) {
      return 'Hodnota nemůže být záporná';
    }

    return null;
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: _optionalNumberValidator,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Přidat míry'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Datum měření'),
                subtitle: Text(dateLabel),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                controller: _neckController,
                label: 'Krk (cm)',
              ),
              const SizedBox(height: 12),
              _buildNumberField(
                controller: _chestController,
                label: 'Hrudník (cm)',
              ),
              const SizedBox(height: 12),
              _buildNumberField(
                controller: _waistController,
                label: 'Pas (cm)',
              ),
              const SizedBox(height: 12),
              _buildNumberField(
                controller: _hipsController,
                label: 'Boky (cm)',
              ),
              const SizedBox(height: 12),
              _buildNumberField(
                controller: _armController,
                label: 'Paže (cm)',
              ),
              const SizedBox(height: 12),
              _buildNumberField(
                controller: _thighController,
                label: 'Stehno (cm)',
              ),
              const SizedBox(height: 12),
              _buildNumberField(
                controller: _calfController,
                label: 'Lýtko (cm)',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Ukládám...' : 'Uložit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}