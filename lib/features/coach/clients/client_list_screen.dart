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
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  Future<void> _setActiveClient(String clientId) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    await ref.read(activeClientIdProvider.notifier).setActive(clientId);

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Aktivní klient nastaven: $clientId'),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Future<void> _copyEmails(List<CoachClientWithStats> clients) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final rawClients = clients.map((e) => e.client).toList();

    final emailsText = ClientsExportService.buildEmailsString(rawClients);
    if (emailsText.trim().isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Žádný klient zatím nemá vyplněný email.'),
          backgroundColor: colorScheme.tertiary,
        ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: emailsText));

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Emaily byly zkopírovány do schránky.'),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Future<void> _exportCsv(List<CoachClientWithStats> clients) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final rawClients = clients.map((e) => e.client).toList();

    final path = await ClientsExportService.exportClientsCsv(rawClients);

    if (!mounted) return;

    if (path == null) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Export CSV byl zrušen.'),
          backgroundColor: colorScheme.tertiary,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text('CSV bylo uloženo: $path'),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Future<void> _exportPdf(List<CoachClientWithStats> clients) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final rawClients = clients.map((e) => e.client).toList();

    await ClientsExportService.exportClientsPdf(rawClients);

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('PDF export byl otevřen pro tisk / uložení.'),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Future<void> _importClientFromJsonFile() async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

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
      final preview = await service.previewClientImportFromJsonFile(file.path);

      if (!mounted) return;
      final mode = await _showImportPreviewDialog(preview);
      if (mode == null) return;

      await service.importClientFromJsonFile(
        file.path,
        ref,
        mode: mode,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            preview.conflictExists
                ? 'Klient "${preview.clientDisplayName}" byl importován jako nový klient.'
                : 'Klient "${preview.clientDisplayName}" byl úspěšně importován.',
          ),
          backgroundColor: colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import ze souboru selhal: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  Future<void> _restoreClientFromArchiveFolder() async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final folderPath = await getDirectoryPath(
        confirmButtonText: 'Vybrat archivní složku',
      );

      if (folderPath == null || folderPath.trim().isEmpty) return;

      final service = const ClientImportService();
      final preview = await service.previewClientImportFromArchiveFolder(
        folderPath,
      );

      if (!mounted) return;
      final mode = await _showImportPreviewDialog(preview);
      if (mode == null) return;

      await service.importClientFromArchiveFolder(
        folderPath,
        ref,
        mode: mode,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            preview.conflictExists
                ? 'Klient "${preview.clientDisplayName}" byl obnoven jako nový klient.'
                : 'Klient "${preview.clientDisplayName}" byl úspěšně obnoven z archivu.',
          ),
          backgroundColor: colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Obnova z archivní složky selhala: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  Future<ClientImportMode?> _showImportPreviewDialog(
    ClientImportPreview preview,
  ) {
    String fmtDate(DateTime? d) {
      if (d == null) return '—';
      return '${d.day.toString().padLeft(2, '0')}.'
          '${d.month.toString().padLeft(2, '0')}.'
          '${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }

    Widget labeledPreviewRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );
    }

    return showDialog<ClientImportMode?>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Náhled před importem'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  labeledPreviewRow('Zdroj', preview.sourceLabel),
                  labeledPreviewRow('Klient', preview.clientDisplayName),
                  labeledPreviewRow('Původní ID', preview.originalClientId),
                  labeledPreviewRow('Exportováno', fmtDate(preview.exportedAt)),
                  labeledPreviewRow('Cesta', preview.sourcePath),
                  const SizedBox(height: 12),
                  const Text(
                    'Obsah archivu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  labeledPreviewRow('Poznámky', '${preview.notesCount}'),
                  labeledPreviewRow('InBody', '${preview.inbodyCount}'),
                  labeledPreviewRow('Obvody', '${preview.circumferencesCount}'),
                  labeledPreviewRow('Výkony', '${preview.performancesCount}'),
                  labeledPreviewRow('Plány', '${preview.customPlansCount}'),
                  labeledPreviewRow('Sessions', '${preview.sessionsCount}'),
                  if (preview.conflictExists) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detekován konflikt klienta',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'V systému už existuje klient se stejným ID: '
                            '${preview.originalClientId}'
                            '${preview.conflictingClientDisplayName == null ? '' : ' (${preview.conflictingClientDisplayName})'}.',
                            style: TextStyle(
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'V této bezpečné verzi se import při konfliktu provede pouze jako nový klient s novým import ID.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Zrušit'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(
                ClientImportMode.importAsNewIfConflict,
              ),
              icon: const Icon(Icons.download),
              label: Text(
                preview.conflictExists
                    ? 'Importovat jako nový klient'
                    : 'Potvrdit import',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final clientsAsync = ref.watch(coachClientsControllerProvider);

    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Chyba: $e')),
      data: (clients) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Autocomplete<CoachClientWithStats>(
                    optionsBuilder: (text) {
                      final q = text.text.trim().toLowerCase();
                      if (q.isEmpty) {
                        return const Iterable<CoachClientWithStats>.empty();
                      }

                      return clients.where(
                        (c) =>
                            c.client.displayName.toLowerCase().contains(q) ||
                            c.client.clientId.toLowerCase().contains(q) ||
                            c.client.email.toLowerCase().contains(q),
                      );
                    },
                    displayStringForOption: (c) => c.client.displayName,
                    onSelected: (selected) async {
                      final navigator = Navigator.of(context);

                      await _setActiveClient(selected.client.clientId);
                      if (!mounted) return;

                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ClientDetailScreen(client: selected.client),
                        ),
                      );
                    },
                    fieldViewBuilder:
                        (context, ctrl, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: ctrl,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Hledej jméno, email nebo ID…',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              clients.isEmpty ? null : () => _copyEmails(clients),
                          icon: const Icon(Icons.copy),
                          label: const Text('Kopírovat emaily'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              clients.isEmpty ? null : () => _exportCsv(clients),
                          icon: const Icon(Icons.table_view),
                          label: const Text('Export CSV'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              clients.isEmpty ? null : () => _exportPdf(clients),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _importClientFromJsonFile,
                          icon: const Icon(Icons.description),
                          label: const Text('Import JSON'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _restoreClientFromArchiveFolder,
                          icon: const Icon(Icons.restore),
                          label: const Text('Obnovit z archivu'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: clients.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: colorScheme.outlineVariant,
                      ),
                      itemBuilder: (context, i) {
                        final c = clients[i];
                        final name = c.client.displayName;
                        final email = c.client.email.trim();

                        final tileColor = c.isInactive7d
                            ? colorScheme.errorContainer.withValues(alpha: 0.45)
                            : null;

                        final titleColor = c.isInactive7d
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSurface;

                        final subtitleColor = c.isInactive7d
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSurfaceVariant;

                        return Container(
                          decoration: BoxDecoration(
                            color: tileColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            title: Text(
                              '$name (${c.client.clientId})',
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Odcvičeno za 7 dní: ${c.completedDaysInLast7}/7 • '
                                  'Věk: ${c.client.age}, ${c.client.heightCm} cm'
                                  '${c.client.isEatingDisorderSupport ? '' : ', ${c.client.weightKg.toStringAsFixed(1)} kg'}',
                                  style: TextStyle(
                                    color: subtitleColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email.isEmpty ? 'Email: —' : 'Email: $email',
                                  style: TextStyle(
                                    color: subtitleColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (c.isInactive7d)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.error,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'NECVIČIL 7+ DNÍ',
                                          style: TextStyle(
                                            color: colorScheme.onError,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (c.client.isEatingDisorderSupport) ...[
                                      if (c.isInactive7d) const SizedBox(width: 8),
                                      Icon(
                                        Icons.shield,
                                        color: c.isInactive7d
                                            ? colorScheme.onErrorContainer
                                            : colorScheme.tertiary,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: subtitleColor,
                            ),
                            onTap: () async {
                              final navigator = Navigator.of(context);

                              await _setActiveClient(c.client.clientId);
                              if (!mounted) return;

                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClientDetailScreen(client: c.client),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.person_add),
                label: const Text('Přidat klienta'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddClientScreen()),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}