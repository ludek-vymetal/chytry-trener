import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/goal.dart';
import '../../providers/user_profile_provider.dart';

class EatingSupportSetupScreen extends ConsumerStatefulWidget {
  const EatingSupportSetupScreen({super.key});

  @override
  ConsumerState<EatingSupportSetupScreen> createState() =>
      _EatingSupportSetupScreenState();
}

class _EatingSupportSetupScreenState
    extends ConsumerState<EatingSupportSetupScreen> {
  bool avoidNumbers = true;
  bool hasMedicalSupport = false;
  String focus = 'energy'; // energy | strength | routine
  String note = '';

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return const Scaffold(
        body: Center(child: Text('Nejprve nastav profil a cíl.')),
      );
    }

    final goal = profile.goal!;
    final isThisMode = goal.type == GoalType.weightGainSupport &&
        goal.reason == GoalReason.eatingDisorderSupport;

    if (!isThisMode) {
      return const Scaffold(
        body: Center(
          child: Text('Tento dotazník je jen pro režim Nabírání/PPP podpora.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Podpora nabírání / bezpečný režim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tenhle režim je navržený tak, aby nepodporoval restrikci ani kalorické počítání.\n'
              'Cílem je bezpečný návrat energie, rutiny a síly.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bezpečnost a preference',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: avoidNumbers,
                      title: const Text(
                        'Nezobrazovat čísla o výživě (kalorie/makra)',
                      ),
                      subtitle: const Text(
                        'Doporučeno – aplikace nebude tlačit na čísla.',
                      ),
                      onChanged: (v) => setState(() => avoidNumbers = v),
                    ),
                    SwitchListTile(
                      value: hasMedicalSupport,
                      title: const Text(
                        'Mám odbornou podporu (terapeut / lékař / nutriční)',
                      ),
                      subtitle: const Text(
                        'Pomůže to nastavit citlivější doporučení.',
                      ),
                      onChanged: (v) => setState(() => hasMedicalSupport = v),
                    ),
                    const SizedBox(height: 10),
                    const Text('Na co se chceš zaměřit teď nejvíc?'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: focus,
                      items: const [
                        DropdownMenuItem(
                          value: 'energy',
                          child: Text('Energie & rutina'),
                        ),
                        DropdownMenuItem(
                          value: 'strength',
                          child: Text('Síla & výkon'),
                        ),
                        DropdownMenuItem(
                          value: 'routine',
                          child: Text('Jemný režim bez tlaku'),
                        ),
                      ],
                      onChanged: (v) => setState(() => focus = v ?? 'energy'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Poznámka (volitelné)',
                        helperText:
                            'Např. “chci 3× týdně lehce”, “nechci vážení”, “preferuji stroje”.',
                      ),
                      minLines: 2,
                      maxLines: 5,
                      onChanged: (v) => note = v,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.amber.withValues(alpha: 0.15),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Pokud máš pocit, že je ti psychicky opravdu zle, nebo máš nutkání si ublížit, '
                  'vyhledej okamžitou pomoc. V ČR funguje Linka první psychické pomoci 116 123 (nonstop) '
                  'a Linka bezpečí 116 111 (nonstop pro děti a mladé).',
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final mergedNote = [
                    goal.note,
                    'safeMode:avoidNumbers=$avoidNumbers',
                    'safeMode:hasSupport=$hasMedicalSupport',
                    'safeMode:focus=$focus',
                    if (note.trim().isNotEmpty) 'safeMode:userNote=${note.trim()}',
                  ].where((x) => x != null && x.toString().trim().isNotEmpty).join(' | ');

                  ref.read(userProfileProvider.notifier).setGoal(
                        goal.copyWith(note: mergedNote),
                      );

                  Navigator.pop(context);
                },
                child: const Text('Uložit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}