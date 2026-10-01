import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_application_1/l10n/app_localizations.dart';

// Modely
import '../../../models/coach/coach_client.dart';
import '../../../models/coach/coach_circumference_entry.dart';
import '../../../core/body/inbody_analysis.dart';
import '../../../models/coach/coach_inbody_entry.dart';
import '../../../models/custom_training_plan.dart';
import '../../../models/exercise_performance.dart';
import '../../../core/training/sessions/training_session.dart';

// Providery (Trenérské)
import '../../../providers/training_session_provider.dart';
import '../../../providers/coach/coach_notes_provider.dart';
import '../../../providers/coach/coach_notes_controller.dart';
import '../../../providers/coach/coach_client_details_controller.dart';
import '../../../providers/coach/coach_circumference_controller.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
import '../../../providers/coach/custom_training_plan_provider.dart';
import '../../../providers/coach/active_client_provider.dart';
import '../../../providers/performance_provider.dart';
import '../../../providers/coach/coach_clients_controller.dart';

// Provider role
import '../../../providers/coach/app_role_provider.dart';

// Providery (Uživatelské)
import '../../../providers/user_profile_provider.dart';

// Služby
import '../../../services/coach/client_export_service.dart';
import '../../../services/coach/client_import_service.dart';
import '../../../services/local_storage_service.dart';

// Obrazovky
import '../../diet_plans/diet_strategy_screen.dart';
import '../../food/food_summary_screen.dart';
import '../../onboarding/onboarding_goal_screen.dart';
import '../../training/custom_training_plan_screen.dart';
import '../../training/training_overview_screen.dart';
import 'edit_client_details_screen.dart';
import 'add_circumference_entry_screen.dart';
import 'add_inbody_entry_screen.dart';
import 'inbody_report_screen.dart';
import 'client_monthly_report_screen.dart';
import '../widgets/client_pulse.dart';
import '../../coaching/coaching_widgets.dart';
import '../../diet_plans/widgets/food_exclusions_card.dart';
import '../../diet_plans/widgets/client_meal_plans_card.dart';
import '../../../core/body/coach_recommendations.dart';
import '../../../services/pdf/client_report_data.dart';
import '../../../services/pdf/client_report_pdf_service.dart';
import '../../coaching/workout_widgets.dart';
import '../../coaching/chat_screen.dart';
import '../../coaching/checkin_widgets.dart';
import '../passes/passes_widgets.dart';
import '../../health/activity_screen.dart';

class ClientDetailScreen extends ConsumerWidget {
  final CoachClient client;

  /// `true` = zobrazeno vedle seznamu klientů (počítač) – bez šipky zpět.
  final bool embedded;

  const ClientDetailScreen({
    super.key,
    required this.client,
    this.embedded = false,
  });

