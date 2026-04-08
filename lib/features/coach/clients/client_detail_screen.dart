import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Modely
import '../../../models/coach/coach_client.dart';
import '../../../models/coach/coach_circumference_entry.dart';
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
import '../../../services/coach/coach_metrics_service.dart';
import '../../../services/coach/client_export_service.dart';
import '../../../services/coach/client_import_service.dart';
import '../../../services/local_storage_service.dart';

// Obrazovky
import 'edit_client_details_screen.dart';
import 'add_circumference_entry_screen.dart';
import 'add_inbody_entry_screen.dart';
import 'client_monthly_report_screen.dart';

class ClientDetailScreen extends ConsumerWidget {
  final CoachClient client;

  const ClientDetailScreen({super.key, required this.client});

  bool get _sensitive => client.isEatingDisorderSupport;

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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archivace dokončena'),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Archiv klienta byl úspěšně vytvořen.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cílová složka',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SelectableText(result.clientDirectory.path),
                const SizedBox(height: 14),
                const Text(
                  'Vytvořené soubory',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                fileRow(
                  'Aktuální JSON',
                  result.currentJsonFile.path.split(Platform.pathSeparator).last,
                ),
                fileRow(
                  'Snapshot',
                  result.historyJsonFile.path.split(Platform.pathSeparator).last,
                ),
                fileRow(
                  'PDF report',
                  result.reportPdfFile.path.split(Platform.pathSeparator).last,
                ),
                fileRow(
                  'Manifest',
                  result.manifestFile.path.split(Platform.pathSeparator).last,
                ),
                fileRow(
                  'InBody CSV',
                  result.inbodyCsvFile.path.split(Platform.pathSeparator).last,
                ),
                fileRow(
                  'Obvody CSV',
                  result.circumferencesCsvFile.path
                      .split(Platform.pathSeparator)
                      .last,
                ),
                fileRow(
                  'Výkony CSV',
                  result.performancesCsvFile.path
                      .split(Platform.pathSeparator)
                      .last,
                ),
                const SizedBox(height: 14),
                Text(
                  'Období reportu: ${_fmtDate(result.reportFrom)} - ${_fmtDate(result.reportTo)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Zavřít'),
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
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Otevřít PDF'),
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
                      content: Text('Složku se nepodařilo otevřít: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Otevřít složku'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showImportSourceDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import / obnova klienta'),
        content: const Text(
          'Vyber, jak chceš klienta obnovit nebo importovat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Zavřít'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _importClientDialog(context, ref);
            },
            icon: const Icon(Icons.code),
            label: const Text('Vložit JSON ručně'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _importClientFromJsonFile(context, ref);
            },
            icon: const Icon(Icons.description),
            label: const Text('Vybrat JSON soubor'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _restoreClientFromArchiveFolder(context, ref);
            },
            icon: const Icon(Icons.restore),
            label: const Text('Obnovit z archivní složky'),
          ),
        ],
      ),
    );
  }

  static Future<void> _importClientFromJsonFile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      const typeGroup = XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
      );

      final file = await openFile(
        acceptedTypeGroups: const [typeGroup],
        confirmButtonText: 'Vybrat JSON',
      );

      if (file == null) return;

      await const ClientImportService().importClientFromJsonFile(file.path, ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Klient byl úspěšně importován ze souboru:\n${file.path}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import ze souboru selhal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _restoreClientFromArchiveFolder(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final folderPath = await getDirectoryPath(
        confirmButtonText: 'Vybrat archivní složku',
      );

      if (folderPath == null || folderPath.trim().isEmpty) return;

      await const ClientImportService().importClientFromArchiveFolder(
        folderPath,
        ref,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Klient byl úspěšně obnoven z archivní složky:\n$folderPath',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Obnova z archivní složky selhala: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openConfiguredExportFolder(BuildContext context) async {
    try {
      final savedPath = await LocalStorageService.loadClientExportFolderPath();

      if (savedPath == null || savedPath.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Není nastavena vlastní exportní složka. Nastav ji nejdřív v dashboardu.',
              ),
              backgroundColor: Colors.orange,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Složku se nepodařilo otevřít: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteClientFlow(
    BuildContext context,
    WidgetRef ref, {
    required bool exportBeforeDelete,
    required dynamic details,
    required List<dynamic> notes,
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circumferences,
    required List<ExercisePerformance> performances,
    required List<CustomTrainingPlan> clientPlans,
    required List<TrainingSession> history,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          exportBeforeDelete
              ? 'Archivovat a smazat klienta'
              : 'Smazat klienta',
        ),
        content: Text(
          exportBeforeDelete
              ? 'Klient bude nejdřív exportován a potom trvale smazán z aplikace.\n\nOpravdu pokračovat?'
              : 'Opravdu chceš klienta trvale smazat z aplikace?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(exportBeforeDelete ? 'Archivovat a smazat' : 'Smazat'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (exportBeforeDelete) {
        await ClientExportService.archiveClientExport(
          client: client,
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
      if (activeClientId == client.clientId) {
        await ref.read(activeClientIdProvider.notifier).clear();
        await ref.read(userProfileProvider.notifier).switchToClient(null);
      }

      await ref
          .read(customTrainingPlanProvider.notifier)
          .deletePlansForClient(client.clientId);

      await ref.read(userProfileProvider.notifier).clearClientData(client.clientId);

      await ref
          .read(coachClientsControllerProvider.notifier)
          .deleteClient(client.clientId);

      ref.invalidate(coachNotesControllerProvider);
      ref.invalidate(coachClientDetailsControllerProvider);
      ref.invalidate(coachCircumferenceControllerProvider);
      ref.invalidate(coachInbodyControllerProvider);
      ref.invalidate(coachClientsControllerProvider);

      if (!context.mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exportBeforeDelete
                ? 'Klient byl archivován a smazán.'
                : 'Klient byl smazán.',
          ),
          backgroundColor: exportBeforeDelete ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při mazání klienta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(coachNotesForClientProvider(client.clientId));
    final detailsAsync =
        ref.watch(coachClientDetailsForClientProvider(client.clientId));
    final circsAsync =
        ref.watch(coachCircumferencesForClientProvider(client.clientId));
    final inbodyAsync = ref.watch(coachInbodyForClientProvider(client.clientId));
    final performances = ref.watch(
      performancesForClientProvider(client.clientId),
    );

    final List<TrainingSession> sessions = ref.watch(trainingSessionProvider);
    final List<TrainingSession> history =
        client.clientId == 'local_user' ? sessions : <TrainingSession>[];

    final customPlans = ref.watch(customTrainingPlanProvider);
    final clientPlans =
        customPlans.where((p) => p.clientId == client.clientId).toList();

    final now = DateTime.now();
    final compliance7d = CoachMetricsService.complianceForDays(
      history: history,
      now: now,
      days: 7,
      frequencyPerWeek: 3,
    );

    final lastSession = history.isEmpty
        ? null
        : ([...history]..sort((a, b) => b.date.compareTo(a.date))).first.date;

    return Scaffold(
      appBar: AppBar(
        title: Text('${client.firstName} ${client.lastName}'),
        actions: [
          IconButton(
            tooltip: 'Analýza klienta',
            icon: const Icon(Icons.assessment),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ClientMonthlyReportScreen(client: client),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Otevřít exportní složku',
            icon: const Icon(Icons.folder_open),
            onPressed: () => _openConfiguredExportFolder(context),
          ),
          IconButton(
            tooltip: 'Import / obnova klienta',
            icon: const Icon(Icons.download),
            onPressed: () => _showImportSourceDialog(context, ref),
          ),
          IconButton(
            tooltip: 'Export klienta',
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              try {
                final result = await ClientExportService.archiveClientExport(
                  client: client,
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
                      content: Text('Chyba exportu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Archivovat a smazat klienta',
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => _deleteClientFlow(
              context,
              ref,
              exportBeforeDelete: true,
              details: detailsAsync.valueOrNull,
              notes: notesAsync.valueOrNull ?? const [],
              inbody: inbodyAsync.valueOrNull ?? const [],
              circumferences: circsAsync.valueOrNull ?? const [],
              performances: performances,
              clientPlans: clientPlans,
              history: history,
            ),
          ),
          IconButton(
            tooltip: 'Smazat klienta',
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteClientFlow(
              context,
              ref,
              exportBeforeDelete: false,
              details: detailsAsync.valueOrNull,
              notes: notesAsync.valueOrNull ?? const [],
              inbody: inbodyAsync.valueOrNull ?? const [],
              circumferences: circsAsync.valueOrNull ?? const [],
              performances: performances,
              clientPlans: clientPlans,
              history: history,
            ),
          ),
          IconButton(
            tooltip: 'Upravit klienta',
            icon: const Icon(Icons.edit),
            onPressed: () => _editClientBasicsDialog(context, ref),
          ),
          IconButton(
            tooltip: 'Upravit kartu klienta',
            icon: const Icon(Icons.edit_note),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    EditClientDetailsScreen(clientId: client.clientId),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Přidat poznámku',
            icon: const Icon(Icons.note_add),
            onPressed: () => _addNoteDialog(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(context, 'Základní informace', [
            _row('Jméno', client.displayName),
            _row('ID klienta', client.clientId),
            _rowWithAction(
              context,
              label: 'Email',
              value: client.email.trim().isEmpty ? '—' : client.email.trim(),
              trailing: client.email.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Kopírovat email',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: client.email.trim()),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email zkopírován do schránky.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
            ),
            _row('Registrován', _fmtDate(client.linkedAt)),
            _row('Pohlaví', _genderLabel(client.gender)),
            _row('Věk', '${client.age} let'),
            _row('Výška', '${client.heightCm} cm'),
            if (!_sensitive)
              _row('Váha', '${client.weightKg.toStringAsFixed(1)} kg'),
            _row(
              'Poslední trénink',
              lastSession == null ? '—' : _fmtDate(lastSession),
            ),
            if (!_sensitive)
              _row('Plnění (7 dní)', '${(compliance7d * 100).round()} %'),
          ]),

          if (_sensitive) ...[
            const SizedBox(height: 12),
            _warningBox(),
          ],

          const SizedBox(height: 16),

          _section(context, 'Tréninkové plány klienta', [
            Row(
              children: [
                Expanded(
                  child: Text(
                    clientPlans.isEmpty
                        ? 'Klient zatím nemá žádný vlastní plán.'
                        : 'Počet plánů: ${clientPlans.length}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _createPlanDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Nový plán'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (clientPlans.isEmpty)
              const Text(
                'Vytvoř první vlastní plán pro tohoto klienta. '
                'Později do něj přidáme dny a cviky.',
              )
            else
              Column(
                children: [
                  for (final plan in clientPlans) _planTile(context, ref, plan),
                ],
              ),
          ]),

          const SizedBox(height: 16),

          _section(context, 'Údaje pro trenéra', [
            detailsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Chyba: $e'),
              data: (d) => Column(
                children: [
                  _row('Aktivita', _cap(d.activityType)),
                  _bigRow('Zranění', d.injuries),
                  _bigRow(
                    'Alergie / Intolerance',
                    '${d.allergies} / ${d.intolerances}',
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),

          _section(context, 'InBody', [
            if (_sensitive)
              const Text('Data skryta (Recovery režim)')
            else
              inbodyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Chyba: $e'),
                data: (items) {
                  if (items.isEmpty) return const Text('Žádná měření.');
                  final latest = items.first;
                  return Column(
                    children: [
                      _row('Váha', '${latest.weightKg} kg'),
                      _row('Tuk', '${latest.percentBodyFat} %'),
                      _row('Svaly', '${latest.skeletalMuscleMassKg} kg'),
                      const SizedBox(height: 10),
                      _interpretationCard(latest),
                      if (items.length > 1) ...[
                        const SizedBox(height: 10),
                        _compareInbodyCard(latest, items[1]),
                      ],
                      const SizedBox(height: 10),
                      _inbodyTable(items.take(5).toList()),
                    ],
                  );
                },
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddInbodyEntryScreen(
                    clientId: client.clientId,
                    heightCm: client.heightCm,
                  ),
                ),
              ),
              child: const Text('Přidat InBody'),
            ),
          ]),

          const SizedBox(height: 16),

          _section(context, 'Obvody', [
            if (_sensitive)
              const Text('Skryto (Recovery režim)')
            else
              circsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Chyba: $e'),
                data: (items) => items.isEmpty
                    ? const Text('Žádné záznamy')
                    : _circTable(items.take(3).toList()),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddCircumferenceEntryScreen(clientId: client.clientId),
                ),
              ),
              child: const Text('Přidat obvody'),
            ),
          ]),

          const SizedBox(height: 16),

          _section(context, 'Poznámky trenéra', [
            notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Chyba: $e'),
              data: (notes) => Column(
                children: [
                  for (final n in notes)
                    _noteTile(context, ref, n.noteId, n.text, n.updatedAt),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.rocket_launch),
              label: const Text("PŘEPNOUT NA TENTO PROFIL"),
              onPressed: () async {
                try {
                  await ref
                      .read(activeClientIdProvider.notifier)
                      .setActive(client.clientId);

                  await ref.read(appRoleProvider.notifier).setRole(AppRole.user);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profil aktivován. Režim: Uživatel."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Chyba: $e")),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Future<void> _editClientBasicsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final firstNameCtrl = TextEditingController(text: client.firstName);
    final lastNameCtrl = TextEditingController(text: client.lastName);
    final emailCtrl = TextEditingController(text: client.email);
    final ageCtrl = TextEditingController(text: client.age.toString());
    final heightCtrl = TextEditingController(text: client.heightCm.toString());
    final weightCtrl =
        TextEditingController(text: client.weightKg.toStringAsFixed(1));

    String gender = client.gender;
    bool eatingDisorderSupport = client.isEatingDisorderSupport;
    String? emailError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocalState) => AlertDialog(
          title: const Text('Upravit klienta'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: firstNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Jméno',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Příjmení',
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
                            : 'Zadej platný email';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'napr. klient@email.cz',
                      border: const OutlineInputBorder(),
                      errorText: emailError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Muž')),
                      DropdownMenuItem(value: 'female', child: Text('Žena')),
                      DropdownMenuItem(value: 'other', child: Text('Jiné')),
                    ],
                    onChanged: (v) =>
                        setLocalState(() => gender = v ?? client.gender),
                    decoration: const InputDecoration(
                      labelText: 'Pohlaví',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Věk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Výška (cm)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Váha (kg)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Recovery / PPP podpora'),
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
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Uložit'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zadej prosím platný email.'),
            backgroundColor: Colors.red,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zkontroluj prosím jméno, příjmení a číselná pole.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await ref.read(coachClientsControllerProvider.notifier).updateClientBasic(
          clientId: client.clientId,
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
    if (activeClientId == client.clientId) {
      ref.read(userProfileProvider.notifier).setProfileBasics(
            clientId: client.clientId,
            firstName: firstName,
            lastName: lastName,
            age: age,
            gender: gender,
            heightCm: height,
            weightKg: weight,
          );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Základní údaje klienta byly upraveny.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  static Future<void> _importClientDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import klienta z JSON'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            minLines: 10,
            maxLines: 18,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Vlož exportovaný JSON klienta...',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.download),
            label: const Text('Importovat'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Klient byl úspěšně importován.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import selhal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _bigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(value.isEmpty ? '—' : value),
        ],
      ),
    );
  }

  Widget _warningBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 10),
          Text(
            'PPP / Recovery režim',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _interpretationCard(CoachInbodyEntry e) {
    final muscleRatio = e.skeletalMuscleMassKg / e.weightKg;
    final fatP = e.percentBodyFat;
    final lines = <String>[];

    if (fatP >= 25) {
      lines.add('Tělesný tuk je vyšší – priorita bude redukce tuku.');
    } else if (fatP >= 18) {
      lines.add('Tělesný tuk je střední – ideální pro formování.');
    } else {
      lines.add('Tělesný tuk je nízký – soustředíme se na výkon a svaly.');
    }

    if (muscleRatio >= 0.48) {
      lines.add('Svalová základna je velmi dobrá.');
    } else if (muscleRatio < 0.40) {
      lines.add('Svalů je méně – priorita budování hmoty.');
    }

    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Automatický výklad',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            for (final t in lines)
              Text('• $t', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _compareInbodyCard(CoachInbodyEntry latest, CoachInbodyEntry prev) {
    String fmt(double v) => (v >= 0 ? '+' : '') + v.toStringAsFixed(1);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Změna od posledně',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _row('Hmotnost', '${fmt(latest.weightKg - prev.weightKg)} kg'),
            _row(
              'Tuk (%)',
              '${fmt(latest.percentBodyFat - prev.percentBodyFat)} %',
            ),
            _row(
              'Svaly',
              '${fmt(latest.skeletalMuscleMassKg - prev.skeletalMuscleMassKg)} kg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _inbodyTable(List<CoachInbodyEntry> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Datum')),
          DataColumn(label: Text('Váha')),
          DataColumn(label: Text('Svaly')),
          DataColumn(label: Text('% tuku')),
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

  Widget _circTable(List<CoachCircumferenceEntry> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 15,
        columns: const [
          DataColumn(label: Text('Datum')),
          DataColumn(label: Text('Pas')),
          DataColumn(label: Text('Boky')),
          DataColumn(label: Text('Stehno')),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(text),
      subtitle: Text(
        'Upraveno: ${_fmtDate(updatedAt)}',
        style: const TextStyle(fontSize: 12),
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
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Upravit')),
          PopupMenuItem(value: 'delete', child: Text('Smazat')),
        ],
      ),
    );
  }

  Widget _planTile(
    BuildContext context,
    WidgetRef ref,
    CustomTrainingPlan plan,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: plan.isActive ? Colors.green.shade300 : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (plan.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aktivní',
                  style: TextStyle(
                    color: Colors.green,
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
            'Počet dnů: ${plan.days.length}\n'
            'Vytvořeno: ${_fmtDate(plan.createdAt)}',
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'activate') {
              await ref.read(customTrainingPlanProvider.notifier).setActivePlan(
                    clientId: client.clientId,
                    planId: plan.id,
                  );
            } else if (value == 'duplicate') {
              await ref.read(customTrainingPlanProvider.notifier).duplicatePlan(
                    sourcePlanId: plan.id,
                    newName: '${plan.name} (kopie)',
                  );
            } else if (value == 'rename') {
              await _renamePlanDialog(context, ref, plan);
            } else if (value == 'delete') {
              await ref
                  .read(customTrainingPlanProvider.notifier)
                  .deletePlan(plan.id);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'activate',
              child: Text('Nastavit jako aktivní'),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Text('Duplikovat'),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: Text('Přejmenovat'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Smazat'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlanDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nový tréninkový plán'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Název plánu',
            hintText: 'Např. Petr – šetrný plán',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vytvořit'),
          ),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(customTrainingPlanProvider.notifier).createPlan(
            clientId: client.clientId,
            name: ctrl.text.trim(),
          );
    }
  }

  Future<void> _renamePlanDialog(
    BuildContext context,
    WidgetRef ref,
    CustomTrainingPlan plan,
  ) async {
    final ctrl = TextEditingController(text: plan.name);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Přejmenovat plán'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Název plánu',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Uložit'),
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

  Future<void> _addNoteDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nová poznámka'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(coachNotesControllerProvider.notifier).addNote(
            clientId: client.clientId,
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
    final ctrl = TextEditingController(text: currentText);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upravit poznámku'),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Uložit'),
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
}