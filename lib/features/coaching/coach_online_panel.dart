import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/coach/checkin_service.dart';
import '../../services/coach/coaching_chat_service.dart';
import '../../services/coach/online_coaching_service.dart';
import '../../services/coach/workout_assignment_service.dart';
import '../help/help_button.dart';
import 'chat_screen.dart';

/// Stav jednoho online klienta pro přehled trenéra.
class OnlineClientStatus {
  final CoachingLink link;
  final int unread;
  final int missed;
  final int upcoming;
  final bool todayAssigned;
  final bool todayDone;
  final DateTime? lastDone;

  /// Klient už přes týden neposlal check-in.
  final bool checkInDue;

  const OnlineClientStatus({
    required this.link,
    required this.unread,
    required this.missed,
    required this.upcoming,
    required this.todayAssigned,
    required this.todayDone,
    required this.lastDone,
    required this.checkInDue,
  });

  /// Něco vyžaduje reakci trenéra.
  bool get needsAction =>
      unread > 0 || missed > 0 || upcoming == 0 || checkInDue;
}

final coachOnlineOverviewProvider =
    FutureProvider.autoDispose<List<OnlineClientStatus>>((ref) async {
  final links = [
    for (final l in await OnlineCoachingService.coachLinks())
      if (l.isConnected) l,
  ];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  Future<OnlineClientStatus> load(CoachingLink l) async {
    List<WorkoutAssignment> ws = const [];
    try {
      ws = await WorkoutAssignmentService.listForClient(l.clientId);
    } catch (_) {}
    final unread = await CoachingChatService.unread(l.linkId, asCoach: true);
    var checkInDue = false;
    try {
      checkInDue =
          CheckInService.isDue(await CheckInService.listForLink(l.linkId));
    } catch (_) {}
    DateTime d(DateTime x) => DateTime(x.year, x.month, x.day);
    final todays = ws.where((w) => d(w.date) == today).toList();
    final done = ws.where((w) => w.status == 'done').toList()
      ..sort((a, b) => (b.completedAt ?? b.date).compareTo(a.completedAt ?? a.date));
    return OnlineClientStatus(
      link: l,
      unread: unread,
      missed: ws
          .where((w) => w.status != 'done' && d(w.date).isBefore(today))
          .length,
      upcoming: ws
          .where((w) => w.status != 'done' && !d(w.date).isBefore(today))
          .length,
      todayAssigned: todays.isNotEmpty,
      todayDone: todays.isNotEmpty && todays.every((w) => w.status == 'done'),
      lastDone: done.isEmpty ? null : (done.first.completedAt ?? done.first.date),
      checkInDue: checkInDue,
    );
  }

  final list = await Future.wait(links.map(load));
  list.sort((a, b) {
    if (a.needsAction != b.needsAction) return a.needsAction ? -1 : 1;
    return a.link.clientName.compareTo(b.link.clientName);
  });
  return list;
});

/// Přehled online klientů na úvodní obrazovce trenéra: nové zprávy,
/// dnešní trénink, neodcvičené tréninky, komu chybí plán.
class OnlineClientsCard extends ConsumerWidget {
  /// Otevře detail klienta podle jeho ID.
  final ValueChanged<String> onOpenClient;

  const OnlineClientsCard({super.key, required this.onOpenClient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coachOnlineOverviewProvider);
    final list = async.valueOrNull;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final attention = list.where((s) => s.needsAction).length;

    Widget chip(String text, Color bg, Color fg, IconData icon) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(text, style: TextStyle(fontSize: 12, color: fg)),
            ],
          ),
        );

    String ago(DateTime d) {
      final days = DateTime.now().difference(d).inDays;
      if (days <= 0) return 'dnes';
      if (days == 1) return 'včera';
      return 'před $days dny';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_tethering, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attention > 0
                        ? 'Online klienti · $attention k řešení'
                        : 'Online klienti',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const HelpButton(topic: 'online'),
                IconButton(
                  tooltip: 'Obnovit',
                  onPressed: () => ref.invalidate(coachOnlineOverviewProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            for (final s in list)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onOpenClient(s.link.clientId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.link.clientName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (s.unread > 0)
                                  chip(
                                    s.unread == 1
                                        ? '1 nová zpráva'
                                        : '${s.unread} nové zprávy',
                                    cs.primaryContainer,
                                    cs.onPrimaryContainer,
                                    Icons.mark_chat_unread_outlined,
                                  ),
                                if (s.todayAssigned)
                                  s.todayDone
                                      ? chip('Dnes odcvičeno',
                                          Colors.green.shade100,
                                          Colors.green.shade900,
                                          Icons.check_circle_outline)
                                      : chip('Dnes čeká trénink',
                                          cs.surfaceContainerHighest,
                                          cs.onSurface,
                                          Icons.schedule),
                                if (s.missed > 0)
                                  chip('Neodcvičeno: ${s.missed}',
                                      cs.errorContainer,
                                      cs.onErrorContainer,
                                      Icons.error_outline),
                                if (s.upcoming == 0)
                                  chip('Nemá naplánovaný trénink',
                                      Colors.orange.shade100,
                                      Colors.orange.shade900,
                                      Icons.event_busy_outlined),
                                if (s.checkInDue)
                                  chip('Check-in chybí',
                                      Colors.orange.shade100,
                                      Colors.orange.shade900,
                                      Icons.fact_check_outlined),
                                if (s.lastDone != null)
                                  chip('Naposledy ${ago(s.lastDone!)}',
                                      cs.surfaceContainerHighest,
                                      cs.onSurfaceVariant,
                                      Icons.history),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zprávy',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoachingChatScreen(
                                linkId: s.link.linkId,
                                asCoach: true,
                                title: s.link.clientName,
                              ),
                            ),
                          );
                          ref.invalidate(coachOnlineOverviewProvider);
                        },
                        icon: Badge(
                          isLabelVisible: s.unread > 0,
                          label: Text('${s.unread}'),
                          child: const Icon(Icons.chat_bubble_outline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
