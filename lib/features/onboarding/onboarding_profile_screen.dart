import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../models/coach/coach_client.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/coach/coach_storage_service.dart';

import 'onboarding_step1.dart';
import 'onboarding_goal_screen.dart';
// ✅ 1. IMPORTUJ OBRAZOVKU S JÍDELNÍČKEM
import '../diet_plans/screens/daily_menu_screen.dart';

final coachClientsFullListProvider = FutureProvider<List<CoachClient>>((ref) async {
  return CoachStorageService.loadClients();
});

final coachClientByIdProvider = FutureProvider.family<CoachClient?, String>((ref, clientId) async {
  final all = await CoachStorageService.loadClients();
  try {
    return all.firstWhere((c) => c.clientId == clientId);
  } catch (_) {
    return null;
  }
});

class OnboardingProfileScreen extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  ConsumerState<OnboardingProfileScreen> createState() => _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends ConsumerState<OnboardingProfileScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeClientIdProvider);
    final activeId = activeAsync.valueOrNull;

    // 1) když je active client -> načti a přejdi na cíle (JEN JEDNOU)
    if (activeId != null) {
      final clientAsync = ref.watch(coachClientByIdProvider(activeId));
      return clientAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Propojení profilu'),
            leading: IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => switchToRoleSelect(context, ref),
            ),
          ),
          body: Center(child: Text('Chyba načítání klienta: $e')),
        ),
        data: (c) {
          if (c == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Propojení profilu'),
                leading: IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () => switchToRoleSelect(context, ref),
                ),
              ),
              body: const Center(child: Text('Klient nenalezen')),
            );
          }

          // ✅ už je profil naplněný tímto klientem -> rovnou na cíle
          final current = ref.read(userProfileProvider);
          final already = current?.clientId == c.clientId;

          if (!_navigated && (already || current == null || current.clientId != c.clientId)) {
            _navigated = true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              // naplnění profilu
              ref.read(userProfileProvider.notifier).setProfileBasics(
                    clientId: c.clientId,
                    age: c.age,
                    gender: c.gender,
                    heightCm: c.heightCm,
                    weightKg: c.weightKg,
                  );

              if (!mounted) return;

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OnboardingGoalScreen()),
              );
            });
          }

          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Profil se přebírá z trenéra…'),
                  SizedBox(height: 12),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        },
      );
    }

    // 2) jinak: vyhledání klienta nebo pokračovat bez trenéra
    final clientsAsync = ref.watch(coachClientsFullListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.swap_horiz),
          tooltip: 'Změnit režim',
          onPressed: () => switchToRoleSelect(context, ref),
        ),
        actions: [
          TextButton(
            onPressed: () => switchToRoleSelect(context, ref),
            child: const Text('Změnit režim'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: clientsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Chyba načítání klientů: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingStep1()),
                  );
                },
                child: const Text('Pokračovat bez trenéra'),
              ),
            ],
          ),
          data: (clients) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Máš trenéra?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Vyhledej se v seznamu klientů a načteme ti profil automaticky.'),
                const SizedBox(height: 12),

                Autocomplete<CoachClient>(
                  optionsBuilder: (text) {
                    final q = text.text.trim().toLowerCase();
                    if (q.isEmpty) return const Iterable<CoachClient>.empty();
                    return clients.where((c) =>
                        c.displayName.toLowerCase().contains(q) ||
                        c.clientId.toLowerCase().contains(q));
                  },
                  displayStringForOption: (c) => c.displayName,
                  onSelected: (selected) async {
                    _navigated = false; // reset guard
                    await ref.read(activeClientIdProvider.notifier).setActive(selected.clientId);
                    if (!mounted) return;
                    setState(() {}); // donutí rebuild -> spadne do activeId části
                  },
                  fieldViewBuilder: (context, ctrl, focusNode, _) {
                    return TextField(
                      controller: ctrl,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Napiš jméno nebo ID klienta…',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OnboardingStep1()),
                    );
                  },
                  child: const Text('Pokračovat bez trenéra'),
                ),
                // ⬇️ 2. PŘIDÁNO TLAČÍTKO PRO JÍDELNÍČEK ⬇️
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DailyMenuScreen()),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Zobrazit můj jídelníček'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
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