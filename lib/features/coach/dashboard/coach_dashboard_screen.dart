import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../../../providers/coach/coach_circumference_controller.dart';
import '../../../providers/coach/coach_client_details_controller.dart';
import '../../../providers/coach/coach_clients_controller.dart';
import '../../../providers/coach/coach_diagnostic_controller.dart';
import '../../../providers/coach/coach_goal_controller.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
import '../../../providers/coach/coach_notes_controller.dart';
import '../../../providers/coach/coach_setup_provider.dart';


import '../../../providers/daily_history_provider.dart';
import '../../../providers/daily_intake_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/training_session_provider.dart';


import '../../../services/coach/coach_cloud_sync_service.dart';
import '../../../services/local_storage_service.dart';

import '../../help/widgets/help_and_reset_actions.dart';

class CoachDashboardScreen
    extends ConsumerStatefulWidget {
  const CoachDashboardScreen({
    super.key,
  });

  @override
  ConsumerState<CoachDashboardScreen>
      createState() =>
          _CoachDashboardScreenState();
}

class _CoachDashboardScreenState
    extends ConsumerState<
        CoachDashboardScreen> {
  bool _syncBusy = false;
  bool _folderBusy = false;

  Future<void> _reloadCoachData() async {
    ref.invalidate(
      coachClientsControllerProvider,
    );

    ref.invalidate(
      coachNotesControllerProvider,
    );

    ref.invalidate(
      coachInbodyControllerProvider,
    );

    ref.invalidate(
      coachCircumferenceControllerProvider,
    );

    ref.invalidate(
      coachDiagnosticControllerProvider,
    );

    ref.invalidate(
      coachGoalControllerProvider,
    );

    ref.invalidate(
      trainingSessionProvider,
    );

    ref.invalidate(
      dailyHistoryProvider,
    );

    ref.invalidate(
      dailyIntakeProvider,
    );

    ref.invalidate(
      coachSetupProvider,
    );

    ref.invalidate(
      coachClientDetailsControllerProvider,
    );

    await ref
        .read(
          coachClientsControllerProvider
              .notifier,
        )
        .reload();

    await ref
        .read(
          coachNotesControllerProvider
              .notifier,
        )
        .reload();

    await ref
        .read(
          coachInbodyControllerProvider
              .notifier,
        )
        .reload();

    await ref
        .read(
          coachCircumferenceControllerProvider
              .notifier,
        )
        .reload();
  }

  Future<void> _pushToCloud() async {
    final l10n =
        AppLocalizations.of(context)!;

    if (_syncBusy) return;

    final colorScheme =
        Theme.of(context).colorScheme;

    setState(() {
      _syncBusy = true;
    });

    try {
      final report =
          await CoachCloudSyncService
              .safePushAllFromLocal();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            report.success
                ? '${l10n.cloudBackupFinished}. ${report.processedKeys.length}'
                : '${l10n.cloudBackupFailed}: ${report.warnings.join(' | ')}',
          ),
          duration:
              const Duration(seconds: 4),
          backgroundColor:
              report.success
                  ? colorScheme.primary
                  : colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.error}: $e',
          ),
          backgroundColor:
              colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncBusy = false;
        });
      }
    }
  }

  Future<void> _pullFromCloud() async {
    final l10n =
        AppLocalizations.of(context)!;

    if (_syncBusy) return;

    final colorScheme =
        Theme.of(context).colorScheme;

    setState(() {
      _syncBusy = true;
    });

    try {
      final report =
          await CoachCloudSyncService
              .safePullMergeToLocal();

      await _reloadCoachData();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            report.success
                ? '${l10n.cloudRestoreFinished}. ${report.processedKeys.length}'
                : '${l10n.cloudRestoreFailed}: ${report.warnings.join(' | ')}',
          ),
          duration:
              const Duration(seconds: 4),
          backgroundColor:
              report.success
                  ? colorScheme.primary
                  : colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.error}: $e',
          ),
          backgroundColor:
              colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncBusy = false;
        });
      }
    }
  }

  Future<void>
      _pickAndSaveExportFolder() async {
    final l10n =
        AppLocalizations.of(context)!;

    if (_folderBusy) return;

    final colorScheme =
        Theme.of(context).colorScheme;

    setState(() {
      _folderBusy = true;
    });

    try {
      final selectedPath =
          await getDirectoryPath(
        confirmButtonText:
            l10n.selectFolder,
      );

      if (selectedPath == null ||
          selectedPath.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _folderBusy = false;
          });
        }
        return;
      }

      final dir = Directory(
        selectedPath,
      );

      if (!dir.existsSync()) {
        await dir.create(
          recursive: true,
        );
      }

      await LocalStorageService
          .saveClientExportFolderPath(
        selectedPath.trim(),
      );

      await ref
          .read(
            coachSetupProvider.notifier,
          )
          .updateExportFolderPath(
            selectedPath.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.exportFolderSaved}\n${dir.path}',
          ),
          duration:
              const Duration(seconds: 4),
          backgroundColor:
              colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.folderPickFailed(
              e.toString(),
            ),
          ),
          backgroundColor:
              colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _folderBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    final colorScheme =
        Theme.of(context).colorScheme;

    final clientsAsync = ref.watch(
      coachClientsControllerProvider,
    );

    final coachSetupAsync = ref.watch(
      coachSetupProvider,
    );

    final coachSetup =
        coachSetupAsync.asData?.value;

    final coachFirstName =
        coachSetup?.firstName.trim();

    final exportFolderPath =
        coachSetup?.exportFolderPath
                .trim() ??
            '';

    final coachTitle =
        (coachFirstName != null &&
                coachFirstName
                    .isNotEmpty)
            ? 'Coach $coachFirstName'
            : l10n.coachMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          coachTitle,
        ),
        actions: [
          PopupMenuButton<Locale?>(
            icon: const Icon(
              Icons.language,
            ),
            onSelected: (locale) {
              ref
                  .read(
                    localeProvider.notifier,
                  )
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
                value: const Locale(
                  'cs',
                ),
                child: Text(
                  l10n.czech,
                ),
              ),
              PopupMenuItem(
                value: const Locale(
                  'en',
                ),
                child: Text(
                  l10n.english,
                ),
              ),
            ],
          ),

          const HelpAndResetActions(),
        ],
      ),
      body: clientsAsync.when(
        loading: () => const Center(
          child:
              CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Text(
              '${l10n.error}: $e',
              textAlign:
                  TextAlign.center,
            ),
          ),
        ),
        data: (clients) {
          final warnings = clients
              .where(
                (c) => c.isInactive7d,
              )
              .length;

          return ListView(
            padding:
                const EdgeInsets.all(16),
            children: [
              Text(
                coachFirstName != null &&
                        coachFirstName
                            .isNotEmpty
                    ? 'Coach $coachFirstName'
                    : l10n.coachMode,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      color: colorScheme
                          .onSurface,
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(
                height: 12,
              ),

              _StatCard(
                title: l10n.clients,
                value:
                    clients.length.toString(),
                icon: Icons.people,
              ),

              const SizedBox(
                height: 12,
              ),

              _StatCard(
                title:
                    l10n.clientInactive7Days,
                value:
                    warnings.toString(),
                icon:
                    Icons.warning_amber,
                highlighted:
                    warnings > 0,
              ),

              const SizedBox(
                height: 16,
              ),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      Text(
                        l10n
                            .openExportFolder,
                        style: Theme.of(
                                context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        exportFolderPath
                                .isEmpty
                            ? l10n
                                .exportFolderNotConfigured
                            : exportFolderPath,
                        style: TextStyle(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _folderBusy
                                    ? null
                                    : _pickAndSaveExportFolder,
                            icon: const Icon(
                              Icons
                                  .folder_open,
                            ),
                            label: Text(
                              l10n
                                  .change,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      Text(
                        l10n.cloudBackup,
                        style: Theme.of(
                                context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        l10n
                            .cloudBackupDescription,
                        style: TextStyle(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _syncBusy
                                    ? null
                                    : _pushToCloud,
                            icon: _syncBusy
                                ? SizedBox(
                                    width:
                                        16,
                                    height:
                                        16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .cloud_upload,
                                  ),
                            label: Text(
                              l10n
                                  .backupToCloud,
                            ),
                          ),

                          OutlinedButton.icon(
                            onPressed:
                                _syncBusy
                                    ? null
                                    : _pullFromCloud,
                            icon: const Icon(
                              Icons
                                  .cloud_download,
                            ),
                            label: Text(
                              l10n
                                  .restoreFromCloud,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool highlighted;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final backgroundColor =
        highlighted
            ? colorScheme
                .errorContainer
            : colorScheme.surface;

    final foregroundColor =
        highlighted
            ? colorScheme
                .onErrorContainer
            : colorScheme.onSurface;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: foregroundColor,
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color:
                          foregroundColor,
                      fontWeight:
                          FontWeight.w600,
                    ),
              ),
            ),

            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    color:
                        foregroundColor,
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}