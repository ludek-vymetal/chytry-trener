import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/coach_client.dart';
import '../../../providers/coach/coach_clients_controller.dart';

class EditClientBasicInfoScreen extends ConsumerStatefulWidget {
  final CoachClient client;

  const EditClientBasicInfoScreen({
    super.key,
    required this.client,
  });

  @override
  ConsumerState<EditClientBasicInfoScreen> createState() =>
      _EditClientBasicInfoScreenState();
}

class _EditClientBasicInfoScreenState
    extends ConsumerState<EditClientBasicInfoScreen> {
  late final TextEditingController firstNameCtrl;
  late final TextEditingController lastNameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController ageCtrl;
  late final TextEditingController heightCtrl;
  late final TextEditingController weightCtrl;

  late String gender;
  late bool eatingDisorderSupport;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    firstNameCtrl = TextEditingController(text: widget.client.firstName);
    lastNameCtrl = TextEditingController(text: widget.client.lastName);
    emailCtrl = TextEditingController(text: widget.client.email);
    ageCtrl = TextEditingController(text: widget.client.age.toString());
    heightCtrl = TextEditingController(text: widget.client.heightCm.toString());
    weightCtrl = TextEditingController(
      text: widget.client.weightKg.toStringAsFixed(1),
    );

    gender = widget.client.gender;
    eatingDisorderSupport = widget.client.isEatingDisorderSupport;
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    ageCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) return true;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  bool get valid {
    return firstNameCtrl.text.trim().isNotEmpty &&
        lastNameCtrl.text.trim().isNotEmpty &&
        _emailValid &&
        int.tryParse(ageCtrl.text.trim()) != null &&
        int.tryParse(heightCtrl.text.trim()) != null &&
        double.tryParse(weightCtrl.text.trim().replaceAll(',', '.')) != null;
  }

  Future<void> save() async {
    if (!valid || saving) return;

    setState(() => saving = true);

    try {
      await ref.read(coachClientsControllerProvider.notifier).updateClientBasic(
            clientId: widget.client.clientId,
            firstName: firstNameCtrl.text.trim(),
            lastName: lastNameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            gender: gender,
            age: int.parse(ageCtrl.text.trim()),
            heightCm: int.parse(heightCtrl.text.trim()),
            weightKg: double.parse(weightCtrl.text.trim().replaceAll(',', '.')),
            isEatingDisorderSupport: eatingDisorderSupport,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nepodařilo se uložit změny: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upravit základní údaje')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.badge),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ID klienta: ${widget.client.clientId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Základní informace',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: firstNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Jméno',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: lastNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Příjmení',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'napr. klient@email.cz',
              border: const OutlineInputBorder(),
              errorText: _emailValid ? null : 'Zadej platný email',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: gender,
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Muž')),
              DropdownMenuItem(value: 'female', child: Text('Žena')),
              DropdownMenuItem(value: 'other', child: Text('Jiné')),
            ],
            onChanged: (v) => setState(() => gender = v ?? 'male'),
            decoration: const InputDecoration(
              labelText: 'Pohlaví',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ageCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Věk',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: heightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Výška (cm)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Váha (kg)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Režim recovery / PPP podpora'),
            subtitle: const Text(
              'Zapne bezpečnostní limity (žádné agresivní hubnutí)',
            ),
            value: eatingDisorderSupport,
            onChanged: (v) => setState(() => eatingDisorderSupport = v),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Uložit změny'),
              onPressed: valid && !saving ? save : null,
            ),
          ),
        ],
      ),
    );
  }
}