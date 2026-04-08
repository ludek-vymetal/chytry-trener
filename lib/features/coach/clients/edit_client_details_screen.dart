import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/coach_client_details.dart';
import '../../../providers/coach/coach_client_details_controller.dart';

class EditClientDetailsScreen extends ConsumerStatefulWidget {
  final String clientId;

  const EditClientDetailsScreen({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<EditClientDetailsScreen> createState() =>
      _EditClientDetailsScreenState();
}

class _EditClientDetailsScreenState
    extends ConsumerState<EditClientDetailsScreen> {
  final occupationCtrl = TextEditingController();
  final injuriesCtrl = TextEditingController();
  final allergiesCtrl = TextEditingController();
  final intolerancesCtrl = TextEditingController();
  final healthCtrl = TextEditingController();

  final sleepHoursCtrl = TextEditingController();
  final stepsCtrl = TextEditingController();
  final motivationCtrl = TextEditingController();
  final preferredFoodsCtrl = TextEditingController();
  final dislikedFoodsCtrl = TextEditingController();

  String activityType = 'sedavé';
  String sleepQuality = 'průměrná';
  String stressLevel = 'střední';

  bool _inited = false;
  bool _saving = false;

  @override
  void dispose() {
    occupationCtrl.dispose();
    injuriesCtrl.dispose();
    allergiesCtrl.dispose();
    intolerancesCtrl.dispose();
    healthCtrl.dispose();
    sleepHoursCtrl.dispose();
    stepsCtrl.dispose();
    motivationCtrl.dispose();
    preferredFoodsCtrl.dispose();
    dislikedFoodsCtrl.dispose();
    super.dispose();
  }

  double _parseDouble(
    TextEditingController c, {
    required double fallback,
  }) {
    final s = c.text.trim().replaceAll(',', '.');
    return double.tryParse(s) ?? fallback;
  }

  int _parseInt(
    TextEditingController c, {
    required int fallback,
  }) {
    final s = c.text.trim();
    return int.tryParse(s) ?? fallback;
  }

  Future<void> _save(CoachClientDetails base) async {
    setState(() => _saving = true);

    final updated = base.copyWith(
      activityType: activityType,
      occupation: occupationCtrl.text.trim(),
      injuries: injuriesCtrl.text.trim(),
      allergies: allergiesCtrl.text.trim(),
      intolerances: intolerancesCtrl.text.trim(),
      healthNotes: healthCtrl.text.trim(),
      sleepHours: _parseDouble(
        sleepHoursCtrl,
        fallback: base.sleepHours,
      ).clamp(0.0, 14.0),
      sleepQuality: sleepQuality,
      stressLevel: stressLevel,
      stepsPerDay: _parseInt(
        stepsCtrl,
        fallback: base.stepsPerDay,
      ).clamp(0, 50000),
      motivation: motivationCtrl.text.trim(),
      preferredFoods: preferredFoodsCtrl.text.trim(),
      dislikedFoods: dislikedFoodsCtrl.text.trim(),
    );

    await ref
        .read(coachClientDetailsControllerProvider.notifier)
        .upsert(updated);

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync =
        ref.watch(coachClientDetailsForClientProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Upravit kartu klienta')),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
        data: (d) {
          if (!_inited) {
            activityType = d.activityType;
            sleepQuality = d.sleepQuality;
            stressLevel = d.stressLevel;

            occupationCtrl.text = d.occupation;
            injuriesCtrl.text = d.injuries;
            allergiesCtrl.text = d.allergies;
            intolerancesCtrl.text = d.intolerances;
            healthCtrl.text = d.healthNotes;

            sleepHoursCtrl.text = d.sleepHours.toStringAsFixed(1);
            stepsCtrl.text = d.stepsPerDay.toString();
            motivationCtrl.text = d.motivation;
            preferredFoodsCtrl.text = d.preferredFoods;
            dislikedFoodsCtrl.text = d.dislikedFoods;

            _inited = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                title: 'Životní styl',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: activityType,
                    items: const [
                      DropdownMenuItem(
                        value: 'sedavé',
                        child: Text('Sedavé zaměstnání'),
                      ),
                      DropdownMenuItem(
                        value: 'aktivní',
                        child: Text('Aktivní zaměstnání'),
                      ),
                      DropdownMenuItem(
                        value: 'těžká manuální',
                        child: Text('Těžká manuální práce'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => activityType = v ?? 'sedavé'),
                    decoration: const InputDecoration(
                      labelText: 'Denní aktivita / práce',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: occupationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Povolání (dobrovolné)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Regenerace',
                children: [
                  TextField(
                    controller: sleepHoursCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Spánek (průměr hodin)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: sleepQuality,
                    items: const [
                      DropdownMenuItem(value: 'dobrá', child: Text('Dobrá')),
                      DropdownMenuItem(
                        value: 'průměrná',
                        child: Text('Průměrná'),
                      ),
                      DropdownMenuItem(value: 'špatná', child: Text('Špatná')),
                    ],
                    onChanged: (v) =>
                        setState(() => sleepQuality = v ?? 'průměrná'),
                    decoration: const InputDecoration(
                      labelText: 'Kvalita spánku',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: stressLevel,
                    items: const [
                      DropdownMenuItem(value: 'nízký', child: Text('Nízký')),
                      DropdownMenuItem(
                        value: 'střední',
                        child: Text('Střední'),
                      ),
                      DropdownMenuItem(value: 'vysoký', child: Text('Vysoký')),
                    ],
                    onChanged: (v) =>
                        setState(() => stressLevel = v ?? 'střední'),
                    decoration: const InputDecoration(
                      labelText: 'Stres',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stepsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Denní kroky (orientačně)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Zdraví a omezení',
                children: [
                  TextField(
                    controller: injuriesCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Zranění / omezení / operace',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: allergiesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alergie',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: intolerancesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Intolerance',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: healthCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Zdravotní poznámky',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Strava a motivace',
                children: [
                  TextField(
                    controller: motivationCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Cíl / motivace',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: preferredFoodsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Preferované potraviny',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dislikedFoodsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Potraviny které nechce / vadí mu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Uložit'),
                onPressed: _saving ? null : () => _save(d),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}