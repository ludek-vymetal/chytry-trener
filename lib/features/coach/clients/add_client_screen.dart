import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/coach/coach_clients_controller.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  String gender = 'male';
  bool eatingDisorderSupport = false;
  bool saving = false;

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
    if (!valid || saving) {
      return;
    }

    setState(() => saving = true);

    try {
      await ref.read(coachClientsControllerProvider.notifier).addClientManual(
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
        SnackBar(content: Text('Nepodařilo se uložit klienta: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  String _nextClientIdFrom(List<CoachClientWithStats> clients) {
    int maxNum = 0;

    for (final c in clients) {
      final id = c.client.clientId;
      if (id.startsWith('C') && id.length > 1) {
        final n = int.tryParse(id.substring(1));
        if (n != null && n > maxNum) {
          maxNum = n;
        }
      }
    }

    return 'C${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(coachClientsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nový klient')),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
        data: (clients) {
          final nextId = _nextClientIdFrom(clients);

          return ListView(
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
                      Text(
                        'ID klienta: $nextId',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                      : const Text('Uložit klienta'),
                  onPressed: valid && !saving ? save : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}