  bool _isValidEmail(String email) {
    if (email.trim().isEmpty) return true;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email.trim());
  }

  static Future<void> _openDirectoryPath(String path) async {
    if (path.trim().isEmpty) return;

    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
      return;
    }

    if (Platform.isMacOS) {
      await Process.run('open', [path]);
      return;
    }

    if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
      return;
    }

    throw UnsupportedError('Otevření složky není na této platformě podporováno.');
  }

  static Future<void> _openFilePath(String path) async {
    if (path.trim().isEmpty) return;

    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', path]);
      return;
    }

    if (Platform.isMacOS) {
      await Process.run('open', [path]);
      return;
    }

    if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
      return;
    }

    throw UnsupportedError('Otevření souboru není na této platformě podporováno.');
  }

  static Future<void> _showExportSuccessDialog(
    BuildContext context, {
    required ClientArchiveExportResult result,
  }) async {
    Widget fileRow(String label, String fileName) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(fileName),
            ),
          ],
        ),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: Text(l10n.archiveCompleted),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clientArchiveSuccessfullyCreated,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.destinationFolder,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(result.clientDirectory.path),
                  const SizedBox(height: 14),
                  Text(
                    l10n.createdFiles,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  fileRow(
                    l10n.currentJson,
                    result.currentJsonFile.path.split(Platform.pathSeparator).last,
                  ),
                  fileRow(
                    l10n.snapshot,
                    result.historyJsonFile.path.split(Platform.pathSeparator).last,
                  ),
                  fileRow(
                    l10n.pdfReport,
                    result.reportPdfFile.path.split(Platform.pathSeparator).last,
                  ),
                  fileRow(
                    l10n.manifest,
                    result.manifestFile.path.split(Platform.pathSeparator).last,
                  ),
                  fileRow(
                    l10n.inbodyCsv,
                    result.inbodyCsvFile.path.split(Platform.pathSeparator).last,
                  ),
                  fileRow(
                    l10n.circumferenceCsv,
                    result.circumferencesCsvFile.path
                        .split(Platform.pathSeparator)
                        .last,
                  ),
                  fileRow(
                    l10n.performancesCsv,
                    result.performancesCsvFile.path
                        .split(Platform.pathSeparator)
                        .last,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${l10n.reportPeriod}: ${_fmtDate(result.reportFrom)} - ${_fmtDate(result.reportTo)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
            TextButton.icon(
              onPressed: () async {
                try {
                  await _openFilePath(result.reportPdfFile.path);
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('PDF se nepodařilo otevřít: $e'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(l10n.openPdf),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _openDirectoryPath(result.clientDirectory.path);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('${l10n.failedToOpenFolder}: $e'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.folder_open),
              label: Text(l10n.openFolder),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showImportSourceDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<void>(
      context: context,
     builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;

        return AlertDialog(
          title: Text(l10n.importRestoreClient),
          content: Text(
            l10n.chooseHowToRestoreOrImportClient,
          ),
          actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _importClientDialog(context, ref);
            },
            icon: const Icon(Icons.code),
            label: Text(l10n.insertJsonManually),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _importClientFromJsonFile(context, ref);
            },
            icon: const Icon(Icons.description),
            label: Text(l10n.selectJsonFile),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _restoreClientFromArchiveFolder(context, ref);
            },
            icon: const Icon(Icons.restore),
            label: Text(l10n.restoreFromArchiveFolder),
          ),
        ],
      );
    },
    );
  }

  static Future<void> _importClientFromJsonFile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final l10n = AppLocalizations.of(context)!;

      const typeGroup = XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
      );

      final file = await openFile(
        acceptedTypeGroups: const [typeGroup],
        confirmButtonText: l10n.selectJson,
      );

      if (file == null) return;

      await const ClientImportService().importClientFromJsonFile(file.path, ref);

      if (context.mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.clientImportedFromFile}\n${file.path}',
            ),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;

        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.fileImportFailed}: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  static Future<void> _restoreClientFromArchiveFolder(
    BuildContext context,
    WidgetRef ref,
  ) async {

    final l10n = AppLocalizations.of(context)!;

    try {
      
      final folderPath = await getDirectoryPath(
        confirmButtonText: l10n.selectArchiveFolder,
      );

      if (folderPath == null || folderPath.trim().isEmpty) return;

      await const ClientImportService().importClientFromArchiveFolder(
        folderPath,
        ref,
      );

      if (context.mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.clientRestoredFromArchive}\n$folderPath',
            ),
            backgroundColor: colorScheme.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;

        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.archiveRestoreFailed}: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openConfiguredExportFolder(BuildContext context) async {

    final l10n = AppLocalizations.of(context)!;

    try {
      
      final savedPath = await LocalStorageService.loadClientExportFolderPath();

      if (savedPath == null || savedPath.trim().isEmpty) {
        if (context.mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:Text(
                l10n.exportFolderNotConfigured,
              ),
              backgroundColor: colorScheme.tertiary,
            ),
          );
        }
        return;
      }

      final dir = Directory(savedPath);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      await _openDirectoryPath(dir.path);
    } catch (e) {
      if (context.mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.folderOpenFailed}: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteClientFlow(
    
    BuildContext context,
    WidgetRef ref, {
     
    required CoachClient liveClient,
    required bool exportBeforeDelete,
    required dynamic details,
    required List<dynamic> notes,
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circumferences,
    required List<ExercisePerformance> performances,
    required List<CustomTrainingPlan> clientPlans,
    required List<TrainingSession> history,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          exportBeforeDelete
              ? l10n.archiveAndDeleteClient
              : l10n.deleteClient,
        ),
        content: Text(
          exportBeforeDelete
              ? l10n.archiveAndDeleteClientConfirm
              : l10n.deleteClientConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              exportBeforeDelete
                  ? l10n.archiveAndDelete
                  : l10n.delete,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (exportBeforeDelete) {
        await ClientExportService.archiveClientExport(
          client: liveClient,
          details: details,
          notes: notes,
          inbody: inbody,
          circumferences: circumferences,
          performances: performances,
          customPlans: clientPlans,
          sessions: history,
        );
      }

      final activeClientId = ref.read(activeClientIdProvider).valueOrNull;
      if (activeClientId == liveClient.clientId) {
        await ref.read(activeClientIdProvider.notifier).clear();
        await ref.read(userProfileProvider.notifier).switchToClient(null);
      }

      await ref
          .read(customTrainingPlanProvider.notifier)
          .deletePlansForClient(liveClient.clientId);

      await ref
          .read(userProfileProvider.notifier)
          .clearClientData(liveClient.clientId);

      await ref
          .read(coachClientsControllerProvider.notifier)
          .deleteClient(liveClient.clientId);

      ref.invalidate(coachNotesControllerProvider);
      ref.invalidate(coachClientDetailsControllerProvider);
      ref.invalidate(coachCircumferenceControllerProvider);
      ref.invalidate(coachInbodyControllerProvider);
      ref.invalidate(coachClientsControllerProvider);

      if (!context.mounted) return;

      Navigator.of(context).pop();

      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exportBeforeDelete
                ? l10n.clientArchivedAndDeleted
                : l10n.clientDeleted,
          ),
          backgroundColor:
              exportBeforeDelete ? colorScheme.primary : colorScheme.tertiary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.clientDeleteError}: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final notesAsync = ref.watch(coachNotesForClientProvider(client.clientId));
    final detailsAsync =
        ref.watch(coachClientDetailsForClientProvider(client.clientId));
    final circsAsync =
        ref.watch(coachCircumferencesForClientProvider(client.clientId));
    final inbodyAsync = ref.watch(coachInbodyForClientProvider(client.clientId));
    final performances = ref.watch(
      performancesForClientProvider(client.clientId),
    );

    final allClientsAsync = ref.watch(coachClientsControllerProvider);

    final liveStats = allClientsAsync.asData?.value
        .where((x) => x.client.clientId == client.clientId)
        .cast<CoachClientWithStats?>()
        .firstOrNull;

    final liveClient = liveStats?.client ?? client;
    final isSensitive = liveClient.isEatingDisorderSupport;

    // watch kvůli překreslení při změně; data bereme pro konkrétního klienta.
    ref.watch(trainingSessionProvider);
    final List<TrainingSession> history = ref
        .read(trainingSessionProvider.notifier)
        .sessionsForClient(liveClient.clientId);

    final customPlans = ref.watch(customTrainingPlanProvider);
    final clientPlans =
        customPlans.where((p) => p.clientId == liveClient.clientId).toList();

    final compliance7d = liveStats?.compliance7d ?? 0.0;
    final completedDaysInLast7 = liveStats?.completedDaysInLast7 ?? 0;
    final lastSession = liveStats?.lastSessionAt;

    final workoutDoneToday = _containsToday(liveClient.completedDays);

    final inbodyItems = inbodyAsync.valueOrNull ?? const <CoachInbodyEntry>[];
    final pulse = liveStats == null
        ? null
        : ClientPulse.of(liveStats, inbodyItems.firstOrNull);

    final planSection = _section(context, l10n.clientPlanTitle, [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _openForClient(
                    context,
                    ref,
                    liveClient,
                    const OnboardingGoalScreen(),
                  ),
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(l10n.clientGoalButton),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openForClient(
                    context,
                    ref,
                    liveClient,
                    const DietStrategyScreen(),
                  ),
                  icon: const Icon(Icons.restaurant_menu),
                  label: Text(l10n.clientDietButton),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openForClient(
                    context,
                    ref,
                    liveClient,
                    const TrainingOverviewScreen(),
                  ),
                  icon: const Icon(Icons.fitness_center),
                  label: Text(l10n.clientTrainingButton),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openForClient(
                    context,
                    ref,
                    liveClient,
                    const CustomTrainingPlanScreen(),
                  ),
                  icon: const Icon(Icons.list_alt),
                  label: Text(l10n.clientProgramsButton),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openForClient(
                    context,
                    ref,
                    liveClient,
                    const FoodSummaryScreen(),
                  ),
                  icon: const Icon(Icons.today),
                  label: Text(l10n.clientFoodTodayButton),
                ),
              ],
            ),
          ]);
    final basicSection = _section(context, l10n.basicInformation, [
            _row(context, l10n.name, liveClient.displayName),
            _row(context, l10n.clientId, liveClient.clientId),
            _rowWithAction(
              context,
              label: l10n.email,
              value: liveClient.email.trim().isEmpty ? '—' : liveClient.email.trim(),
              trailing: liveClient.email.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.copyEmail,
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: liveClient.email.trim()),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.emailCopied),
                            backgroundColor: colorScheme.primary,
                          ),
                        );
                      },
                    ),
            ),
            _row(context, l10n.registered, _fmtDate(liveClient.linkedAt)),
            _row(context, l10n.gender, _genderLabel(liveClient.gender)),
            _row(context, l10n.age, '${liveClient.age} ${l10n.years}'),
            _row(context, l10n.height, '${liveClient.heightCm} cm'),
            if (!isSensitive)
              _row(context, l10n.weight, '${liveClient.weightKg.toStringAsFixed(1)} kg'),
            _row(
              context,
              l10n.lastWorkout,
              lastSession == null ? '—' : _fmtDate(lastSession),
            ),
            _row(
              context,
              l10n.completedLast7Days,
              '$completedDaysInLast7 / 7 ${l10n.days}',
            ),
            if (!isSensitive)
              _row(
                context,
                l10n.compliance7Days,
                '${(compliance7d * 100).round()} %',
              ),
          ]);
    final todaySection = _section(context, l10n.today, [
            CheckboxListTile(
              value: workoutDoneToday,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.completedToday),
              subtitle: Text(
                workoutDoneToday
                    ? l10n.todayWorkoutSaved
                    : l10n.tapToSaveTodayWorkout,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              onChanged: workoutDoneToday
                  ? null
                  : (_) async {
                      await ref
                          .read(coachClientsControllerProvider.notifier)
                          .markWorkoutDoneToday(liveClient.clientId);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.todayWorkoutSaved),
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    },
            ),
          ]);
    final statusSection = _section(context, l10n.statusCheck, [
            _binaryStatusRow(
              context,
              label: l10n.sentComparisonPhotos,
              value: liveClient.photosDelivered,
              onYes: () async {
                await ref
                    .read(coachClientsControllerProvider.notifier)
                    .setPhotosDelivered(
                      clientId: liveClient.clientId,
                      value: true,
                    );
              },
              onNo: () async {
                await ref
                    .read(coachClientsControllerProvider.notifier)
                    .setPhotosDelivered(
                      clientId: liveClient.clientId,
                      value: false,
                    );
              },
              onRequest: () => _showRequestPlaceholder(
                context,
                l10n.photoRequestPlaceholder,
              ),
            ),
            const SizedBox(height: 10),
            _binaryStatusRow(
              context,
              label: l10n.followsDiet,
              value: liveClient.dietFollowed,
              onYes: () async {
                await ref
                    .read(coachClientsControllerProvider.notifier)
                    .setDietFollowed(
                      clientId: liveClient.clientId,
                      value: true,
                    );
              },
              onNo: () async {
                await ref
                    .read(coachClientsControllerProvider.notifier)
                    .setDietFollowed(
                      clientId: liveClient.clientId,
                      value: false,
                    );
              },
              onRequest: () => _showRequestPlaceholder(
                context,
                l10n.dietCheckPlaceholder,
              ),
            ),
            const SizedBox(height: 10),
            _binaryStatusRow(
              context,
              label: l10n.respondedToMessage,
              value: liveClient.communicationOk,
              onYes: () async {
                await ref
                    .read(coachClientsControllerProvider.notifier)
                    .setCommunicationOk(
                      clientId: liveClient.clientId,
                      value: true,
                    );
              },
              onNo: () async {
                await ref
                    .read(coachClientsControllerProvider.notifier)
                    .setCommunicationOk(
                      clientId: liveClient.clientId,
                      value: false,
                    );
              },
              onRequest: () => _showRequestPlaceholder(
                context,
                l10n.responseRequestPlaceholder,
              ),
            ),
          ]);
    final plansSection = _section(context, l10n.clientTrainingPlans, [
            Row(
              children: [
                Expanded(
                  child: Text(
                    clientPlans.isEmpty
                        ? l10n.clientHasNoPlans
                        : '${l10n.planCount}: ${clientPlans.length}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _createPlanDialog(context, ref, liveClient.clientId),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newPlan),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (clientPlans.isEmpty)
              Text(
                l10n.createFirstPlanHint,
              )
            else
              Column(
                children: [
                  for (final plan in clientPlans)
                    _planTile(context, ref, plan, liveClient.clientId),
                ],
              ),
          ]);
    final coachDataSection = _section(context, l10n.coachData, [
            detailsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('${l10n.error}: $e'),
              data: (d) => Column(
                children: [
                  _row(context, l10n.activity, _cap(d.activityType)),
                  _bigRow(context, l10n.injuries, d.injuries),
                  _bigRow(
                    context,
                    l10n.allergiesIntolerances,
                    '${d.allergies} / ${d.intolerances}',
                  ),
                ],
              ),
            ),
          ]);
    final inbodySection = _section(context, l10n.inbody, [
            if (isSensitive)
              Text(l10n.dataHiddenRecoveryMode)
            else
              inbodyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('${l10n.error}: $e'),
                data: (items) {
                  if (items.isEmpty) return Text(l10n.noMeasurements);
                  final latest = items.first;
                  return Column(
                    children: [
                      _row(context, l10n.weight, '${latest.weightKg} kg'),
                      _row(context, l10n.fat, '${latest.percentBodyFat} %'),
                      _row(context, l10n.muscles, '${latest.skeletalMuscleMassKg} kg'),
                      const SizedBox(height: 10),
                      _interpretationCard(context, liveClient, items),
                      if (items.length > 1) ...[
                        const SizedBox(height: 10),
                        _compareInbodyCard(context, latest, items[1]),
                      ],
                      const SizedBox(height: 10),
                      _inbodyTable(context, items.take(5).toList())
                    ],
                  );
                },
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddInbodyEntryScreen(
                    clientId: liveClient.clientId,
                    heightCm: liveClient.heightCm,
                  ),
                ),
              ),
              child: Text(l10n.addInbody),
            ),
          ]);
    final circSection = _section(context, l10n.circumferences, [
            if (isSensitive)
              Text(l10n.hiddenRecoveryMode)
            else
              circsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('${l10n.error}: $e'),
                data: (items) => items.isEmpty
                    ? Text(l10n.noRecords)
                    : _circTable(context, items.take(3).toList()),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddCircumferenceEntryScreen(clientId: liveClient.clientId),
                ),
              ),
              child: Text(l10n.addCircumferences),
            ),
          ]);
    final notesSection = _section(context, l10n.coachNotes, [
            notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('${l10n.error}: $e'),
              data: (notes) => Column(
                children: [
                  for (final n in notes)
                    _noteTile(context, ref, n.noteId, n.text, n.updatedAt),
                ],
              ),
            ),
          ]);
    final openAsClient =           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_new),

              label: Text(l10n.openAsClient),

              onPressed: () async {
                try {
                  await ref
                      .read(activeClientIdProvider.notifier)
                      .setActive(liveClient.clientId);

                  await ref
                      .read(appRoleProvider.notifier)
                      .setRole(AppRole.user);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.profileActivatedUserMode),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Chyba: $e"),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
          );

    void openPdf() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientMonthlyReportScreen(client: liveClient),
          ),
        );
    void addInbody() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddInbodyEntryScreen(
              clientId: liveClient.clientId,
              heightCm: liveClient.heightCm,
            ),
          ),
        );

    Widget tabList(List<Widget> children) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              children[i],
            ],
          ],
        );

    final sinceMonth = _monthsGen[liveClient.linkedAt.month - 1];
    final meta = [
      _genderLabel(liveClient.gender),
      if (liveClient.age > 0) '${liveClient.age} let',
      if (liveClient.heightCm > 0) '${liveClient.heightCm} cm',
      'klientem od $sinceMonth ${liveClient.linkedAt.year}',
    ].join(' · ');

    final sessionsDesc = [...history]..sort((a, b) => b.date.compareTo(a.date));
    final recentSessions = _RecentSessionsCard(sessions: sessionsDesc.take(6).toList());

    final attention = AttentionCard(
      alerts: pulse?.alerts ?? const [],
      title: 'POZORNOST',
      showNames: false,
      emptyText: 'Klient je v rytmu – nic nehoří.',
    );

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 720;
      final twoCols = box.maxWidth >= 980;

      final overview = tabList([
        if (isSensitive)
          _warningBox(
            context,
            l10n.recoveryMode,
            colorScheme.tertiaryContainer,
            colorScheme.onTertiaryContainer,
          ),
        _KpiTiles(
          client: liveClient,
          inbody: inbodyItems,
          completedLast7: completedDaysInLast7,
          lastSession: lastSession,
        ),
        CoachingInviteCard(client: liveClient),
        ClientCheckInsCard(client: liveClient),
        ClientActivityCard(client: liveClient),
        ClientPassesCard(client: liveClient),
        _ActionPlanCard(client: liveClient),
        if (twoCols)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    todaySection,
                    const SizedBox(height: 16),
                    statusSection,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    attention,
                    const SizedBox(height: 16),
                    recentSessions,
                  ],
                ),
              ),
            ],
          )
        else ...[
          attention,
          todaySection,
          statusSection,
          recentSessions,
        ],
        planSection,
        basicSection,
      ]);

      final bodyTab = tabList([inbodySection, circSection]);

      final trainingTab = tabList([
        AssignedWorkoutsCard(client: liveClient),
        _section(context, 'Trénink klienta', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _openForClient(
                  context,
                  ref,
                  liveClient,
                  const TrainingOverviewScreen(),
                ),
                icon: const Icon(Icons.fitness_center),
                label: Text(l10n.clientTrainingButton),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _openForClient(
                  context,
                  ref,
                  liveClient,
                  const CustomTrainingPlanScreen(),
                ),
                icon: const Icon(Icons.list_alt),
                label: Text(l10n.clientProgramsButton),
              ),
            ],
          ),
        ]),
        recentSessions,
        plansSection,
      ]);

      final foodTab = tabList([
        _section(context, 'Strava klienta', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _openForClient(
                  context,
                  ref,
                  liveClient,
                  const DietStrategyScreen(),
                ),
                icon: const Icon(Icons.restaurant_menu),
                label: Text(l10n.clientDietButton),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _openForClient(
                  context,
                  ref,
                  liveClient,
                  const FoodSummaryScreen(),
                ),
                icon: const Icon(Icons.today),
                label: Text(l10n.clientFoodTodayButton),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _openForClient(
                  context,
                  ref,
                  liveClient,
                  const OnboardingGoalScreen(),
                ),
                icon: const Icon(Icons.flag_outlined),
                label: Text(l10n.clientGoalButton),
              ),
            ],
          ),
        ]),
        ClientMealPlansCard(client: liveClient),
        FoodExclusionsCard(clientId: liveClient.clientId),
        coachDataSection,
      ]);

      final notesTab = tabList([
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _addNoteDialog(context, ref, liveClient.clientId),
            icon: const Icon(Icons.note_add_outlined),
            label: Text(l10n.addNote),
          ),
        ),
        notesSection,
        openAsClient,
      ]);

      return DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !embedded,
            toolbarHeight: 84,
            titleSpacing: embedded ? 20 : 0,
            title: Row(
              children: [
                if (pulse != null) ...[
                  ScoreRing(score: pulse.score, size: 56),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        liveClient.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              CoachChatButton(client: liveClient),
              if (wide) ...[
                OutlinedButton.icon(
                  onPressed: addInbody,
                  icon: const Icon(Icons.monitor_weight_outlined),
                  label: Text(l10n.addInbody),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: openPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Souhrn PDF'),
                ),
                const SizedBox(width: 4),
              ] else ...[
                IconButton(
                  tooltip: l10n.addInbody,
                  icon: const Icon(Icons.monitor_weight_outlined),
                  onPressed: addInbody,
                ),
                IconButton(
                  tooltip: 'Souhrn PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: openPdf,
                ),
              ],
          IconButton(
            tooltip: l10n.editClient,
            icon: const Icon(Icons.edit),
            onPressed: () => _editClientBasicsDialog(context, ref, liveClient),
          ),
          IconButton(
            tooltip: l10n.addNote,
            icon: const Icon(Icons.note_add),
            onPressed: () => _addNoteDialog(context, ref, liveClient.clientId),
          ),
          // Méně časté a nebezpečné akce v menu – mazání odděleně dole.
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'card':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EditClientDetailsScreen(clientId: liveClient.clientId),
                    ),
                  );
                  break;
                case 'export':
                  try {
                    final result = await ClientExportService.archiveClientExport(
                      client: liveClient,
                      details: detailsAsync.valueOrNull,
                      notes: notesAsync.valueOrNull ?? const [],
                      inbody: inbodyAsync.valueOrNull ?? const [],
                      circumferences: circsAsync.valueOrNull ?? const [],
                      performances: performances,
                      customPlans: clientPlans,
                      sessions: history,
                    );

                    if (context.mounted) {
                      await _showExportSuccessDialog(
                        context,
                        result: result,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n.exportError}: $e'),
                          backgroundColor: colorScheme.error,
                        ),
                      );
                    }
                  }
                  break;
                case 'folder':
                  await _openConfiguredExportFolder(context);
                  break;
                case 'import':
                  await _showImportSourceDialog(context, ref);
                  break;
                case 'archiveDelete':
                case 'delete':
                  await _deleteClientFlow(
                    context,
                    ref,
                    exportBeforeDelete: value == 'archiveDelete',
                  liveClient: liveClient,
                  details: detailsAsync.valueOrNull,
                  notes: notesAsync.valueOrNull ?? const [],
                  inbody: inbodyAsync.valueOrNull ?? const [],
                  circumferences: circsAsync.valueOrNull ?? const [],
                  performances: performances,
                  clientPlans: clientPlans,
                  history: history,
                  );
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'card',
                child: ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: Text(l10n.editClientCard),
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: Text(l10n.exportClient),
                ),
              ),
              PopupMenuItem(
                value: 'folder',
                child: ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(l10n.openExportFolder),
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(l10n.importRestoreClient),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'archiveDelete',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: colorScheme.error),
                  title: Text(
                    l10n.archiveAndDeleteClient,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: colorScheme.error),
                  title: Text(
                    l10n.deleteClient,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
              const SizedBox(width: 8),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Přehled'),
                Tab(text: 'Postava'),
                Tab(text: 'Trénink'),
                Tab(text: 'Strava'),
                Tab(text: 'Poznámky'),
              ],
            ),
          ),
          body: TabBarView(
            children: [overview, bodyTab, trainingTab, foodTab, notesTab],
          ),
        ),
      );
    });
  }

  /// Otevře obrazovku (cíl, jídelníček, trénink…) pro tohoto klienta
  /// přímo v trenérském režimu: klient se nastaví jako aktivní a načte se
  /// jeho profil, pak se obrazovka otevře. Po návratu je trenér zpět
  /// v detailu klienta.
  Future<void> _openForClient(
    BuildContext context,
    WidgetRef ref,
    CoachClient client,
    Widget screen,
  ) async {
    await ref.read(activeClientIdProvider.notifier).setActive(client.clientId);

    final notifier = ref.read(userProfileProvider.notifier);
    await notifier.switchToClient(client.clientId);

    final profile = ref.read(userProfileProvider);
    if (profile == null ||
        profile.clientId != client.clientId ||
        profile.height == 0 ||
        profile.weight == 0) {
      await notifier.setProfileBasics(
        clientId: client.clientId,
        firstName: client.firstName,
        lastName: client.lastName,
        age: client.age,
        gender: client.gender,
        heightCm: client.heightCm,
        weightKg: client.weightKg,
      );
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _editClientBasicsDialog(
    BuildContext context,
    WidgetRef ref,
    CoachClient liveClient,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final firstNameCtrl = TextEditingController(text: liveClient.firstName);
    final lastNameCtrl = TextEditingController(text: liveClient.lastName);
    final emailCtrl = TextEditingController(text: liveClient.email);
    final ageCtrl = TextEditingController(text: liveClient.age.toString());
    final heightCtrl =
        TextEditingController(text: liveClient.heightCm.toString());
    final weightCtrl =
        TextEditingController(text: liveClient.weightKg.toStringAsFixed(1));

    String gender = liveClient.gender;
    bool eatingDisorderSupport = liveClient.isEatingDisorderSupport;
    String? emailError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocalState) => AlertDialog(
          title: Text(l10n.editClient),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: firstNameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.firstName,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastNameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.lastName,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      setLocalState(() {
                        emailError = _isValidEmail(emailCtrl.text.trim())
                            ? null
                            : l10n.enterValidEmail;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      hintText: l10n.emailHint,
                      border: const OutlineInputBorder(),
                      errorText: emailError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    items:[
                      DropdownMenuItem(value: 'male', child: Text(l10n.male)),
                      DropdownMenuItem(value: 'female', child: Text(l10n.female)),
                      DropdownMenuItem(value: 'other', child: Text(l10n.other)),
                    ],
                    onChanged: (v) =>
                        setLocalState(() => gender = v ?? liveClient.gender),
                    decoration: InputDecoration(
                      labelText: l10n.gender,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.age,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.heightCm,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.weightKg,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.recoverySupport),
                    value: eatingDisorderSupport,
                    onChanged: (v) =>
                        setLocalState(() => eatingDisorderSupport = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final firstName = firstNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final age = int.tryParse(ageCtrl.text.trim());
    final height = int.tryParse(heightCtrl.text.trim());
    final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));

    if (!_isValidEmail(email)) {
      if (context.mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.enterValidEmail),
            backgroundColor: colorScheme.error,
          ),
        );
      }
      return;
    }

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        age == null ||
        height == null ||
        weight == null) {
      if (context.mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.checkRequiredFields),
            backgroundColor: colorScheme.error,
          ),
        );
      }
      return;
    }

    await ref.read(coachClientsControllerProvider.notifier).updateClientBasic(
          clientId: liveClient.clientId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          gender: gender,
          age: age,
          heightCm: height,
          weightKg: weight,
          isEatingDisorderSupport: eatingDisorderSupport,
        );

    final activeClientId = ref.read(activeClientIdProvider).valueOrNull;
    if (activeClientId == liveClient.clientId) {
      ref.read(userProfileProvider.notifier).setProfileBasics(
            clientId: liveClient.clientId,
            firstName: firstName,
            lastName: lastName,
            age: age,
            gender: gender,
            heightCm: height,
            weightKg: weight,
          );
    }

    if (context.mounted) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.clientBasicInfoUpdated),
          backgroundColor: colorScheme.primary,
        ),
      );
    }
  }

  static Future<void> _importClientDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.importClientFromJson),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            minLines: 10,
            maxLines: 18,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: l10n.pasteExportedJson,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.download),
            label: Text(l10n.importLabel),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final jsonString = controller.text.trim();
    if (jsonString.isEmpty) return;

    try {
      await const ClientImportService().importClientFromJson(jsonString, ref);

      if (context.mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clientImportedSuccessfully),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.importFailed}: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowWithAction(
    BuildContext context, {
    required String label,
    required String value,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _warningBox(
    BuildContext context,
    String text,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: foreground),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _binaryStatusRow(
    BuildContext context, {
    required String label,
    required bool value,
    required Future<void> Function() onYes,
    required Future<void> Function() onNo,
    required VoidCallback onRequest,
  }) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: Text(l10n.yes),
              selected: value,
              onSelected: (_) => onYes(),
            ),
            ChoiceChip(
              label: Text(l10n.no),
              selected: !value,
              onSelected: (_) => onNo(),
            ),
            if (!value)
              OutlinedButton(
                onPressed: onRequest,
                child: Text(l10n.request),
              ),
          ],
        ),
      ],
    );
  }

  void _showRequestPlaceholder(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.tertiary,
      ),
    );
  }

  Widget _interpretationCard(
    BuildContext context,
    CoachClient client,
    List<CoachInbodyEntry> items,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final report = InbodyAnalysis.analyze(
      latest: items.first,
      previous: items.length > 1 ? items[1] : null,
      gender: client.gender,
      age: client.age,
    );

    // Nejdůležitější zjištění: nejdřív problémy, pak zbytek.
    int rank(InbodyStatus s) => switch (s) {
          InbodyStatus.bad => 0,
          InbodyStatus.warn => 1,
          InbodyStatus.good => 2,
          InbodyStatus.ok => 3,
          InbodyStatus.info => 4,
        };
    final top = report.sections.expand((s) => s.findings).toList()
      ..sort((x, y) => rank(x.status).compareTo(rank(y.status)));

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.bodyType,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              report.summary,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            for (final f in top.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      inbodyStatusStyle(context, f.status).icon,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${f.title}: ${f.value}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InbodyReportScreen(client: client),
                  ),
                ),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Podrobný rozbor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compareInbodyCard(
    BuildContext context,
    CoachInbodyEntry latest,
    CoachInbodyEntry prev,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;
    String fmt(double v) => (v >= 0 ? '+' : '') + v.toStringAsFixed(1);

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.changeFromLastTime,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _row(
              context,
              l10n.weight,
              '${fmt(latest.weightKg - prev.weightKg)} kg',
            ),
            _row(
              context,
              l10n.fatPercent,
              '${fmt(latest.percentBodyFat - prev.percentBodyFat)} %',
            ),
            _row(
              context,
              l10n.muscles,
              '${fmt(latest.skeletalMuscleMassKg - prev.skeletalMuscleMassKg)} kg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _inbodyTable(
    BuildContext context,
    List<CoachInbodyEntry> items,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns:[
          DataColumn(label: Text(l10n.date)),
          DataColumn(label: Text(l10n.weight)),
          DataColumn(label: Text(l10n.muscles)),
          DataColumn(label: Text(l10n.fatPercent)),
        ],
        rows: items
            .map(
              (e) => DataRow(
                cells: [
                  DataCell(Text(_fmtDate(e.date))),
                  DataCell(Text('${e.weightKg.toStringAsFixed(1)} kg')),
                  DataCell(
                    Text('${e.skeletalMuscleMassKg.toStringAsFixed(1)} kg'),
                  ),
                  DataCell(Text('${e.percentBodyFat.toStringAsFixed(1)} %')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _circTable(
    BuildContext context,
    List<CoachCircumferenceEntry> items,
  ) {

    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 15,
        columns: [
          DataColumn(label: Text(l10n.date)),
          DataColumn(label: Text(l10n.waist)),
          DataColumn(label: Text(l10n.hips)),
          DataColumn(label: Text(l10n.thigh)),
      ],
        rows: items
            .map(
              (e) => DataRow(
                cells: [
                  DataCell(Text(_fmtDate(e.date))),
                  DataCell(Text('${e.waistCm.toStringAsFixed(0)} cm')),
                  DataCell(Text('${e.hipsCm.toStringAsFixed(0)} cm')),
                  DataCell(Text('${e.thighCm.toStringAsFixed(0)} cm')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _noteTile(
    BuildContext context,
    WidgetRef ref,
    String noteId,
    String text,
    DateTime updatedAt,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        text,
        style: TextStyle(color: colorScheme.onSurface),
      ),
      subtitle: Text(
        '${l10n.updated}: ${_fmtDate(updatedAt)}',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'edit') {
            await _editNoteDialog(context, ref, noteId, text);
          } else if (v == 'delete') {
            await ref
                .read(coachNotesControllerProvider.notifier)
                .deleteNote(noteId);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
          PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
        ],
      ),
    );
  }

  Widget _planTile(
    BuildContext context,
    WidgetRef ref,
    CustomTrainingPlan plan,
    String clientId,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: plan.isActive
              ? colorScheme.primary
              : colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        // Otevře plán k úpravám (dny, cviky).
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomPlanDetailScreen(planId: plan.id),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (plan.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.active,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${l10n.dayCount}: ${plan.days.length}\n'
            '${l10n.created}: ${_fmtDate(plan.createdAt)}',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'activate') {
              await ref.read(customTrainingPlanProvider.notifier).setActivePlan(
                    clientId: clientId,
                    planId: plan.id,
                  );
            } else if (value == 'duplicate') {
              await ref.read(customTrainingPlanProvider.notifier).duplicatePlan(
                    sourcePlanId: plan.id,
                    newName: '${plan.name} (${l10n.copy})',
                  );
            } else if (value == 'rename') {
              await _renamePlanDialog(context, ref, plan);
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.reallyDeletePlan),
                  content: Text(l10n.confirmDeletePlan(plan.name)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await ref
                  .read(customTrainingPlanProvider.notifier)
                  .deletePlan(plan.id);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'activate',
              child: Text(l10n.setAsActive),
            ),
            PopupMenuItem(
              value: 'duplicate',
              child: Text(l10n.duplicate),
            ),
            PopupMenuItem(
              value: 'rename',
              child: Text(l10n.rename),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(l10n.delete),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlanDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {

    final l10n = AppLocalizations.of(context)!;

    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.newTrainingPlan),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: l10n.planName,
            hintText: l10n.planNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.create),
          ),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(customTrainingPlanProvider.notifier).createPlan(
            clientId: clientId,
            name: ctrl.text.trim(),
          );
    }
  }

  Future<void> _renamePlanDialog(
    BuildContext context,
    WidgetRef ref,
    CustomTrainingPlan plan,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final ctrl = TextEditingController(text: plan.name);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.renamePlan),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: l10n.planName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(customTrainingPlanProvider.notifier).renamePlan(
            planId: plan.id,
            newName: ctrl.text.trim(),
          );
    }
  }

  Future<void> _addNoteDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {

    final l10n = AppLocalizations.of(context)!;

    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.newNote),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(coachNotesControllerProvider.notifier).addNote(
            clientId: clientId,
            text: ctrl.text.trim(),
          );
    }
  }

  Future<void> _editNoteDialog(
    BuildContext context,
    WidgetRef ref,
    String noteId,
    String currentText,
  ) async {

    final l10n = AppLocalizations.of(context)!;

    final ctrl = TextEditingController(text: currentText);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.editNote),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(coachNotesControllerProvider.notifier).updateNote(
            noteId: noteId,
            newText: ctrl.text.trim(),
          );
    }
  }

  static String _genderLabel(String g) {
    switch (g.toLowerCase()) {
      case 'male':
        return 'Muž';
      case 'female':
        return 'Žena';
      default:
        return 'Jiné';
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _cap(String s) =>
      s.isEmpty ? '—' : '${s[0].toUpperCase()}${s.substring(1)}';

  static bool _containsToday(List<DateTime> days) {
    final now = DateTime.now();
    return days.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }
}

const _monthsGen = [
  'ledna', 'února', 'března', 'dubna', 'května', 'června',
  'července', 'srpna', 'září', 'října', 'listopadu', 'prosince',
];

String _num(double v, [int digits = 1]) =>
    v.toStringAsFixed(digits).replaceAll('.', ',');

/// Akční plán (stejný jako v PDF) za posledních 30 dní.
final _clientActionPlanProvider = FutureProvider.autoDispose
    .family<List<CoachActionGroup>, CoachClient>((ref, client) async {
  final id = client.clientId;
  final inbody = ref.watch(coachInbodyForClientProvider(id)).valueOrNull ??
      const <CoachInbodyEntry>[];
  final perf = ref.watch(performancesForClientProvider(id));
  final to = DateTime.now();
  final from = to.subtract(const Duration(days: 30));
  final extras =
      await ClientReportExtras.load(client: client, from: from, to: to);
  return ClientReportPdfService.actionPlan(
    client: client,
    extras: extras,
    inbody: inbody,
    performances: perf,
    from: from,
    to: to,
  );
});

/// Čtyři hlavní čísla klienta nahoře v Přehledu.
class _KpiTiles extends StatelessWidget {
  final CoachClient client;

  /// Seřazeno od nejnovějšího.
  final List<CoachInbodyEntry> inbody;
  final int completedLast7;
  final DateTime? lastSession;

  const _KpiTiles({
    required this.client,
    required this.inbody,
    required this.completedLast7,
    required this.lastSession,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const good = Color(0xFF16A34A);
    const bad = Color(0xFFDC2626);
    final sensitive = client.isEatingDisorderSupport;
    final latest = inbody.isEmpty ? null : inbody.first;
    final first = inbody.length > 1 ? inbody.last : null;

    (String, Color)? delta(double now, double then, String unit,
        {required bool higherIsBetter}) {
      final d = now - then;
      if (d.abs() < 0.05) return ('beze změny od začátku', cs.onSurfaceVariant);
      final better = higherIsBetter ? d > 0 : d < 0;
      final sign = d > 0 ? '+' : '−';
      return (
        '$sign${_num(d.abs())} $unit od začátku',
        better ? good : bad,
      );
    }

    final tiles = <(String, String, (String, Color)?)>[];
    if (!sensitive && latest != null) {
      tiles.add((
        'Tělesný tuk',
        '${_num(latest.bodyFatPercent)} %',
        first == null
            ? null
            : delta(latest.bodyFatPercent, first.bodyFatPercent, '%',
                higherIsBetter: false),
      ));
      tiles.add((
        'Svaly',
        '${_num(latest.smmKg)} kg',
        first == null
            ? null
            : delta(latest.smmKg, first.smmKg, 'kg', higherIsBetter: true),
      ));
    }
    final days = lastSession == null
        ? null
        : DateTime.now().difference(lastSession!).inDays;
    tiles.add((
      'Docházka',
      '$completedLast7× týdně',
      (
        days == null
            ? 'zatím bez tréninku'
            : days == 0
                ? 'poslední trénink dnes'
                : 'poslední před $days ${czDays(days)}',
        days != null && days > 7 ? bad : cs.onSurfaceVariant,
      ),
    ));
    if (!sensitive) {
      final w = latest?.weightKg ?? client.weightKg;
      tiles.add((
        'Váha',
        w > 0 ? '${_num(w)} kg' : '—',
        latest == null
            ? ('bez měření InBody', cs.onSurfaceVariant)
            : (
                'měřeno ${latest.date.day}. ${latest.date.month}. ${latest.date.year}',
                cs.onSurfaceVariant,
              ),
      ));
    }

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 640 ? tiles.length : 2;
      const spacing = 12.0;
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final t in tiles)
            Container(
              width: w,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.$1,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.$2,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (t.$3 != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      t.$3!.$1,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: t.$3!.$2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    });
  }
}

/// „Akční plán na další období“ – karty Strava / Trénink / Regenerace.
class _ActionPlanCard extends ConsumerWidget {
  final CoachClient client;
  const _ActionPlanCard({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(_clientActionPlanProvider(client));

    Widget body;
    if (async.isLoading && !async.hasValue) {
      body = const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (async.hasError) {
      body = Text(
        'Plán se nepodařilo spočítat.',
        style: TextStyle(color: cs.onSurfaceVariant),
      );
    } else {
      final groups = (async.valueOrNull ?? const <CoachActionGroup>[])
          .where((g) => g.actions.isNotEmpty)
          .toList();
      if (groups.isEmpty) {
        body = Text(
          'Zatím málo dat. Přidej měření InBody a nech klienta zapisovat '
          'tréninky a jídlo – plán se pak doplní sám.',
          style: TextStyle(color: cs.onSurfaceVariant),
        );
      } else {
        final cards = [
          for (final g in groups)
            for (final a in g.actions.take(2)) (g.title, a),
        ].take(6).toList();
        body = LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 760 ? 3 : (c.maxWidth >= 480 ? 2 : 1);
          const spacing = 12.0;
          final w = (c.maxWidth - spacing * (cols - 1)) / cols;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final (title, a) in cards)
                Container(
                  width: w,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.headline,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.detail,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        });
      }
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Akční plán na další období',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'POSLEDNÍCH 30 DNÍ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            body,
          ],
        ),
      ),
    );
  }
}

/// Poslední zapsané tréninky klienta.
class _RecentSessionsCard extends StatelessWidget {
  final List<TrainingSession> sessions;
  const _RecentSessionsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Poslední tréninky',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Zatím žádný zapsaný trénink.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              )
            else
              for (final s in sessions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 54,
                        child: Text(
                          '${s.date.day}. ${s.date.month}.',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          [
                            s.dayPlan.dayLabel,
                            if (s.dayPlan.focus.isNotEmpty) s.dayPlan.focus,
                          ].join(' – '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                      Icon(
                        s.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: s.completed ? cs.primary : cs.outline,
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}