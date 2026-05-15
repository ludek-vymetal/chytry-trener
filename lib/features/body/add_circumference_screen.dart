import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/body_circumference.dart';
import '../../providers/user_profile_provider.dart';
import 'package:dart_application_1/l10n/app_localizations.dart';

class AddCircumferenceScreen extends ConsumerStatefulWidget {
  const AddCircumferenceScreen({super.key});

  @override
  ConsumerState<AddCircumferenceScreen> createState() =>
      _AddCircumferenceScreenState();
}

class _AddCircumferenceScreenState
    extends ConsumerState<AddCircumferenceScreen> {
  DateTime selectedDate = DateTime.now();

  final _waistController =
      TextEditingController();

  final _hipsController =
      TextEditingController();

  final _chestController =
      TextEditingController();

  final _bicepsController =
      TextEditingController();

  final _thighController =
      TextEditingController();

  final _neckController =
      TextEditingController();

  @override
  void dispose() {
    _waistController.dispose();
    _hipsController.dispose();
    _chestController.dispose();
    _bicepsController.dispose();
    _thighController.dispose();
    _neckController.dispose();

    super.dispose();
  }

  void _save() {
    final l10n =
        AppLocalizations.of(context)!;

    final waist = double.tryParse(
      _waistController.text,
    );

    final hips = double.tryParse(
      _hipsController.text,
    );

    final chest = double.tryParse(
      _chestController.text,
    );

    final biceps = double.tryParse(
      _bicepsController.text,
    );

    final thigh = double.tryParse(
      _thighController.text,
    );

    final neck = double.tryParse(
      _neckController.text,
    );

    if (waist == null ||
        hips == null ||
        chest == null ||
        biceps == null ||
        thigh == null ||
        neck == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.enterAllNumbers,
          ),
        ),
      );

      return;
    }

    final data = BodyCircumference(
      date: selectedDate,
      waist: waist,
      hips: hips,
      chest: chest,
      biceps: biceps,
      thigh: thigh,
      neck: neck,
    );

    ref
        .read(
          userProfileProvider.notifier,
        )
        .addCircumference(data);

    Navigator.pop(context);
  }

  Widget _field(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),

      child: TextField(
        controller: controller,

        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),

        decoration: InputDecoration(
          labelText: label,

          prefixIcon: const Icon(
            Icons.straighten,
            size: 20,
          ),

          border:
              const OutlineInputBorder(),

          filled: true,

          fillColor: Colors.grey[50],
        ),
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
          l10n.addNewCircumferences,
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text(
                  'Datum měření',
                ),

                subtitle: Text(
                  '${selectedDate.day}. ${selectedDate.month}. ${selectedDate.year}',

                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                trailing: const Icon(
                  Icons.calendar_month,
                ),

                onTap: () async {
                  final picked =
                      await showDatePicker(
                    context: context,
                    initialDate:
                        selectedDate,
                    firstDate:
                        DateTime(2020),
                    lastDate:
                        DateTime.now(),
                  );

                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            _field(
              'Pas (cm)',
              _waistController,
            ),

            _field(
              'Boky (cm)',
              _hipsController,
            ),

            _field(
              'Hrudník (cm)',
              _chestController,
            ),

            _field(
              'Biceps (cm)',
              _bicepsController,
            ),

            _field(
              'Stehno (cm)',
              _thighController,
            ),

            _field(
              'Krk (cm)',
              _neckController,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: _save,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blue,
                  foregroundColor:
                      Colors.white,
                ),

                child: const Text(
                  'ULOŽIT OBVODY',

                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}