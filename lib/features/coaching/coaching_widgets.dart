import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_client.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/coach/app_role_provider.dart';
import '../../providers/coach/coach_circumference_controller.dart';
import '../../providers/coach/coach_client_details_controller.dart';
import '../../providers/coach/coach_clients_controller.dart';
import '../../providers/coach/coach_diagnostic_controller.dart';
import '../../providers/coach/coach_goal_controller.dart';
import '../../providers/coach/coach_inbody_controller.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../providers/daily_history_provider.dart';
import '../../providers/daily_intake_provider.dart';
import '../../providers/performance_provider.dart';
import '../../providers/training_session_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/coach/online_coaching_service.dart';
import '../../services/pdf/pdf_author.dart';
import 'workout_widgets.dart';

// =====================================================================
// Obnova dat po synchronizaci + pravidelná synchronizace
// =====================================================================

/// Obalí aplikaci: po synchronizaci s trenérem / klientem načte data
/// znovu a každé 2 minuty se zeptá cloudu na novinky.
class CoachingSyncListener extends ConsumerStatefulWidget {
  final Widget child;
  const CoachingSyncListener({super.key, required this.child});

  @override
  ConsumerState<CoachingSyncListener> createState() =>
      _CoachingSyncListenerState();
}

class _CoachingSyncListenerState extends ConsumerState<CoachingSyncListener>
    with WidgetsBindingObserver {
  Timer? _periodic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    OnlineCoachingService.revision.addListener(_reload);
    OnlineCoachingService.scheduleSync(delay: const Duration(seconds: 4));
    _periodic = Timer.periodic(
      const Duration(minutes: 2),
      (_) {
        OnlineCoachingService.syncNow();
        if (mounted) ref.invalidate(myWorkoutsProvider);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Návrat do aplikace → hned stáhnout novinky.
    if (state == AppLifecycleState.resumed) {
      OnlineCoachingService.scheduleSync(delay: const Duration(seconds: 1));
    }
  }

  void _reload() {
    if (!mounted) return;
    ref.invalidate(coachClientsControllerProvider);
    ref.invalidate(coachInbodyControllerProvider);
    ref.invalidate(coachCircumferenceControllerProvider);
    ref.invalidate(coachGoalControllerProvider);
    ref.invalidate(coachDiagnosticControllerProvider);
    ref.invalidate(coachClientDetailsControllerProvider);
    ref.invalidate(trainingSessionProvider);
    ref.invalidate(dailyHistoryProvider);
    ref.invalidate(dailyIntakeProvider);
    ref.invalidate(performanceProvider);
    ref.invalidate(customTrainingPlanProvider);
    ref.invalidate(clientLinkProvider);
    ref.invalidate(myWorkoutsProvider);
    final cid = ref.read(userProfileProvider)?.clientId;
    if (cid != null && cid.isNotEmpty) {
      ref.read(userProfileProvider.notifier).switchToClient(cid);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OnlineCoachingService.revision.removeListener(_reload);
    _periodic?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// =====================================================================
// TRENÉR – karta „Online coaching“ v detailu klienta
// =====================================================================

class CoachingInviteCard extends StatefulWidget {
  final CoachClient client;
  const CoachingInviteCard({super.key, required this.client});

  @override
  State<CoachingInviteCard> createState() => _CoachingInviteCardState();
}

class _CoachingInviteCardState extends State<CoachingInviteCard> {
  CoachingLink? _link;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await OnlineCoachingService.loadLink(widget.client.clientId);
      if (!mounted) return;
      setState(() {
        _link = l;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      final text = e.toString();
      setState(() {
        _loading = false;
        _error = text.contains('permission-denied')
            ? 'Cloud odmítl přístup – ve Firebase ještě nejsou publikovaná '
                'nová pravidla (Firestore → Pravidla).'
            : 'Nepodařilo se načíst stav: $text';
      });
    }
  }

  String _inviteText(String code, String? coach) =>
      'Ahoj ${widget.client.firstName}! Tvůj trénink a jídelníček teď '
      'najdeš v aplikaci Chytrý trenér${coach == null ? '' : ' od $coach'}.\n'
      '1) Stáhni si aplikaci Chytrý trenér\n'
      '2) Na úvodní obrazovce zvol „Mám pozvánku od trenéra“\n'
      '3) Zadej kód: $code';

  Future<void> _invite() async {
    setState(() => _busy = true);
    try {
      final coach = await PdfAuthor.load();
      final code = await OnlineCoachingService.createInvite(
        clientId: widget.client.clientId,
        clientName: widget.client.displayName,
        coachName: coach,
      );
      await _load();
      if (!mounted) return;
      await _showCode(code, coach);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pozvánku se nepodařilo vytvořit: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCode(String code, String? coach) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pozvánka pro klienta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kód pro připojení:'),
            const SizedBox(height: 8),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Klient si stáhne aplikaci, zvolí „Mám pozvánku od trenéra“ '
              'a zadá kód. Kód platí jen pro tohoto klienta a jde použít '
              'jednou.',
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: _inviteText(code, coach)));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Zpráva s pozvánkou zkopírována – vlož '
                        'ji klientovi do WhatsAppu / SMS.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Kopírovat zprávu'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hotovo'),
          ),
        ],
      ),
    );
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    await OnlineCoachingService.syncNow();
    if (!mounted) return;
    setState(() => _busy = false);
    final err = OnlineCoachingService.lastError.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Synchronizováno.')),
    );
  }

  Future<void> _unlink() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ukončit online coaching?'),
        content: Text(
          '${widget.client.firstName} ztratí přístup ke sdíleným datům '
          'a plánům. Data u tebe v aplikaci zůstanou.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ukončit'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await OnlineCoachingService.unlink(widget.client.clientId);
    } finally {
      await _load();
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime d) => '${d.day}. ${d.month}. ${d.year}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final link = _link;

    Widget body;
    if (_loading) {
      body = const LinearProgressIndicator();
    } else if (_error != null) {
      body = Text(_error!, style: TextStyle(color: cs.error));
    } else if (link == null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pošli klientovi pozvánku do aplikace. Uvidí svůj trénink, '
            'jídelníček a pokrok, bude zapisovat jídlo a tréninky a ty to '
            'hned uvidíš tady.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _invite,
            icon: const Icon(Icons.send_to_mobile_outlined),
            label: const Text('Pozvat klienta do aplikace'),
          ),
        ],
      );
    } else if (!link.isConnected) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top, color: cs.tertiary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Pozvánka odeslaná – čeká se na připojení.'),
              ),
            ],
          ),
          if (link.inviteCode != null) ...[
            const SizedBox(height: 6),
            SelectableText(
              'Kód: ${OnlineCoachingService.formatCode(link.inviteCode!)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy || link.inviteCode == null
                    ? null
                    : () async => _showCode(
                          OnlineCoachingService.formatCode(link.inviteCode!),
                          link.coachName,
                        ),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Zobrazit pozvánku'),
              ),
              TextButton(
                onPressed: _busy ? null : _invite,
                child: const Text('Nový kód'),
              ),
              TextButton(
                onPressed: _busy ? null : _unlink,
                child: const Text('Zrušit pozvánku'),
              ),
            ],
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  link.joinedAt == null
                      ? 'Připojeno'
                      : 'Připojeno od ${_date(link.joinedAt!)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Plány, jídelníček a změny se klientovi posílají samy. '
            'Jeho jídlo, tréninky a váhu tu vidíš do pár minut.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _sync,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: const Text('Synchronizovat teď'),
              ),
              TextButton(
                onPressed: _busy ? null : _unlink,
                child: const Text('Ukončit coaching'),
              ),
            ],
          ),
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phonelink_ring_outlined, color: cs.primary),
                const SizedBox(width: 10),
                const Text(
                  'Online coaching',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            body,
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// KLIENT – připojení kódem
// =====================================================================

class JoinCoachScreen extends ConsumerStatefulWidget {
  const JoinCoachScreen({super.key});

  @override
  ConsumerState<JoinCoachScreen> createState() => _JoinCoachScreenState();
}

class _JoinCoachScreenState extends ConsumerState<JoinCoachScreen> {
  final _ctrl = TextEditingController();
  bool _consent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final (info, error) = await OnlineCoachingService.joinWithCode(_ctrl.text);
    if (!mounted) return;
    if (info == null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    await ref.read(activeClientIdProvider.notifier).setActive(info.clientId);
    await ref.read(userProfileProvider.notifier).switchToClient(info.clientId);
    OnlineCoachingService.revision.value++;
    await ref.read(appRoleProvider.notifier).setRole(AppRole.user);
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Připojení k trenérovi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Icon(Icons.phonelink_ring_outlined, size: 56, color: cs.primary),
              const SizedBox(height: 12),
              const Text(
                'Zadej kód od svého trenéra',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Po připojení uvidíš svůj trénink a jídelníček a trenér uvidí, '
                'co zapíšeš.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Kód',
                  hintText: 'KL-XXXX-XXXX',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _consent,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _consent = v ?? false),
                title: const Text(
                  'Souhlasím, že můj trenér uvidí údaje, které v aplikaci '
                  'zapíšu (jídlo, tréninky, váha, měření), a že se kvůli tomu '
                  'ukládají v cloudu. Souhlas můžu kdykoli odvolat odpojením.',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ||
                        !_consent ||
                        _ctrl.text.trim().length < 8
                    ? null
                    : _join,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: const Text('Připojit se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// KLIENT – karta v profilu
// =====================================================================

class ClientCoachCard extends StatefulWidget {
  const ClientCoachCard({super.key});

  @override
  State<ClientCoachCard> createState() => _ClientCoachCardState();
}

class _ClientCoachCardState extends State<ClientCoachCard> {
  ClientLinkInfo? _info;
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    OnlineCoachingService.localClientLink().then((v) {
      if (mounted) {
        setState(() {
          _info = v;
          _loaded = true;
        });
      }
    });
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    await OnlineCoachingService.syncNow();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            OnlineCoachingService.lastError.value ?? 'Synchronizováno.'),
      ),
    );
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odpojit se od trenéra?'),
        content: const Text(
          'Trenér už neuvidí nové zápisy a ty nedostaneš nové plány. '
          'Data v telefonu ti zůstanou.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Odpojit'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await OnlineCoachingService.leave();
    OnlineCoachingService.revision.value++;
    if (mounted) setState(() => _info = null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final info = _info;
    if (info == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.phonelink_ring_outlined),
          title: const Text('Mám pozvánku od trenéra'),
          subtitle: const Text('Připoj se ke svému trenérovi kódem'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const JoinCoachScreen()),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.coachName == null
                        ? 'Propojeno s trenérem'
                        : 'Tvůj trenér: ${info.coachName}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<String?>(
              valueListenable: OnlineCoachingService.lastError,
              builder: (context, err, _) => err == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        err,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _sync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Synchronizovat'),
                ),
                TextButton(
                  onPressed: _busy ? null : _leave,
                  child: const Text('Odpojit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
