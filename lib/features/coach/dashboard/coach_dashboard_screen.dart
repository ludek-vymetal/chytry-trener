import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/coach/coach_client.dart';
import '../../../providers/coach/active_client_provider.dart';
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
import '../../../providers/nav_provider.dart';
import '../../../providers/subscription/subscription_provider.dart';
import '../../../providers/training_session_provider.dart';
import '../../../services/coach/coach_cloud_sync_service.dart';
import '../../../services/local_storage_service.dart';
import '../../common/adaptive_shell.dart';
import '../../help/help_button.dart';
import '../widgets/client_pulse.dart';
import '../../paywall/paywall_screen.dart';
import '../clients/add_client_screen.dart';
import '../clients/add_inbody_entry_screen.dart';
import '../clients/client_detail_screen.dart';

// =================================================================
// Výpočty pro přehled
// =================================================================

const _weekdays = ['pondělí', 'úterý', 'středa', 'čtvrtek', 'pátek', 'sobota', 'neděle'];
const _months = [
  'ledna', 'února', 'března', 'dubna', 'května', 'června',
  'července', 'srpna', 'září', 'října', 'listopadu', 'prosince',
];

String _greeting(DateTime now) {
  if (now.hour < 10) return 'Dobré ráno';
  if (now.hour < 18) return 'Dobrý den';
  return 'Dobrý večer';
}

// =================================================================
// Obrazovka
// =================================================================

