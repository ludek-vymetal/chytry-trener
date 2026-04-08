import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/coach/active_client_data_providers.dart';
import '../../providers/coach/app_role_provider.dart';
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
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _exportFolderPath;
  bool _loadingExportFolder = true;
  bool _changingExportFolder = false;

  @override
  void initState() {
    super.initState();
    _loadExportFolderPath();
  }

  Future<void> _loadExportFolderPath() async {
    final path = await LocalStorageService.loadClientExportFolderPath();
    if (!mounted) return;

    setState(() {
      _exportFolderPath = path;
      _loadingExportFolder = false;
    });
  }

  Future<void> _pickExportFolder() async {
    if (_changingExportFolder) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _changingExportFolder = true;
    });

    try {
      final selectedPath = await getDirectoryPath(
        confirmButtonText: 'Vybrat složku',
      );

      if (selectedPath == null || selectedPath.trim().isEmpty) {
        return;
      }

      final dir = Directory(selectedPath);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      await LocalStorageService.saveClientExportFolderPath(selectedPath);

      if (!mounted) return;
      setState(() {
        _exportFolderPath = selectedPath;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Exportní složka byla uložena.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Nepodařilo se vybrat složku: $e'),
          backgroundColor: Colors.red,
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

    await LocalStorageService.clearClientExportFolderPath();

    if (!mounted) return;
    setState(() {
      _exportFolderPath = null;
    });

    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Vlastní exportní složka byla smazána. Použije se výchozí Documents/Klienti.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final activeCoachClientAsync = ref.watch(activeCoachClientProvider);
    final activeCoachClient = activeCoachClientAsync.asData?.value;
    final themeMode = ref.watch(themeProvider);

    if (profile == null || profile.goal == null) {
      return const Scaffold(
        body: Center(child: Text('Profil nenalezen')),
      );
    }

    final tdee = MetabolismService.calculateTDEE(
      profile,
      ActivityLevel.moderate,
    );

    final macro = MacroService.calculate(profile, tdee);

    final currentKg = profile.weight;
    final targetKg = profile.goal?.targetWeightKg;

    void forceRestart(WidgetRef ref, BuildContext context) {
      ref.read(appRoleProvider.notifier).setRole(null);

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
            builder: (_) => CoachCircumferenceHistoryScreen(
              client: activeCoachClient,
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CircumferenceListScreen(),
        ),
      );
    }

    void openAddCircumference() {
      if (activeCoachClient != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddCircumferenceEntryScreen(
              clientId: activeCoachClient.clientId,
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddCircumferenceScreen(),
        ),
      );
    }

    Future<void> openChangeGoal() async {
      final navigator = Navigator.of(context);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Změnit cíl'),
          content: const Text(
            'Opravdu chceš změnit cíl? '
            'Při změně cíle se může upravit strategie, fáze a doporučení.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ne'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ano'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (confirmed == true) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const OnboardingGoalScreen(),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => forceRestart(ref, context),
        ),
        actions: [
          IconButton(
            tooltip: themeMode == ThemeMode.dark
                ? 'Přepnout na světlý režim'
                : 'Přepnout na tmavý režim',
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleLightDark();
            },
          ),
          TextButton.icon(
            onPressed: () => forceRestart(ref, context),
            icon: const Icon(Icons.swap_horiz, color: Colors.brown),
            label: const Text(
              'Změnit režim',
              style: TextStyle(color: Colors.brown),
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
              value: '${tdee.toStringAsFixed(0)} kcal',
              subtitle: 'Denní energetický výdej',
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'CÍLOVÉ KALORIE',
              value: '${macro.targetCalories} kcal',
              subtitle:
                  '${macro.strategyLabel} • ${macro.phaseLabel} • ${macro.planModeLabel}',
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Makra',
              value:
                  'B ${macro.protein} g | S ${macro.carbs} g | T ${macro.fat} g',
              subtitle: 'Týdnů do cíle: ${macro.weeksToTarget}',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  macro.rationale,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _MacroDebugCard(
              currentKg: currentKg,
              targetKg: targetKg,
              weightForCaloriesKg: macro.weightForCaloriesKg,
              weightForProteinKg: macro.weightForProteinKg,
              macro: macro,
            ),
            const SizedBox(height: 12),
            _ExportFolderCard(
              currentPath: _exportFolderPath,
              isLoading: _loadingExportFolder,
              isBusy: _changingExportFolder,
              onPickFolder: _pickExportFolder,
              onClearFolder: _clearExportFolder,
            ),
            const SizedBox(height: 24),
            _fullWidthButton(
              context,
              'Přidat měření',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddMeasurementScreen(),
                ),
              ),
            ),
            _fullWidthButton(
              context,
              'Obvody těla',
              openCircumferenceHistory,
            ),
            _fullWidthButton(
              context,
              'Přidat obvody',
              openAddCircumference,
            ),
            _fullWidthButton(
              context,
              'Výkonnost / PR',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerformanceListScreen(),
                ),
              ),
            ),
            _fullWidthButton(
              context,
              'Denní makra',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MacrosScreen(),
                ),
              ),
            ),
            _fullWidthButton(
              context,
              'Dnešní jídlo',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FoodSummaryScreen(),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DietStrategyScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.fact_check),
                label: const Text(
                  'STYL JÍDELNÍHO PLÁNU',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _fullWidthButton(
              context,
              'Změnit cíl',
              openChangeGoal,
            ),
            _fullWidthButton(
              context,
              'Tréninkový režim',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrainingOverviewScreen(),
                ),
              ),
            ),
            _fullWidthButton(
              context,
              'TEST LOGIKY FÁZÍ',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PhaseTestScreen(),
                ),
              ),
              color: Colors.orange,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _fullWidthButton(
    BuildContext context,
    String label,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton(
          style: color != null
              ? ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
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
    final hasCustomPath = currentPath != null && currentPath!.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Archivace klientů',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isLoading
                  ? 'Načítám nastavení exportní složky...'
                  : hasCustomPath
                      ? 'Aktuální exportní složka:\n$currentPath'
                      : 'Není vybraná vlastní exportní složka.\nPoužije se výchozí Documents/Klienti.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : onPickFolder,
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open),
                    label: const Text('Vybrat exportní složku'),
                  ),
                ),
                if (hasCustomPath) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: isBusy ? null : onClearFolder,
                    child: const Text('Zrušit vlastní cestu'),
                  ),
                ],
              ],
            ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
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

  String _kg(double v) => '${v.toStringAsFixed(1)} kg';

  Widget _row(String left, String right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(left)),
          Text(
            right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug – z jaké váhy se počítá',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _row('Aktuální váha', _kg(currentKg)),
            _row(
              'Cílová váha',
              targetKg == null ? 'nenastaveno' : _kg(targetKg!),
            ),
            const Divider(height: 18),
            _row('Váha pro kalorie', _kg(weightForCaloriesKg)),
            _row('Váha pro protein', _kg(weightForProteinKg)),
            const Divider(height: 18),
            _row('Fáze', macro.phaseLabel),
            _row('Režim', macro.planModeLabel),
            _row('Týdny do cíle', '${macro.weeksToTarget}'),
            _row('Strategie', macro.strategyLabel),
          ],
        ),
      ),
    );
  }
}