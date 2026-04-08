import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_client.dart';
import '../../services/coach/coach_storage_service.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/user_profile_provider.dart';

import 'onboarding_goal_screen.dart';
import '../role/role_select_screen.dart';

final coachClientsFullProvider = FutureProvider<List<CoachClient>>((ref) async {
  final all = await CoachStorageService.loadClients();
  // volitelně: řazení podle jména
  all.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  return all;
});

class OnboardingLinkClientScreen extends ConsumerStatefulWidget {
  const OnboardingLinkClientScreen({super.key});

  @override
  ConsumerState<OnboardingLinkClientScreen> createState() => _OnboardingLinkClientScreenState();
}

class _OnboardingLinkClientScreenState extends ConsumerState<OnboardingLinkClientScreen> {
  CoachClient? _selected;

  void _backToRoleSelect() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
      (route) => false,
    );
  }

  void _continueWithoutCoach() {
    // pro jistotu vyčisti active client
    ref.read(activeClientIdProvider.notifier).clear();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingGoalScreen()),
    );
  }

  Future<void> _linkSelectedAndContinue() async {
    final c = _selected;
    if (c == null) return;

    // 1) uložit aktivního klienta
    await ref.read(activeClientIdProvider.notifier).setActive(c.clientId);

    // 2) autofill profilu z coach dat
    ref.read(userProfileProvider.notifier).setProfileBasics(
          age: c.age,
          gender: c.gender,
          heightCm: c.heightCm,
          weightKg: c.weightKg,
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingGoalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(coachClientsFullProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Propojit s trenérem'),
        leading: IconButton(
          icon: const Icon(Icons.swap_horiz),
          tooltip: 'Změnit režim',
          onPressed: _backToRoleSelect,
        ),
        actions: [
          TextButton(
            onPressed: _backToRoleSelect,
            child: const Text('Změnit režim'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: clientsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chyba při načítání klientů: $e'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continueWithoutCoach,
                  child: const Text('Pokračovat bez trenéra'),
                ),
              ),
            ],
          ),
          data: (clients) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vyhledej svého klienta podle jména',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Autocomplete<CoachClient>(
                  displayStringForOption: (c) => c.displayName,
                  optionsBuilder: (TextEditingValue q) {
                    final query = q.text.trim().toLowerCase();
                    if (query.isEmpty) return const Iterable<CoachClient>.empty();
                    return clients.where((c) => c.displayName.toLowerCase().contains(query));
                  },
                  onSelected: (c) => setState(() => _selected = c),
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Začni psát jméno…',
                      ),
                      onChanged: (_) => setState(() {
                        _selected = null; // když user mění text, zruš selection
                      }),
                    );
                  },
                ),

                const SizedBox(height: 12),

                if (_selected != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vybráno: ${_selected!.displayName}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Věk: ${_selected!.age}'),
                          Text('Pohlaví: ${_selected!.gender}'),
                          Text('Výška: ${_selected!.heightCm} cm'),
                          Text('Váha: ${_selected!.weightKg.toStringAsFixed(1)} kg'),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selected == null ? null : _linkSelectedAndContinue,
                    child: const Text('Propojit a pokračovat'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _continueWithoutCoach,
                    child: const Text('Pokračovat bez trenéra'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}