import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../l10n/app_localizations.dart';

import '../../models/coach/coach_client.dart';

import '../../providers/coach/active_client_provider.dart';
import '../../providers/user_profile_provider.dart';

import '../../services/coach/coach_storage_service.dart';

import 'onboarding_goal_screen.dart';
import 'onboarding_step1.dart';

final coachClientByIdProvider =
    FutureProvider.family<
        CoachClient?,
        String>(
  (ref, clientId) async {
    final all =
        await CoachStorageService
            .loadClients();

    try {
      return all.firstWhere(
        (c) =>
            c.clientId == clientId,
      );
    } catch (_) {
      return null;
    }
  },
);

class OnboardingProfileScreen
    extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({
    super.key,
  });

  @override
  ConsumerState<
          OnboardingProfileScreen>
      createState() =>
          _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<
        OnboardingProfileScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    final activeAsync = ref.watch(
      activeClientIdProvider,
    );

    final activeId =
        activeAsync.valueOrNull;

    if (activeId != null) {
      final clientAsync = ref.watch(
        coachClientByIdProvider(
          activeId,
        ),
      );

      return clientAsync.when(
        loading: () => const Scaffold(
          body: Center(
            child:
                CircularProgressIndicator(),
          ),
        ),

        error: (e, _) => Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.profile,
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.swap_horiz,
              ),
              onPressed: () =>
                  switchToRoleSelect(
                context,
                ref,
              ),
            ),
          ),
          body: Center(
            child: Text(
              '${l10n.error}: $e',
            ),
          ),
        ),

        data: (c) {
          if (c == null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  l10n.profile,
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.swap_horiz,
                  ),
                  onPressed: () =>
                      switchToRoleSelect(
                    context,
                    ref,
                  ),
                ),
              ),
              body: Center(
                child: Text(
                  l10n.profileNotFound,
                ),
              ),
            );
          }

          final current = ref.read(
            userProfileProvider,
          );

          final already =
              current?.clientId ==
                  c.clientId;

          if (!_navigated &&
              (already ||
                  current == null ||
                  current.clientId !=
                      c.clientId)) {
            _navigated = true;

            WidgetsBinding.instance
                .addPostFrameCallback(
              (_) {
                ref
                    .read(
                      userProfileProvider
                          .notifier,
                    )
                    .setProfileBasics(
                      clientId:
                          c.clientId,
                      age: c.age,
                      gender:
                          c.gender,
                      heightCm:
                          c.heightCm,
                      weightKg:
                          c.weightKg,
                    );

                if (!mounted) return;

                Navigator.of(context)
                    .pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        const OnboardingGoalScreen(),
                  ),
                );
              },
            );
          }

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    l10n
                        .loadingProfileFromCoach,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        },
      );
    }

    // Bez propojení s trenérem rovnou vyplní základní údaje.
    // (Vyhledávání v klientech trenéra do uživatelského režimu nepatří.)
    return const OnboardingStep1();
  }
}