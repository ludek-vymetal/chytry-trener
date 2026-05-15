import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

import '../../providers/coach/active_client_data_providers.dart';
import '../../providers/coach/app_role_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_profile_provider.dart';

import '../../services/local_storage_service.dart';
import '../../services/macro_service.dart';
import '../../services/metabolism_service.dart';

import '../body/add_circumference_screen.dart';
import '../body/add_measurement_screen.dart';
import '../body/circumference_list_screen.dart';

import '../coach/clients/add_circumference_entry_screen.dart';
import '../coach/clients/coach_circumference_history_screen.dart';

import '../debug/phase_test_screen.dart';

import '../diet_plans/diet_strategy_screen.dart';

import '../food/food_summary_screen.dart';

import '../onboarding/onboarding_goal_screen.dart';

import '../performance/performance_list_screen.dart';

import '../role/role_select_screen.dart';

import '../training/training_overview_screen.dart';

import 'macros_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends ConsumerState<DashboardScreen> {
  String? _exportFolderPath;

  bool _loadingExportFolder = true;

  bool _changingExportFolder = false;

  @override
  void initState() {
    super.initState();
    _loadExportFolderPath();
  }

  Future<void> _loadExportFolderPath() async {
    final path =
        await LocalStorageService.loadClientExportFolderPath();

    if (!mounted) return;

    setState(() {
      _exportFolderPath = path;
      _loadingExportFolder = false;
    });
  }

  Future<void> _pickExportFolder() async {
    if (_changingExportFolder) return;

    final messenger = ScaffoldMessenger.of(context);

    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _changingExportFolder = true;
    });

    try {
      final selectedPath = await getDirectoryPath(
        confirmButtonText: 'Vybrat složku',
      );

      if (selectedPath == null ||
          selectedPath.trim().isEmpty) {
        return;
      }

      final dir = Directory(selectedPath);

      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      await LocalStorageService
          .saveClientExportFolderPath(selectedPath);

      if (!mounted) return;

      setState(() {
        _exportFolderPath = selectedPath;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.exportFolderSaved),
          backgroundColor: colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.folderPickFailed(e.toString()),
          ),
          backgroundColor: colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingExportFolder = false;
        });
      }
    }
  }

  Future<void> _clearExportFolder() async {
    final messenger = ScaffoldMessenger.of(context);

    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    await LocalStorageService.clearClientExportFolderPath();

    if (!mounted) return;

    setState(() {
      _exportFolderPath = null;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.customExportFolderRemoved,
        ),
        backgroundColor: colorScheme.tertiary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;

    final profile = ref.watch(userProfileProvider);

    final activeCoachClientAsync =
        ref.watch(activeCoachClientProvider);

    final activeCoachClient =
        activeCoachClientAsync.asData?.value;

    final themeMode = ref.watch(themeProvider);

    if (profile == null || profile.goal == null) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.profileNotFound,
          ),
        ),
      );
    }

    final tdee = MetabolismService.calculateTDEE(
      profile,
      ActivityLevel.moderate,
    );

    final macro =
        MacroService.calculate(profile, tdee);

    final currentKg = profile.weight;

    final targetKg =
        profile.goal?.targetWeightKg;

    void forceRestart() {
      ref
          .read(appRoleProvider.notifier)
          .setRole(null);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const RoleSelectScreen(),
        ),
        (route) => false,
      );
    }

    void openCircumferenceHistory() {
      if (activeCoachClient != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CoachCircumferenceHistoryScreen(
              client: activeCoachClient,
            ),
          ),
        );

        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const CircumferenceListScreen(),
        ),
      );
    }

    void openAddCircumference() {
      if (activeCoachClient != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddCircumferenceEntryScreen(
              clientId:
                  activeCoachClient.clientId,
            ),
          ),
        );

        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AddCircumferenceScreen(),
        ),
      );
    }

    Future<void> openChangeGoal() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            l10n.changeGoal,
          ),
          content: Text(
            l10n.changeGoalDescription,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                l10n.no,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                l10n.yes,
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (confirmed == true) {
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const OnboardingGoalScreen(),
          ),
        );
      }
    }  

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.dashboard,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: forceRestart,
        ),
        actions: [
          PopupMenuButton<Locale?>(
            icon: const Icon(Icons.language),
            onSelected: (locale) {
              ref
                  .read(localeProvider.notifier)
                  .state = locale;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text(
                  l10n.automatic,
                ),
              ),
              PopupMenuItem(
                value: const Locale('cs'),
                child: Text(
                  l10n.czech,
                ),
              ),
              PopupMenuItem(
                value: const Locale('en'),
                child: Text(
                  l10n.english,
                ),
              ),
            ],
          ),

          IconButton(
            tooltip: themeMode == ThemeMode.dark
                ? l10n.switchToLightMode
                : l10n.switchToDarkMode,
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              ref
                  .read(themeProvider.notifier)
                  .toggleLightDark();
            },
          ),

          TextButton.icon(
            onPressed: forceRestart,
            icon: Icon(
              Icons.swap_horiz,
              color: colorScheme.primary,
            ),
            label: Text(
              l10n.changeMode,
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            _MetricCard(
              title: 'TDEE',
              value:
                  '${tdee.toStringAsFixed(0)} kcal',
              subtitle:
                  'Denní energetický výdej',
            ),

            const SizedBox(height: 12),

            _MetricCard(
              title: 'CÍLOVÉ KALORIE',
              value:
                  '${macro.targetCalories} kcal',
              subtitle:
                  '${macro.strategyLabel} • ${macro.phaseLabel} • ${macro.planModeLabel}',
            ),

            const SizedBox(height: 12),

            _MetricCard(
              title: 'Makra',
              value:
                  'B ${macro.protein} g | S ${macro.carbs} g | T ${macro.fat} g',
              subtitle:
                  'Týdnů do cíle: ${macro.weeksToTarget}',
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(12),
                child: Text(
                  macro.rationale,
                  style: TextStyle(
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _MacroDebugCard(
              currentKg: currentKg,
              targetKg: targetKg,
              weightForCaloriesKg:
                  macro.weightForCaloriesKg,
              weightForProteinKg:
                  macro.weightForProteinKg,
              macro: macro,
            ),

            const SizedBox(height: 12),

            _ExportFolderCard(
              currentPath: _exportFolderPath,
              isLoading:
                  _loadingExportFolder,
              isBusy:
                  _changingExportFolder,
              onPickFolder:
                  _pickExportFolder,
              onClearFolder:
                  _clearExportFolder,
            ),

            const SizedBox(height: 24),

            _fullWidthButton(
              label: l10n.addMeasurement,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddMeasurementScreen(),
                  ),
                );
              },
            ),

            _fullWidthButton(
              label:
                  l10n.bodyCircumference,
              onPressed:
                  openCircumferenceHistory,
            ),

            _fullWidthButton(
              label:
                  l10n.addCircumference,
              onPressed:
                  openAddCircumference,
            ),

            _fullWidthButton(
              label: l10n.performance,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PerformanceListScreen(),
                  ),
                );
              },
            ),

            _fullWidthButton(
              label: l10n.dailyMacros,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MacrosScreen(),
                  ),
                );
              },
            ),

            _fullWidthButton(
              label: l10n.todayFood,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const FoodSummaryScreen(),
                  ),
                );
              },
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const DietStrategyScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.fact_check,
                ),
                label: Text(
                  l10n.dietPlanStyle,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      colorScheme
                          .tertiaryContainer,
                  foregroundColor:
                      colorScheme
                          .onTertiaryContainer,
                ),
              ),
            ),

            const SizedBox(height: 12),

            _fullWidthButton(
              label: l10n.changeGoal,
              onPressed: openChangeGoal,
            ),

            _fullWidthButton(
              label:
                  l10n.trainingMode,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TrainingOverviewScreen(),
                  ),
                );
              },
            ),

            _fullWidthButton(
              label:
                  l10n.phaseLogicTest,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PhaseTestScreen(),
                  ),
                );
              },
              backgroundColor:
                  colorScheme
                      .secondaryContainer,
              foregroundColor:
                  colorScheme
                      .onSecondaryContainer,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _fullWidthButton({
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),

      child: SizedBox(
        width: double.infinity,
        height: 45,

        child: ElevatedButton(
          style: (backgroundColor != null ||
                  foregroundColor != null)
              ? ElevatedButton.styleFrom(
                  backgroundColor:
                      backgroundColor,
                  foregroundColor:
                      foregroundColor,
                )
              : null,

          onPressed: onPressed,

          child: Text(label),
        ),
      ),
    );
  }
}

