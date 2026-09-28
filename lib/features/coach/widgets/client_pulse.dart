import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/coach/coach_client.dart';
import '../../../models/coach/coach_inbody_entry.dart';
import '../../../providers/coach/coach_clients_controller.dart';

/// Důvod, proč klient potřebuje pozornost.
class ClientAlert {
  final CoachClient client;
  final IconData icon;
  final String text;

  /// 2 = důležité, 1 = připomínka.
  final int severity;

  const ClientAlert(this.client, this.icon, this.text, this.severity);
}

/// Stav klienta pro přehledy: skóre aktivity a upozornění.
class ClientPulse {
  final CoachClientWithStats data;
  final CoachInbodyEntry? lastInbody;
  final int score;
  final List<ClientAlert> alerts;

  const ClientPulse(this.data, this.lastInbody, this.score, this.alerts);

  CoachClient get client => data.client;
  bool get needsAttention => alerts.isNotEmpty;

  /// Poslední InBody každého klienta.
  static Map<String, CoachInbodyEntry> lastInbodyByClient(
    Iterable<CoachInbodyEntry> all,
  ) {
    final map = <String, CoachInbodyEntry>{};
    for (final e in all) {
      if (e.isDeleted) continue;
      final prev = map[e.clientId];
      if (prev == null || e.date.isAfter(prev.date)) map[e.clientId] = e;
    }
    return map;
  }

  static ClientPulse of(CoachClientWithStats d, CoachInbodyEntry? inbody) {
    final now = DateTime.now();
    final last = d.lastSessionAt;
    final daysSince = last == null ? null : now.difference(last).inDays;
    final inbodyDays =
        inbody == null ? null : now.difference(inbody.date).inDays;

    // Skóre aktivity 0–100:
    // 60 % tréninky za posledních 7 dní (cíl 3×),
    // 20 % jak dávno byl poslední trénink,
    // 20 % jak čerstvé je měření InBody.
    final training = math.min(d.completedDaysInLast7 / 3.0, 1.0);
    final recency = daysSince == null
        ? 0.0
        : (1 - ((daysSince - 3).clamp(0, 11) / 11)).toDouble();
    final measure = inbodyDays == null
        ? 0.0
        : (1 - ((inbodyDays - 35).clamp(0, 55) / 55)).toDouble();
    final score = (training * 60 + recency * 20 + measure * 20).round();

    final alerts = <ClientAlert>[];
    final c = d.client;
    if (!c.isArchived) {
      if (daysSince == null) {
        alerts.add(ClientAlert(
            c, Icons.fitness_center, 'zatím žádný zapsaný trénink', 1));
      } else if (daysSince > 7) {
        alerts.add(ClientAlert(c, Icons.directions_run,
            'necvičil/a $daysSince ${czDays(daysSince)}', 2));
      }
      if (inbodyDays == null) {
        alerts.add(ClientAlert(
            c, Icons.monitor_weight_outlined, 'ještě nemá měření InBody', 1));
      } else if (inbodyDays > 35) {
        alerts.add(ClientAlert(c, Icons.monitor_weight_outlined,
            '${inbodyDays ~/ 7} týdnů bez měření InBody', 1));
      }
    }
    return ClientPulse(d, inbody, score, alerts);
  }

  String get statusLine {
    final last = data.lastSessionAt;
    final n = data.completedDaysInLast7;
    final parts = <String>[];
    if (n > 0) parts.add('$n× tento týden');
    if (last == null) {
      parts.add('bez tréninku');
    } else {
      final days = DateTime.now().difference(last).inDays;
      parts.add(days == 0
          ? 'trénoval/a dnes'
          : days == 1
              ? 'naposledy včera'
              : 'naposledy před $days ${czDays(days)}');
    }
    return parts.join(' · ');
  }
}

String czDays(int n) => n == 1 ? 'den' : (n >= 2 && n <= 4 ? 'dny' : 'dní');

String clientInitials(CoachClient c) {
  final a = c.firstName.trim();
  final b = c.lastName.trim();
  final s = '${a.isEmpty || a == '—' ? '' : a[0]}'
      '${b.isEmpty || b == '—' ? '' : b[0]}';
  return s.isEmpty ? '?' : s.toUpperCase();
}

Color scoreColor(int score) {
  if (score >= 75) return const Color(0xFF16A34A);
  if (score >= 50) return const Color(0xFFF59E0B);
  return const Color(0xFFDC2626);
}

/// Kroužek se skóre aktivity klienta.
class ScoreRing extends StatelessWidget {
  final int score;
  final double size;

  const ScoreRing({super.key, required this.score, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Skóre aktivity: tréninky za týden, poslední trénink '
          'a čerstvost měření',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: size >= 56 ? 6 : 4.5,
                backgroundColor: cs.surfaceContainerHighest,
                color: scoreColor(score),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: size * 0.33,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kulatý avatar s iniciálami klienta.
class ClientAvatar extends StatelessWidget {
  final CoachClient client;
  final double radius;
  const ClientAvatar({super.key, required this.client, this.radius = 21});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      child: Text(
        clientInitials(client),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: radius * 0.7),
      ),
    );
  }
}

/// Tmavá karta „Potřebují pozornost“.
class AttentionCard extends StatelessWidget {
  final List<ClientAlert> alerts;
  final ValueChanged<CoachClient>? onOpen;
  final String title;
  final bool showNames;
  final String emptyText;

  const AttentionCard({
    super.key,
    required this.alerts,
    this.onOpen,
    this.title = 'POTŘEBUJÍ POZORNOST',
    this.showNames = true,
    this.emptyText = 'Všechno v pořádku – nikdo nevypadl z rytmu.',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? cs.surfaceContainerHighest : const Color(0xFF13171C);
    const fg = Colors.white;
    final shown = alerts.take(6).toList();
    final open = onOpen;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: shown.isEmpty
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFFF5A1F),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.75),
                    fontSize: 12,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Text(
                emptyText,
                style: TextStyle(color: fg.withValues(alpha: 0.85)),
              ),
            )
          else
            for (final a in shown)
              InkWell(
                onTap: open == null ? null : () => open(a.client),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        a.icon,
                        size: 18,
                        color: a.severity >= 2
                            ? const Color(0xFFFF8A5B)
                            : fg.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              if (showNames)
                                TextSpan(
                                  text: '${a.client.displayName} – ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              TextSpan(
                                text: showNames
                                    ? a.text
                                    : a.text[0].toUpperCase() +
                                        a.text.substring(1),
                                style: TextStyle(
                                    color: fg.withValues(alpha: 0.8)),
                              ),
                            ],
                          ),
                          style: const TextStyle(color: fg),
                        ),
                      ),
                      if (open != null)
                        Icon(Icons.chevron_right,
                            size: 18, color: fg.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
          if (alerts.length > shown.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'a další ${alerts.length - shown.length}',
                style: TextStyle(color: fg.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }
}
