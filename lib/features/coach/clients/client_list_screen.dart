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
    final rawClients = clients.map((e) => e.client).toList();

    final emailsText =
        ClientsExportService.buildEmailsString(rawClients);

    if (emailsText.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Žádný klient zatím nemá vyplněný email.'),
        ),
      );

      return;
    }

    await Clipboard.setData(
      ClipboardData(text: emailsText),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Emaily byly zkopírovány do schránky.'),
      ),
    );
  }

  Future<void> _exportCsv(
    List<CoachClientWithStats> clients,
  ) async {
    final rawClients = clients.map((e) => e.client).toList();

    final path =
        await ClientsExportService.exportClientsCsv(
      rawClients,
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
    final rawClients = clients.map((e) => e.client).toList();

    await ClientsExportService.exportClientsPdf(
      rawClients,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('PDF export byl otevřen pro tisk / uložení.'),
      ),
    );
  }

  Future<void> _importArchivedClientsFromCsvFile() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'CSV',
        extensions: ['csv'],
      );

      final file = await openFile(
        acceptedTypeGroups: const [typeGroup],
        confirmButtonText: 'Vybrat CSV',
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
                ? 'Z CSV nebyl importován žádný nový archivní klient.'
                : 'Import hotový. Přidáno archivních klientů: $count',
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
            'Import CSV do archivu selhal: $e',
          ),
        ),
      );
    }
  }

  Future<void> _archiveClient(
    CoachClientWithStats clientWithStats,
  ) async {
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
          'Klient "${client.displayName}" byl přesunut do archivu.',
        ),
      ),
    );
  }

  Future<void> _restoreArchivedClient(
    CoachClientWithStats clientWithStats,
  ) async {
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
          'Klient "${client.displayName}" byl obnoven.',
        ),
      ),
    );
  }

  Future<void> _importClientFromJsonFile() async {
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
            'Klient "${preview.clientDisplayName}" byl importován.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import ze souboru selhal: $e',
          ),
        ),
      );
    }
  }

  Future<ClientImportMode?> _showImportPreviewDialog(
    ClientImportPreview preview,
  ) {
    return showDialog<ClientImportMode?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Náhled před importem'),
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
              child: const Text('Zrušit'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  ClientImportMode
                      .importAsNewIfConflict,
                );
              },
              child: const Text('Importovat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Text('Chyba: $e'),
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
                  icon:
                      const Icon(Icons.person_add),
                  label: const Text(
                    'Přidat klienta',
                  ),
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
                          client:
                              selected.client,
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder:
                      (
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
                            'Hledej jméno, email nebo ID',
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
                      label: const Text(
                        'Kopírovat emaily',
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
                      label: const Text(
                        'Import CSV do archivu',
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
                            ? 'Archiv zatím neobsahuje žádné klienty.'
                            : 'Zatím nemáš žádné aktivní klienty.',
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