/// Přehled trenéra: klienti se skóre, kdo potřebuje pozornost,
/// aktivita za týden a záloha. Na počítači vpravo boční panel.
class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() =>
      _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  bool _syncBusy = false;
  bool _folderBusy = false;
  bool _onlyAttention = false;

  // ---------------------------------------------------------------
  // Akce
  // ---------------------------------------------------------------

  Future<void> _openClient(CoachClient client) async {
    await ref.read(activeClientIdProvider.notifier).setActive(client.clientId);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
    );
  }

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

  Future<void> _addInbody(List<ClientPulse> pulses) async {
    if (pulses.isEmpty) return;
    final client = pulses.length == 1
        ? pulses.first.client
        : await showModalBottomSheet<CoachClient>(
            context: context,
            showDragHandle: true,
            builder: (ctx) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Komu přidat měření?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  for (final p in pulses)
                    ListTile(
                      leading: CircleAvatar(child: Text(clientInitials(p.client))),
                      title: Text(p.client.displayName),
                      onTap: () => Navigator.pop(ctx, p.client),
                    ),
                ],
              ),
            ),
          );
    if (client == null || !mounted) return;
    await ref.read(activeClientIdProvider.notifier).setActive(client.clientId);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddInbodyEntryScreen(
          clientId: client.clientId,
          heightCm: client.heightCm,
        ),
      ),
    );
  }

  Future<void> _reloadCoachData() async {
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
    ref.invalidate(coachClientDetailsControllerProvider);
    await ref.read(coachClientsControllerProvider.notifier).reload();
    await ref.read(coachNotesControllerProvider.notifier).reload();
    await ref.read(coachInbodyControllerProvider.notifier).reload();
    await ref.read(coachCircumferenceControllerProvider.notifier).reload();
  }

  void _snack(String text, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 4),
        backgroundColor: error ? cs.error : cs.primary,
      ),
    );
  }

  Future<void> _pushToCloud() async {
    final l10n = AppLocalizations.of(context)!;
    if (_syncBusy) return;
    setState(() => _syncBusy = true);
    try {
      final report = await CoachCloudSyncService.safePushAllFromLocal();
      if (!mounted) return;
      _snack(
        report.success
            ? '${l10n.cloudBackupFinished}. ${report.processedKeys.length}'
            : '${l10n.cloudBackupFailed}: ${report.warnings.join(' | ')}',
        error: !report.success,
      );
    } catch (e) {
      if (mounted) _snack('${l10n.error}: $e', error: true);
    } finally {
      if (mounted) setState(() => _syncBusy = false);
    }
  }

  Future<void> _pullFromCloud() async {
    final l10n = AppLocalizations.of(context)!;
    if (_syncBusy) return;
    setState(() => _syncBusy = true);
    try {
      final report = await CoachCloudSyncService.safePullMergeToLocal();
      await _reloadCoachData();
      if (!mounted) return;
      _snack(
        report.success
            ? '${l10n.cloudRestoreFinished}. ${report.processedKeys.length}'
            : '${l10n.cloudRestoreFailed}: ${report.warnings.join(' | ')}',
        error: !report.success,
      );
    } catch (e) {
      if (mounted) _snack('${l10n.error}: $e', error: true);
    } finally {
      if (mounted) setState(() => _syncBusy = false);
    }
  }

  Future<void> _pickAndSaveExportFolder() async {
    final l10n = AppLocalizations.of(context)!;
    if (_folderBusy) return;
    setState(() => _folderBusy = true);
    try {
      final selectedPath =
          await getDirectoryPath(confirmButtonText: l10n.selectFolder);
      if (selectedPath == null || selectedPath.trim().isEmpty) return;
      final dir = Directory(selectedPath);
      if (!dir.existsSync()) await dir.create(recursive: true);
      await LocalStorageService.saveClientExportFolderPath(selectedPath.trim());
      await ref
          .read(coachSetupProvider.notifier)
          .updateExportFolderPath(selectedPath.trim());
      if (!mounted) return;
      _snack('${l10n.exportFolderSaved}\n${dir.path}');
    } catch (e) {
      if (mounted) _snack(l10n.folderPickFailed(e.toString()), error: true);
    } finally {
      if (mounted) setState(() => _folderBusy = false);
    }
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clientsAsync = ref.watch(coachClientsControllerProvider);
    final inbodyAll =
        ref.watch(coachInbodyControllerProvider).asData?.value ?? const [];
    final setup = ref.watch(coachSetupProvider).asData?.value;
    final coachName = setup?.firstName.trim() ?? '';
    final exportFolder = setup?.exportFolderPath.trim() ?? '';

    return Scaffold(
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${l10n.error}: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (all) {
          final lastInbody = ClientPulse.lastInbodyByClient(inbodyAll);

          final pulses = all
              .where((c) => !c.client.isArchived)
              .map((c) => ClientPulse.of(c, lastInbody[c.client.clientId]))
              .toList()
            ..sort((a, b) {
              if (a.needsAttention != b.needsAttention) {
                return a.needsAttention ? -1 : 1;
              }
              return a.score.compareTo(b.score);
            });

          final alerts = [for (final p in pulses) ...p.alerts]
            ..sort((a, b) => b.severity.compareTo(a.severity));
          final attentionCount = pulses.where((p) => p.needsAttention).length;
          final trainedThisWeek =
              pulses.where((p) => p.data.completedDaysInLast7 > 0).length;
          final avgScore = pulses.isEmpty
              ? 0
              : (pulses.map((p) => p.score).reduce((a, b) => a + b) /
                      pulses.length)
                  .round();

          final now = DateTime.now();
          final header = _Header(
            date: '${_weekdays[now.weekday - 1]} ${now.day}. ${_months[now.month - 1]}',
            greeting: coachName.isEmpty
                ? _greeting(now)
                : '${_greeting(now)}, $coachName',
            subtitle: pulses.isEmpty
                ? 'Začni přidáním prvního klienta.'
                : attentionCount == 0
                    ? 'Všichni klienti jsou v pohodě.'
                    : '$attentionCount ${attentionCount == 1 ? 'klient potřebuje' : attentionCount < 5 ? 'klienti potřebují' : 'klientů potřebuje'} pozornost.',
            onAdd: () => _addClient(pulses.length),
          );

          final kpis = _KpiRow(items: [
            _Kpi(Icons.people_alt_outlined, 'Aktivní klienti', '${pulses.length}', null),
            _Kpi(Icons.event_available_outlined, 'Trénovali tento týden',
                '$trainedThisWeek', pulses.isEmpty ? null : 'z ${pulses.length}'),
            _Kpi(Icons.speed_outlined, 'Průměrné skóre', '$avgScore', 'ze 100'),
            _Kpi(Icons.priority_high_rounded, 'Potřebují pozornost',
                '$attentionCount', null,
                highlight: attentionCount > 0),
          ]);

          final shown =
              _onlyAttention ? pulses.where((p) => p.needsAttention).toList() : pulses;

          final clientsCard = _ClientsCard(
            pulses: shown,
            total: pulses.length,
            attention: attentionCount,
            onlyAttention: _onlyAttention,
            onFilter: (v) => setState(() => _onlyAttention = v),
            onOpen: _openClient,
            onShowAll: () => ref.read(coachTabProvider.notifier).state = 1,
            onAdd: () => _addClient(pulses.length),
          );

          final attentionPanel = AttentionCard(alerts: alerts, onOpen: _openClient);
          final activity = _ActivityPanel(pulses: pulses);
          final quick = _QuickPanel(
            items: [
              _Quick(Icons.person_add_alt_1, 'Přidat klienta',
                  () => _addClient(pulses.length)),
              _Quick(Icons.monitor_weight_outlined, 'Přidat měření InBody',
                  pulses.isEmpty ? null : () => _addInbody(pulses)),
              _Quick(Icons.people_outline, 'Všichni klienti',
                  () => ref.read(coachTabProvider.notifier).state = 1),
              _Quick(Icons.settings_outlined, 'Nastavení a vzhled',
                  () => ref.read(coachTabProvider.notifier).state = 2),
            ],
          );
          final backup = _BackupPanel(
            exportFolder: exportFolder,
            syncBusy: _syncBusy,
            folderBusy: _folderBusy,
            onPush: _pushToCloud,
            onPull: _pullFromCloud,
            onFolder: _pickAndSaveExportFolder,
          );

          final withSide = SidePanelLayout.isWide(context);
          const gap = SizedBox(height: 16);

          final main = SafeArea(
            child: RefreshIndicator(
              onRefresh: _reloadCoachData,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    withSide ? 28 : 16, 12, withSide ? 28 : 16, 32),
                children: [
                  PageWidth(
                    maxWidth: 1000,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        gap,
                        kpis,
                        gap,
                        if (!withSide && alerts.isNotEmpty) ...[
                          attentionPanel,
                          gap,
                        ],
                        clientsCard,
                        if (!withSide) ...[
                          gap,
                          activity,
                          gap,
                          quick,
                          gap,
                          backup,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

          return SidePanelLayout(
            main: main,
            side: [
              attentionPanel,
              activity,
              quick,
              backup,
              const PlanStatusCard(),
            ],
          );
        },
      ),
    );
  }
}

// =================================================================
// Části obrazovky
// =================================================================

class _Header extends StatelessWidget {
  final String date;
  final String greeting;
  final String subtitle;
  final VoidCallback onAdd;

  const _Header({
    required this.date,
    required this.greeting,
    required this.subtitle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date[0].toUpperCase() + date.substring(1),
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const HelpButton(topic: 'start'),
        const SizedBox(width: 6),
        if (wide)
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Přidat klienta'),
          )
        else
          IconButton.filled(
            tooltip: 'Přidat klienta',
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1),
          ),
      ],
    );
  }
}

