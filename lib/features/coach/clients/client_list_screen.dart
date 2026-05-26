import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/coach/active_client_provider.dart';
import '../../../providers/coach/coach_clients_controller.dart';
import '../../../services/coach/client_import_service.dart';
import '../../../services/coach/clients_export_service.dart';

import 'add_client_screen.dart';
import 'client_detail_screen.dart';
import 'package:dart_application_1/l10n/app_localizations.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() =>
      _ClientListScreenState();
}

class _ClientListScreenState
    extends ConsumerState<ClientListScreen> {
  bool _showArchived = false;

  Future<void> _setActiveClient(String clientId) async {
    await ref
        .read(activeClientIdProvider.notifier)
        .setActive(clientId);
  }

  Future<void> _copyEmails(
    List<CoachClientWithStats> clients,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final rawClients = clients.map((e) => e.client).toList();

    final emailsText =
        ClientsExportService.buildEmailsString(rawClients);

    if (emailsText.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.noClientsWithEmail,
          ),
        ),
      );

      return;
    }

    await Clipboard.setData(
      ClipboardData(text: emailsText),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.emailsCopied,
        ),
      ),
    );
  }

  Future<void> _exportCsv(
    List<CoachClientWithStats> clients,
  ) async {
    final path =
        await ClientsExportService.exportClientsCsv(
      clients.map((e) => e.client).toList(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null
              ? 'Export CSV byl zrušen.'
              : 'CSV bylo uloženo.',
        ),
      ),
    );
  }

  Future<void> _exportPdf(
    List<CoachClientWithStats> clients,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    await ClientsExportService.exportClientsPdf(
      clients.map((e) => e.client).toList(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.pdfExportOpened,
        ),
      ),
    );
  }

  Future<void> _importArchivedClientsFromCsvFile() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      const typeGroup = XTypeGroup(
        label: 'CSV',
        extensions: ['csv'],
      );

      final file = await openFile(
        acceptedTypeGroups: const [typeGroup],
        confirmButtonText: l10n.selectCsv,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      String csvString;

      try {
        csvString = utf8.decode(bytes);
      } catch (_) {
        csvString = latin1.decode(bytes);
      }

      final count = await ref
          .read(
            coachClientsControllerProvider.notifier,
          )
          .importArchivedClientsFromCsv(csvString);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? l10n.noArchivedClientsImported
                : l10n.archivedClientsImported(
                    count,
                  ),
          ),
        ),
      );

      if (count > 0) {
        setState(() {
          _showArchived = true;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.archiveCsvImportFailed(
              e.toString(),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _archiveClient(
    CoachClientWithStats clientWithStats,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final client = clientWithStats.client;

    await ref
        .read(
          coachClientsControllerProvider.notifier,
        )
        .archiveClient(client.clientId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.clientMovedToArchive(
            client.displayName,
          ),
        ),
      ),
    );
  }

  Future<void> _restoreArchivedClient(
    CoachClientWithStats clientWithStats,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final client = clientWithStats.client;

    await ref
        .read(
          coachClientsControllerProvider.notifier,
        )
        .restoreArchivedClient(client.clientId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.clientRestored(
            client.displayName,
          ),
        ),
      ),
    );
  }

  Future<void> _importClientFromJsonFile() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      const typeGroup = XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
      );

      final file = await openFile(
        acceptedTypeGroups: const [typeGroup],
        confirmButtonText: l10n.selectJson,
      );

      if (file == null) return;

      final service = const ClientImportService();

      final preview =
          await service.previewClientImportFromJsonFile(
        file.path,
      );

      if (!mounted) return;

      final mode = await _showImportPreviewDialog(
        preview,
      );

      if (mode == null) return;

      await service.importClientFromJsonFile(
        file.path,
        ref,
        mode: mode,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.clientImported(
              preview.clientDisplayName,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.fileImportFailedWithError(
              e.toString(),
            ),
          ),
        ),
      );
    }
  }

  Future<ClientImportMode?> _showImportPreviewDialog(
    ClientImportPreview preview,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<ClientImportMode?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.importPreview),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Klient: ${preview.clientDisplayName}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Původní ID: ${preview.originalClientId}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Poznámky: ${preview.notesCount}',
                ),
                Text(
                  'InBody: ${preview.inbodyCount}',
                ),
                Text(
                  'Obvody: ${preview.circumferencesCount}',
                ),
                Text(
                  'Výkony: ${preview.performancesCount}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  ClientImportMode
                      .importAsNewIfConflict,
                );
              },
              child: const Text(
                'Importovat',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme =
        Theme.of(context).colorScheme;

    final clientsAsync = ref.watch(
      coachClientsControllerProvider,
    );

    return clientsAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text(
            '${l10n.error}: $e',
          ),
        ),
      ),
      data: (clients) {
        final activeClients = clients
            .where((c) => !c.client.isArchived)
            .toList();

        final archivedClients = clients
            .where((c) => c.client.isArchived)
            .toList();

        final displayedClients = _showArchived
            ? archivedClients
            : activeClients;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          floatingActionButtonLocation:
              FloatingActionButtonLocation
                  .centerFloat,
          floatingActionButton: !_showArchived
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.addClient),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const AddClientScreen(),
                      ),
                    );
                  },
                )
              : null,
          body: SafeArea(
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                140,
              ),
              children: [
                Autocomplete<CoachClientWithStats>(
                  optionsBuilder: (text) {
                    final q = text.text
                        .trim()
                        .toLowerCase();

                    if (q.isEmpty) {
                      return const Iterable<
                          CoachClientWithStats>.empty();
                    }

                    return displayedClients.where(
                      (c) =>
                          c.client.displayName
                              .toLowerCase()
                              .contains(q) ||
                          c.client.clientId
                              .toLowerCase()
                              .contains(q) ||
                          c.client.email
                              .toLowerCase()
                              .contains(q),
                    );
                  },
                  displayStringForOption: (c) =>
                      c.client.displayName,
                  onSelected: (selected) async {
                    await _setActiveClient(
                      selected.client.clientId,
                    );

                    if (!context.mounted) return;

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ClientDetailScreen(
                          client: selected.client,
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (
                    context,
                    ctrl,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return TextField(
                      controller: ctrl,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.search),
                        hintText:
                            l10n.searchByNameEmailOrId,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                ToggleButtons(
                  isSelected: [
                    !_showArchived,
                    _showArchived,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _showArchived = index == 1;
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(14),
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Aktivní (${activeClients.length})',
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.archive,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Archiv (${archivedClients.length})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          displayedClients.isEmpty
                              ? null
                              : () => _copyEmails(
                                    displayedClients,
                                  ),
                      icon: const Icon(Icons.copy),
                      label: Text(
                        l10n.copyEmails,
                      ),
                    ),

                    OutlinedButton.icon(
                      onPressed:
                          displayedClients.isEmpty
                              ? null
                              : () => _exportCsv(
                                    displayedClients,
                                  ),
                      icon: const Icon(
                        Icons.table_chart,
                      ),
                      label:
                          const Text('Export CSV'),
                    ),

                    OutlinedButton.icon(
                      onPressed:
                          displayedClients.isEmpty
                              ? null
                              : () => _exportPdf(
                                    displayedClients,
                                  ),
                      icon: const Icon(
                        Icons.picture_as_pdf,
                      ),
                      label:
                          const Text('Export PDF'),
                    ),

                    OutlinedButton.icon(
                      onPressed:
                          _importArchivedClientsFromCsvFile,
                      icon: const Icon(
                        Icons.archive_outlined,
                      ),
                      label: Text(
                        l10n.archiveCsvImport,
                      ),
                    ),

                    OutlinedButton.icon(
                      onPressed:
                          _importClientFromJsonFile,
                      icon: const Icon(
                        Icons.description,
                      ),
                      label:
                          const Text('Import JSON'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (displayedClients.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 60,
                    ),
                    child: Center(
                      child: Text(
                        _showArchived
                            ? l10n.archiveHasNoClients
                            : l10n.noActiveClientsYet,
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  ),

                ...displayedClients.map(
                  (c) {
                    final name =
                        c.client.displayName;

                    final email =
                        c.client.email.trim();

                    final tileColor =
                        c.client.isArchived
                            ? colorScheme
                                .secondaryContainer
                                .withValues(
                                  alpha: 0.35,
                                )
                            : c.isInactive7d
                                ? colorScheme
                                    .errorContainer
                                    .withValues(
                                      alpha: 0.45,
                                    )
                                : null;

                    return Container(
                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.all(
                          16,
                        ),
                        title: Text(
                          '$name (${c.client.clientId})',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 10,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Odcvičeno za 7 dní: ${c.completedDaysInLast7}/7',
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                'Věk: ${c.client.age}, ${c.client.heightCm} cm'
                                '${c.client.isEatingDisorderSupport ? '' : ', ${c.client.weightKg.toStringAsFixed(1)} kg'}',
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                email.isEmpty
                                    ? 'Email: —'
                                    : 'Email: $email',
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  if (c.client
                                      .isArchived)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            10,
                                        vertical:
                                            4,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            colorScheme
                                                .secondary,
                                        borderRadius:
                                            BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'ARCHIV',
                                        style:
                                            TextStyle(
                                          color:
                                              colorScheme
                                                  .onSecondary,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (!c.client
                                          .isArchived &&
                                      c.isInactive7d)
                                    Container(
                                      margin:
                                          const EdgeInsets.only(
                                        left: 8,
                                      ),
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            10,
                                        vertical:
                                            4,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            colorScheme
                                                .error,
                                        borderRadius:
                                            BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'NECVIČIL 7+ DNÍ',
                                        style:
                                            TextStyle(
                                          color:
                                              colorScheme
                                                  .onError,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: c.client
                                .isArchived
                            ? FilledButton(
                                onPressed: () =>
                                    _restoreArchivedClient(
                                  c,
                                ),
                                child: const Text(
                                  'Obnovit',
                                ),
                              )
                            : PopupMenuButton<
                                String>(
                                onSelected:
                                    (
                                      value,
                                    ) async {
                                  if (value ==
                                      'archive') {
                                    await _archiveClient(
                                      c,
                                    );
                                  }
                                },
                                itemBuilder:
                                    (context) => const [
                                  PopupMenuItem<
                                      String>(
                                    value:
                                        'archive',
                                    child: Text(
                                      'Přesunout do archivu',
                                    ),
                                  ),
                                ],
                              ),
                        onTap: () async {
                          await _setActiveClient(
                            c.client.clientId,
                          );

                          if (!context.mounted) return;

                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClientDetailScreen(
                                client:
                                    c.client,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}