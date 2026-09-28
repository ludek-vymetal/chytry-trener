import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/coach/active_client_provider.dart';
import '../../../providers/coach/coach_clients_controller.dart';
import '../../../providers/subscription/subscription_provider.dart';
import '../../paywall/paywall_screen.dart';
import '../../help/help_button.dart';
import '../../common/adaptive_shell.dart';
import '../widgets/client_pulse.dart';
import '../../../models/coach/coach_inbody_entry.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
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

  bool _onlyAttention = false;
  String _query = '';
  String? _selectedId;

  Future<void> _addClient(int activeCount) async {
    final max = ref.read(accessProvider).maxClients;
    if (max != null && activeCount >= max) {
      await showUpgradeSheet(context, ref, feature: 'Další klient');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddClientScreen()),
    );
  }

  Future<void> _open(ClientPulse p, {required bool wide}) async {
    await _setActiveClient(p.client.clientId);
    if (!mounted) return;
    if (wide) {
      setState(() => _selectedId = p.client.clientId);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: p.client)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final clientsAsync = ref.watch(coachClientsControllerProvider);
    final inbodyAll = ref.watch(coachInbodyControllerProvider).asData?.value ??
        const <CoachInbodyEntry>[];
    final wide =
        MediaQuery.sizeOf(context).width >= SidePanelLayout.breakpoint;

    return clientsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('${l10n.error}: $e')),
      ),
      data: (clients) {
        final lastIb = ClientPulse.lastInbodyByClient(inbodyAll);
        final pulses = [
          for (final c in clients) ClientPulse.of(c, lastIb[c.client.clientId]),
        ];
        final active = pulses.where((p) => !p.client.isArchived).toList();
        final archived = pulses.where((p) => p.client.isArchived).toList();
        final attention = active.where((p) => p.needsAttention).toList();

        var shown = _showArchived
            ? archived
            : (_onlyAttention ? attention : active);
        final q = _query.trim().toLowerCase();
        if (q.isNotEmpty) {
          shown = shown
              .where((p) =>
                  p.client.displayName.toLowerCase().contains(q) ||
                  p.client.clientId.toLowerCase().contains(q) ||
                  p.client.email.toLowerCase().contains(q))
              .toList();
        }
        final displayedClients = shown.map((p) => p.data).toList();

        ClientPulse? selected;
        if (wide) {
          for (final p in pulses) {
            if (p.client.clientId == _selectedId) selected = p;
          }
          selected ??= shown.isNotEmpty ? shown.first : null;
        }

        // ---------------- hlavička seznamu ----------------
        final header = Row(
          children: [
            Expanded(
              child: Text(
                l10n.clients,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const HelpButton(topic: 'clients'),
            PopupMenuButton<String>(
              tooltip: l10n.importExport,
              icon: const Icon(Icons.import_export),
              onSelected: (value) {
                switch (value) {
                  case 'emails':
                    _copyEmails(displayedClients);
                    break;
                  case 'csv':
                    _exportCsv(displayedClients);
                    break;
                  case 'pdf':
                    _exportPdf(displayedClients);
                    break;
                  case 'importCsv':
                    _importArchivedClientsFromCsvFile();
                    break;
                  case 'importJson':
                    _importClientFromJsonFile();
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'emails',
                  enabled: displayedClients.isNotEmpty,
                  child: ListTile(
                    leading: const Icon(Icons.copy),
                    title: Text(l10n.copyEmails),
                  ),
                ),
                PopupMenuItem(
                  value: 'csv',
                  enabled: displayedClients.isNotEmpty,
                  child: const ListTile(
                    leading: Icon(Icons.table_chart),
                    title: Text('Export CSV'),
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  enabled: displayedClients.isNotEmpty,
                  child: const ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text('Export PDF'),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'importCsv',
                  child: ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: Text(l10n.archiveCsvImport),
                  ),
                ),
                const PopupMenuItem(
                  value: 'importJson',
                  child: ListTile(
                    leading: Icon(Icons.description),
                    title: Text('Import JSON'),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: l10n.addClient,
              onPressed: () => _addClient(active.length),
              icon: const Icon(Icons.add),
            ),
          ],
        );

        final search = TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.searchByNameEmailOrId,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        );

        Widget chip(String label, bool on, VoidCallback onTap,
            {bool warn = false}) {
          return ChoiceChip(
            label: Text(label),
            selected: on,
            showCheckmark: false,
            onSelected: (_) => onTap(),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: on
                  ? cs.onInverseSurface
                  : (warn ? cs.error : cs.onSurface),
            ),
            selectedColor: cs.inverseSurface,
            backgroundColor: warn
                ? cs.errorContainer.withValues(alpha: 0.5)
                : cs.surfaceContainerHighest.withValues(alpha: 0.6),
            side: BorderSide.none,
            shape: const StadiumBorder(),
          );
        }

        final chips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('Aktivní ${active.length}', !_showArchived && !_onlyAttention,
                () => setState(() {
                      _showArchived = false;
                      _onlyAttention = false;
                    })),
            chip('Pozornost ${attention.length}',
                !_showArchived && _onlyAttention,
                () => setState(() {
                      _showArchived = false;
                      _onlyAttention = true;
                    }),
                warn: attention.isNotEmpty),
            chip('Archiv ${archived.length}', _showArchived,
                () => setState(() {
                      _showArchived = true;
                      _onlyAttention = false;
                    })),
          ],
        );

        Widget row(ClientPulse p) {
          final isSel = wide && selected?.client.clientId == p.client.clientId;
          final urgent = p.alerts.any((a) => a.severity >= 2);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: isSel
                  ? cs.primaryContainer.withValues(alpha: 0.7)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _open(p, wide: wide),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                  child: Row(
                    children: [
                      ClientAvatar(client: p.client),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.client.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.client.isArchived
                                  ? 'V archivu · ${p.client.clientId}'
                                  : (urgent
                                      ? p.alerts
                                          .firstWhere((a) => a.severity >= 2)
                                          .text
                                      : p.statusLine),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    urgent ? FontWeight.w700 : FontWeight.w500,
                                color: urgent ? cs.error : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (p.client.isArchived)
                        TextButton(
                          onPressed: () => _restoreArchivedClient(p.data),
                          child: const Text('Obnovit'),
                        )
                      else ...[
                        ScoreRing(score: p.score, size: 40),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) async {
                            if (value == 'archive') await _archiveClient(p.data);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem<String>(
                              value: 'archive',
                              child: Text('Přesunout do archivu'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final emptyText = q.isNotEmpty
            ? 'Nic nenalezeno.'
            : _showArchived
                ? l10n.archiveHasNoClients
                : _onlyAttention
                    ? 'Nikdo teď pozornost nepotřebuje.'
                    : l10n.noActiveClientsYet;

        final listPane = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: header,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: search,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: chips,
            ),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emptyText, textAlign: TextAlign.center),
                            if (!_showArchived &&
                                !_onlyAttention &&
                                q.isEmpty) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _addClient(active.length),
                                icon: const Icon(Icons.person_add_alt_1),
                                label: Text(l10n.addClient),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                      children: [for (final p in shown) row(p)],
                    ),
            ),
          ],
        );

        if (!wide) {
          return Scaffold(body: SafeArea(child: listPane));
        }

        final sel = selected;
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 350,
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    right: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: SafeArea(right: false, child: listPane),
              ),
              Expanded(
                child: sel == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                size: 56, color: cs.outline),
                            const SizedBox(height: 10),
                            Text(
                              'Vyber klienta ze seznamu',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ClientDetailScreen(
                        key: ValueKey(sel.client.clientId),
                        client: sel.client,
                        embedded: true,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