class _Kpi {
  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final bool highlight;
  const _Kpi(this.icon, this.label, this.value, this.suffix, {this.highlight = false});
}

class _KpiRow extends StatelessWidget {
  final List<_Kpi> items;
  const _KpiRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 640 ? 4 : 2;
      const spacing = 12.0;
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final k in items)
            SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: k.highlight ? cs.errorContainer : cs.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: k.highlight
                        ? Colors.transparent
                        : cs.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      k.icon,
                      size: 20,
                      color: k.highlight ? cs.onErrorContainer : cs.primary,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          k.value,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: k.highlight ? cs.onErrorContainer : cs.onSurface,
                          ),
                        ),
                        if (k.suffix != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            k.suffix!,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      k.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: k.highlight
                            ? cs.onErrorContainer
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _ClientsCard extends StatelessWidget {
  final List<ClientPulse> pulses;
  final int total;
  final int attention;
  final bool onlyAttention;
  final ValueChanged<bool> onFilter;
  final ValueChanged<CoachClient> onOpen;
  final VoidCallback onShowAll;
  final VoidCallback onAdd;

  const _ClientsCard({
    required this.pulses,
    required this.total,
    required this.attention,
    required this.onlyAttention,
    required this.onFilter,
    required this.onOpen,
    required this.onShowAll,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const maxRows = 8;
    final rows = pulses.take(maxRows).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Klienti',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: onShowAll,
                  child: const Text('Všichni klienti'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Všichni $total'),
                  selected: !onlyAttention,
                  onSelected: (_) => onFilter(false),
                ),
                ChoiceChip(
                  label: Text('Pozornost $attention'),
                  selected: onlyAttention,
                  onSelected: (_) => onFilter(true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.group_add_outlined, size: 44, color: cs.primary),
                    const SizedBox(height: 8),
                    const Text('Zatím tu nikdo není.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Přidat prvního klienta'),
                    ),
                  ],
                ),
              )
            else if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Nikdo teď pozornost nepotřebuje.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              )
            else
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
                _ClientRow(pulse: rows[i], onTap: () => onOpen(rows[i].client)),
              ],
            if (pulses.length > maxRows)
              TextButton(
                onPressed: onShowAll,
                child: Text('Zobrazit dalších ${pulses.length - maxRows}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final ClientPulse pulse;
  final VoidCallback onTap;
  const _ClientRow({required this.pulse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = pulse.client;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              child: Text(
                clientInitials(c),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      if (pulse.needsAttention) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.circle, size: 8, color: cs.error),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pulse.statusLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ScoreRing(score: pulse.score),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Kdo kolikrát trénoval za posledních 7 dní.
class _ActivityPanel extends StatelessWidget {
  final List<ClientPulse> pulses;
  const _ActivityPanel({required this.pulses});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = [...pulses]
      ..sort((a, b) =>
          b.data.completedDaysInLast7.compareTo(a.data.completedDaysInLast7));
    final rows = sorted.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SideTitle('Tréninky za 7 dní'),
            if (rows.isEmpty)
              Text('Zatím žádná data.', style: TextStyle(color: cs.onSurfaceVariant))
            else
              for (final p in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          p.client.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                child: Container(
                                  height: 10,
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  decoration: BoxDecoration(
                                    color: i < p.data.completedDaysInLast7
                                        ? cs.primary
                                        : cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${p.data.completedDaysInLast7}×',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
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

class _Quick {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Quick(this.icon, this.label, this.onTap);
}

class _QuickPanel extends StatelessWidget {
  final List<_Quick> items;
  const _QuickPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SideTitle('Rychlé akce'),
        for (final q in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                enabled: q.onTap != null,
                onTap: q.onTap,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(q.icon, size: 19, color: cs.onPrimaryContainer),
                ),
                title: Text(
                  q.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
      ],
    );
  }
}

class _BackupPanel extends StatelessWidget {
  final String exportFolder;
  final bool syncBusy;
  final bool folderBusy;
  final VoidCallback onPush;
  final VoidCallback onPull;
  final VoidCallback onFolder;

  const _BackupPanel({
    required this.exportFolder,
    required this.syncBusy,
    required this.folderBusy,
    required this.onPush,
    required this.onPull,
    required this.onFolder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SideTitle('Záloha a export'),
            Text(
              l10n.cloudBackupDescription,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: syncBusy ? null : onPush,
              icon: syncBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(l10n.backupToCloud),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: syncBusy ? null : onPull,
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(l10n.restoreFromCloud),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.openExportFolder,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              exportFolder.isEmpty ? l10n.exportFolderNotConfigured : exportFolder,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: folderBusy ? null : onFolder,
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(l10n.change),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
