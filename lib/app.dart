import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/role/role_select_screen.dart';
import 'features/onboarding/onboarding_profile_screen.dart';
import 'features/coach/auth/coach_auth_screen.dart';
import 'features/coach/coach_shell.dart';
import 'features/coach/setup/coach_setup_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

import 'providers/coach/app_role_provider.dart';
import 'providers/coach/coach_auth_provider.dart';
import 'providers/coach/coach_circumference_controller.dart';
import 'providers/coach/coach_clients_controller.dart';
import 'providers/coach/coach_diagnostic_controller.dart';
import 'providers/coach/coach_goal_controller.dart';
import 'providers/coach/coach_inbody_controller.dart';
import 'providers/coach/coach_notes_controller.dart';
import 'providers/coach/coach_setup_provider.dart';
import 'providers/daily_history_provider.dart';
import 'providers/daily_intake_provider.dart';
import 'providers/subscription/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/training_session_provider.dart';
import 'providers/user_profile_provider.dart';

import 'core/nav/active_client_profile_sync.dart';
import 'services/coach/coach_cloud_sync_service.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRoleProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      key: ValueKey(role),
      title: 'Chytrý trenér',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      builder: (context, child) {
        return ActiveClientProfileSync(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AppBootstrap(role: role),
    );
  }
}

class AppBootstrap extends ConsumerStatefulWidget {
  final AppRole? role;

  const AppBootstrap({super.key, required this.role});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  bool _isBootstrapping = true;
  Object? _bootstrapError;
  bool _didStartBootstrap = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (_didStartBootstrap) return;
      _didStartBootstrap = true;
      _bootstrap();
    });
  }

  @override
  void didUpdateWidget(covariant AppBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.role != widget.role) {
      debugPrint(
        'APP BOOTSTRAP -> role changed ${oldWidget.role} -> ${widget.role}',
      );

      _didStartBootstrap = true;

      if (mounted) {
        setState(() {
          _isBootstrapping = true;
          _bootstrapError = null;
        });
      }

      Future.microtask(_bootstrap);
    }
  }

  Future<void> _bootstrap() async {
    try {
      debugPrint(
        'APP BOOTSTRAP -> start role=${widget.role} currentUser=${FirebaseAuth.instance.currentUser?.uid}',
      );

      _invalidateAppDataProviders();

      if (!mounted) return;
      setState(() {
        _isBootstrapping = false;
        _bootstrapError = null;
      });

      debugPrint('APP BOOTSTRAP -> done');
    } catch (e, st) {
      debugPrint('APP BOOTSTRAP ERROR -> $e');
      debugPrint('$st');

      _invalidateAppDataProviders();

      if (!mounted) return;
      setState(() {
        _isBootstrapping = false;
        _bootstrapError = e;
      });
    }
  }

  void _invalidateAppDataProviders() {
    ref.invalidate(coachClientsControllerProvider);
    ref.invalidate(coachNotesControllerProvider);
    ref.invalidate(coachInbodyControllerProvider);
    ref.invalidate(coachCircumferenceControllerProvider);
    ref.invalidate(coachDiagnosticControllerProvider);
    ref.invalidate(coachGoalControllerProvider);
    ref.invalidate(trainingSessionProvider);
    ref.invalidate(dailyHistoryProvider);
    ref.invalidate(dailyIntakeProvider);
    ref.invalidate(coachSetupProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bootstrapError != null) {
      return Scaffold(
        body: Center(
          child: Text('Chyba při startu aplikace: $_bootstrapError'),
        ),
      );
    }

    return RoleGate(role: widget.role);
  }
}

class RoleGate extends ConsumerWidget {
  final AppRole? role;

  const RoleGate({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final profile = ref.watch(userProfileProvider);
    final coachAuthAsync = ref.watch(coachAuthStateProvider);

    if (role == null) {
      return const RoleSelectScreen();
    }

    return subscriptionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Chyba předplatného: $e')),
      ),
      data: (sub) {
        if (!sub.isActive) {
          return PaywallScreen(
            target: role == AppRole.coach
                ? PaywallTarget.coach
                : PaywallTarget.client,
          );
        }

        if (role == AppRole.user && !sub.clientUnlocked) {
          return const PaywallScreen(target: PaywallTarget.client);
        }

        if (role == AppRole.coach && !sub.coachUnlocked) {
          return const PaywallScreen(target: PaywallTarget.coach);
        }

        switch (role!) {
          case AppRole.user:
            if (profile != null && profile.goal != null) {
              return const DashboardScreen();
            }
            return const OnboardingProfileScreen();

          case AppRole.coach:
            return coachAuthAsync.when(
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Scaffold(
                body: Center(child: Text('Chyba přihlášení trenéra: $e')),
              ),
              data: (user) {
                debugPrint('ROLE GATE -> coach auth user=${user?.uid}');

                if (user == null) {
                  return const CoachAuthScreen();
                }

                return _CoachSessionBootstrap(user: user);
              },
            );
        }
      },
    );
  }
}

class _CoachSessionBootstrap extends ConsumerStatefulWidget {
  final User user;

  const _CoachSessionBootstrap({required this.user});

  @override
  ConsumerState<_CoachSessionBootstrap> createState() =>
      _CoachSessionBootstrapState();
}

class _CoachSessionBootstrapState
    extends ConsumerState<_CoachSessionBootstrap> {
  bool _isSyncing = true;
  Object? _syncError;
  String? _lastSyncedUid;

  @override
  void initState() {
    super.initState();
    Future.microtask(_syncIfNeeded);
  }

  @override
  void didUpdateWidget(covariant _CoachSessionBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      Future.microtask(_syncIfNeeded);
    }
  }

  Future<void> _syncIfNeeded() async {
    final uid = widget.user.uid;

    if (_lastSyncedUid == uid && mounted) {
      setState(() {
        _isSyncing = false;
        _syncError = null;
      });
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isSyncing = true;
          _syncError = null;
        });
      }

      debugPrint('COACH SESSION SYNC -> start uid=$uid');

      final report = await CoachCloudSyncService.safePullMergeToLocal();

      debugPrint(
        'COACH SESSION SYNC -> success=${report.success} processed=${report.processedKeys} warnings=${report.warnings}',
      );

      ref.invalidate(coachClientsControllerProvider);
      ref.invalidate(coachNotesControllerProvider);
      ref.invalidate(coachInbodyControllerProvider);
      ref.invalidate(coachCircumferenceControllerProvider);
      ref.invalidate(coachDiagnosticControllerProvider);
      ref.invalidate(coachGoalControllerProvider);
      ref.invalidate(trainingSessionProvider);
      ref.invalidate(dailyHistoryProvider);
      ref.invalidate(dailyIntakeProvider);
      ref.invalidate(coachSetupProvider);

      if (!mounted) return;
      setState(() {
        _lastSyncedUid = uid;
        _isSyncing = false;
        _syncError = null;
      });
    } catch (e, st) {
      debugPrint('COACH SESSION SYNC ERROR -> uid=$uid error=$e');
      debugPrint('$st');

      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _syncError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSyncing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_syncError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chyba synchronizace coach dat:\n$_syncError',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _syncIfNeeded,
                  child: const Text('Zkusit znovu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final coachSetupAsync = ref.watch(coachSetupProvider);

    return coachSetupAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Chyba coach setupu: $e')),
      ),
      data: (setup) {
        if (setup == null || !setup.isComplete) {
          return const CoachSetupScreen();
        }
        return const CoachShell();
      },
    );
  }
}