import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_client.dart';
import '../../services/coach/coaching_chat_service.dart';
import '../../services/coach/online_coaching_service.dart';
import '../help/help_button.dart';
import 'workout_widgets.dart';

/// Konverzace trenér ↔ klient.
class CoachingChatScreen extends StatefulWidget {
  final String linkId;
  final bool asCoach;
  final String title;

  const CoachingChatScreen({
    super.key,
    required this.linkId,
    required this.asCoach,
    required this.title,
  });

  @override
  State<CoachingChatScreen> createState() => _CoachingChatScreenState();
}

class _CoachingChatScreenState extends State<CoachingChatScreen> {
  final _ctrl = TextEditingController();
  late final Stream<List<ChatMessage>> _stream;
  bool _sending = false;
  Timer? _readTimer;

  @override
  void initState() {
    super.initState();
    _stream = CoachingChatService.watch(widget.linkId);
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _scheduleMarkRead() {
    _readTimer?.cancel();
    _readTimer = Timer(const Duration(milliseconds: 600), () {
      CoachingChatService.markRead(widget.linkId, asCoach: widget.asCoach);
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await CoachingChatService.send(
        widget.linkId,
        text,
        fromCoach: widget.asCoach,
      );
      _ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zprávu se nepodařilo odeslat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  static String _day(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Dnes';
    if (diff == 1) return 'Včera';
    return '${d.day}. ${d.month}. ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [HelpButton(topic: 'chat')],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Zprávy se nepodařilo načíst. Zkontroluj připojení '
                        'k internetu.\n\n${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data!;
                if (msgs.any((m) => m.fromCoach != widget.asCoach && !m.read)) {
                  _scheduleMarkRead();
                }
                if (msgs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.asCoach
                            ? 'Zatím žádné zprávy. Napiš klientovi první.'
                            : 'Zatím žádné zprávy. Napiš trenérovi, jak se máš '
                                'nebo na co se chceš zeptat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = m.fromCoach == widget.asCoach;
                    final older = i + 1 < msgs.length ? msgs[i + 1] : null;
                    final showDay =
                        older == null || _day(older.at) != _day(m.at);
                    return Column(
                      children: [
                        if (showDay)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _day(m.at),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                              decoration: BoxDecoration(
                                color: mine
                                    ? cs.primary
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(mine ? 16 : 4),
                                  bottomRight: Radius.circular(mine ? 4 : 16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SelectableText(
                                    m.text,
                                    style: TextStyle(
                                      color: mine ? cs.onPrimary : cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _time(m.at),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: mine
                                              ? cs.onPrimary
                                                  .withValues(alpha: 0.8)
                                              : cs.onSurfaceVariant,
                                        ),
                                      ),
                                      if (mine) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          m.read ? Icons.done_all : Icons.done,
                                          size: 13,
                                          color: cs.onPrimary
                                              .withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: CoachingChatService.maxLength,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Napiš zprávu…',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Odeslat',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Propojení trenéra s tímto klientem (null = klient nemá online koučink).
final coachLinkForClientProvider =
    FutureProvider.autoDispose.family<CoachingLink?, String>((ref, clientId) {
  return OnlineCoachingService.loadLink(clientId);
});

/// Tlačítko „Zprávy“ v detailu klienta (jen u online klientů).
class CoachChatButton extends ConsumerWidget {
  final CoachClient client;
  const CoachChatButton({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(coachLinkForClientProvider(client.clientId)).valueOrNull;
    if (link == null || link.clientUid == null) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: CoachingChatService.watchUnread(link.linkId, asCoach: true),
      builder: (context, snap) {
        final n = snap.data ?? 0;
        return IconButton(
          tooltip: 'Zprávy s klientem',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CoachingChatScreen(
                linkId: link.linkId,
                asCoach: true,
                title: client.displayName,
              ),
            ),
          ),
          icon: Badge(
            isLabelVisible: n > 0,
            label: Text('$n'),
            child: const Icon(Icons.chat_bubble_outline),
          ),
        );
      },
    );
  }
}

/// Karta na obrazovce Dnes u klienta s online koučinkem.
class ClientMessagesTile extends ConsumerWidget {
  const ClientMessagesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(clientLinkProvider).valueOrNull;
    if (link == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final coach = (link.coachName ?? '').trim();

    void open() => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoachingChatScreen(
              linkId: link.linkId,
              asCoach: false,
              title: coach.isEmpty ? 'Trenér' : coach,
            ),
          ),
        );

    return StreamBuilder<int>(
      stream: CoachingChatService.watchUnread(link.linkId, asCoach: false),
      builder: (context, snap) {
        final n = snap.data ?? 0;
        return Card(
          color: n > 0 ? cs.primaryContainer : null,
          child: ListTile(
            leading: Badge(
              isLabelVisible: n > 0,
              label: Text('$n'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            title: Text(
              n > 0
                  ? (n == 1
                      ? 'Nová zpráva od trenéra'
                      : 'Nové zprávy od trenéra ($n)')
                  : 'Zprávy s trenérem',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              n > 0 ? 'Klepni a přečti si ji' : 'Napiš trenérovi, jak se máš',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: open,
          ),
        );
      },
    );
  }
}