class _ExportFolderCard extends StatelessWidget {
  final String? currentPath;

  final bool isLoading;

  final bool isBusy;

  final VoidCallback onPickFolder;

  final VoidCallback onClearFolder;

  const _ExportFolderCard({
    required this.currentPath,
    required this.isLoading,
    required this.isBusy,
    required this.onPickFolder,
    required this.onClearFolder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final hasCustomPath =
        currentPath != null &&
            currentPath!.trim().isNotEmpty;

    return Card(
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color:
              colorScheme.outlineVariant,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_copy_outlined,
                  color:
                      colorScheme.primary,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Archivace klientů',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                      color: colorScheme
                          .onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.45),

                borderRadius:
                    BorderRadius.circular(
                        14),

                border: Border.all(
                  color: colorScheme
                      .outlineVariant,
                ),
              ),

              child: SelectableText(
                isLoading
                    ? 'Načítám nastavení exportní složky...'
                    : hasCustomPath
                        ? 'Aktuální exportní složka:\n\n$currentPath'
                        : 'Není vybraná vlastní exportní složka.\n\nPoužije se výchozí Documents/Klienti.',

                style: TextStyle(
                  color: colorScheme
                      .onSurfaceVariant,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,

              child: FilledButton.icon(
                onPressed:
                    isBusy
                        ? null
                        : onPickFolder,

                icon: isBusy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme
                              .onPrimary,
                        ),
                      )
                    : const Icon(
                        Icons.folder_open,
                      ),

                label: const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  child: Text(
                    'Vybrat exportní složku',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              ),
            ),

            if (hasCustomPath) ...[
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,

                child:
                    OutlinedButton.icon(
                  onPressed:
                      isBusy
                          ? null
                          : onClearFolder,

                  icon: const Icon(
                    Icons.close,
                  ),

                  label: const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Text(
                      'Zrušit vlastní cestu',
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;

  final String value;

  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),

        side: BorderSide(
          color:
              colorScheme.outlineVariant,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              title,

              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
                color:
                    colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              value,

              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.w800,
                color:
                    colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,

              style: TextStyle(
                color: colorScheme
                    .onSurfaceVariant,
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroDebugCard extends StatelessWidget {
  final double currentKg;

  final double? targetKg;

  final double weightForCaloriesKg;

  final double weightForProteinKg;

  final MacroTarget macro;

  const _MacroDebugCard({
    required this.currentKg,
    required this.targetKg,
    required this.weightForCaloriesKg,
    required this.weightForProteinKg,
    required this.macro,
  });

  String kg(double value) {
    return '${value.toStringAsFixed(1)} kg';
  }

  Widget rowItem(
    BuildContext context,
    String left,
    String right,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Expanded(
            flex: 2,

            child: Text(
              left,

              style: TextStyle(
                color: colorScheme
                    .onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            flex: 3,

            child: Text(
              right,

              textAlign: TextAlign.right,

              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
                fontSize: 14,
                color:
                    colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),

        side: BorderSide(
          color:
              colorScheme.outlineVariant,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color:
                      colorScheme.primary,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Debug – z jaké váhy se počítá',

                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme
                          .onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            rowItem(
              context,
              'Aktuální váha',
              kg(currentKg),
            ),

            rowItem(
              context,
              'Cílová váha',
              targetKg == null
                  ? 'nenastaveno'
                  : kg(targetKg!),
            ),

            Divider(
              height: 24,
              color:
                  colorScheme.outlineVariant,
            ),

            rowItem(
              context,
              'Váha pro kalorie',
              kg(weightForCaloriesKg),
            ),

            rowItem(
              context,
              'Váha pro protein',
              kg(weightForProteinKg),
            ),

            Divider(
              height: 24,
              color:
                  colorScheme.outlineVariant,
            ),

            rowItem(
              context,
              'Fáze',
              macro.phaseLabel,
            ),

            rowItem(
              context,
              'Režim',
              macro.planModeLabel,
            ),

            rowItem(
              context,
              'Týdny do cíle',
              '${macro.weeksToTarget}',
            ),

            rowItem(
              context,
              'Strategie',
              macro.strategyLabel,
            ),
          ],
        ),
      ),
    );
  }
}