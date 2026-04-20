import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/nav/active_client_profile_sync.dart';
import 'features/coach/auth/coach_auth_screen.dart';
import 'features/coach/coach_shell.dart';
import 'features/coach/setup/coach_setup_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_profile_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/role/role_select_screen.dart';
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
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      builder: (context, child) {
        return ActiveClientProfileSync(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AppBootstrap(role: role),
    );
  }
}

class AppTheme {
  static ThemeData build(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.deepOrange,
      brightness: brightness,
    );

    final colorScheme = base.colorScheme;
    final isDark = brightness == Brightness.dark;

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor:
              colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor:
              colorScheme.onSurface.withValues(alpha: 0.38),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor:
              colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor:
              colorScheme.onSurface.withValues(alpha: 0.38),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.45 : 0.65,
          ),
        ),
        dividerThickness: 1,
        dataTextStyle: TextStyle(color: colorScheme.onSurface),
        headingTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );
  }
}

class AppBootstrap extends ConsumerStatefulWidget {
  final AppRole? role;

  const AppBootstrap({
    super.key,
    required this.role,
  });

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  bool _isBootstrapping = true;
  Object? _bootstrapError;
  bool _hasBootstrapped = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_runBootstrap);
  }

  @override
  void didUpdateWidget(covariant AppBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.role != widget.role) {
      Future.microtask(_runBootstrap);
    }
  }

  Future<void> _runBootstrap() async {
    if (_hasBootstrapped && mounted && !_roleChangedRequiresReset()) {
      return;
    }

    if (mounted) {
      setState(() {
        _isBootstrapping = true;
        _bootstrapError = null;
      });
    }

    try {
      debugPrint(
        'APP BOOTSTRAP -> start role=${widget.role} currentUser=${FirebaseAuth.instance.currentUser?.uid}',
      );

      AppProviderInvalidation.invalidateAll(ref);

      _hasBootstrapped = true;

      if (!mounted) return;
      setState(() {
        _isBootstrapping = false;
        _bootstrapError = null;
      });

      debugPrint('APP BOOTSTRAP -> done');
    } catch (e, st) {
      debugPrint('APP BOOTSTRAP ERROR -> $e');
      debugPrint('$st');

      AppProviderInvalidation.invalidateAll(ref);

      if (!mounted) return;
      setState(() {
        _isBootstrapping = false;
        _bootstrapError = e;
      });
    }
  }

  bool _roleChangedRequiresReset() {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const _FullscreenLoader();
    }

    if (_bootstrapError != null) {
      return _FullscreenError(
        message: 'Chyba při startu aplikace: $_bootstrapError',
      );
    }

    return RoleGate(role: widget.role);
  }
}

class RoleGate extends ConsumerWidget {
  final AppRole? role;

  const RoleGate({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (role == null) {
      return const RoleSelectScreen();
    }

    final subscriptionAsync = ref.watch(subscriptionProvider);
    final profile = ref.watch(userProfileProvider);
    final coachAuthAsync = ref.watch(coachAuthStateProvider);

    return subscriptionAsync.when(
      loading: () => const _FullscreenLoader(),
      error: (e, _) => _FullscreenError(
        message: 'Chyba předplatného: $e',
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

        if (role == AppRole.user) {
          if (profile != null && profile.goal != null) {
            return const DashboardScreen();
          }
          return const OnboardingProfileScreen();
        }

        return coachAuthAsync.when(
          loading: () => const _FullscreenLoader(),
          error: (e, _) => _FullscreenError(
            message: 'Chyba přihlášení trenéra: $e',
          ),
          data: (user) {
            debugPrint('ROLE GATE -> coach auth user=${user?.uid}');

            if (user == null) {
              return const CoachAuthScreen();
            }

            return CoachSessionBootstrap(user: user);
          },
        );
      },
    );
  }
}

class CoachSessionBootstrap extends ConsumerStatefulWidget {
  final User user;

  const CoachSessionBootstrap({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<CoachSessionBootstrap> createState() =>
      _CoachSessionBootstrapState();
}

class _CoachSessionBootstrapState
    extends ConsumerState<CoachSessionBootstrap> {
  bool _isSyncing = true;
  Object? _syncError;
  String? _lastSyncedUid;

  @override
  void initState() {
    super.initState();
    Future.microtask(_syncIfNeeded);
  }

  @override
  void didUpdateWidget(covariant CoachSessionBootstrap oldWidget) {
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

      final report = await CoachCloudSyncService.safeReconcileLocalAndCloud();

      debugPrint(
        'COACH SESSION SYNC -> success=${report.success} processed=${report.processedKeys} warnings=${report.warnings}',
      );

      AppProviderInvalidation.invalidateAll(ref);

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
      return const _FullscreenLoader();
    }

    if (_syncError != null) {
      return _RetryableErrorCard(
        message: 'Chyba synchronizace coach dat:\n$_syncError',
        onRetry: _syncIfNeeded,
        icon: Icons.sync_problem,
      );
    }

    final coachSetupAsync = ref.watch(coachSetupProvider);

    return coachSetupAsync.when(
      loading: () => const _FullscreenLoader(),
      error: (e, _) => _FullscreenError(
        message: 'Chyba coach setupu: $e',
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

class AppProviderInvalidation {
  static void invalidateAll(WidgetRef ref) {
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
}

class _FullscreenLoader extends StatelessWidget {
  const _FullscreenLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _FullscreenError extends StatelessWidget {
  final String message;

  const _FullscreenError({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _RetryableErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const _RetryableErrorCard({
    required this.message,
    required this.onRetry,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 36,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Zkusit znovu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}