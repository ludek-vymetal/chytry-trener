import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/coach/custom_training_plan_provider.dart';
import '../../services/coach/exercise_video_service.dart';
import '../coaching/workout_widgets.dart';
import '../help/help_button.dart';

/// Odkazy na videa s technikou ke cvikům (Instagram, YouTube…).
/// Posílají se klientovi s každým tréninkem.
class ExerciseVideosScreen extends ConsumerStatefulWidget {
  const ExerciseVideosScreen({super.key});

  @override
  ConsumerState<ExerciseVideosScreen> createState() =>
      _ExerciseVideosScreenState();
}

class _ExerciseVideosScreenState extends ConsumerState<ExerciseVideosScreen> {
  Map<String, String> _videos = {};
  String _query = '';
  bool _onlyMissing = false;

  @override
  void initState() {
    super.initState();
    ExerciseVideoService.load().then((v) {
      if (mounted) setState(() => _videos = v);
    });
  }

  Future<void> _edit(String name) async {
    final current = ExerciseVideoService.urlFor(_videos, name) ?? '';
    final ctrl = TextEditingController(text: current);
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(name),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vlož odkaz na video (Instagram, YouTube…). V Instagramu: '
                  'u příspěvku ⋯ → Kopírovat odkaz.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Odkaz',
                    hintText: 'https://www.instagram.com/p/…',
                    errorText: error,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Vložit ze schránky',
                      icon: const Icon(Icons.content_paste),
                      onPressed: () async {
                        final d = await Clipboard.getData('text/plain');
                        final t = d?.text?.trim() ?? '';
                        if (t.isNotEmpty) setLocal(() => ctrl.text = t);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (current.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(ctx, ''),
                child: const Text('Odebrat'),
              ),
            TextButton(
              onPressed: () {
                final u = ctrl.text.trim();
                if (ExerciseVideoService.isValid(u)) {
                  openExerciseVideo(ctx, u);
                } else {
                  setLocal(() => error = 'Neplatný odkaz');
                }
              },
              child: const Text('Vyzkoušet'),
            ),
            FilledButton(
              onPressed: () {
                final u = ctrl.text.trim();
                if (u.isNotEmpty && !ExerciseVideoService.isValid(u)) {
                  setLocal(() => error =
                      'Odkaz musí začínat https://');
                  return;
                }
                Navigator.pop(ctx, u);
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 500), ctrl.dispose);
    if (result == null) return;
    final next = {..._videos};
    final key = ExerciseVideoService.norm(name);
    if (result.isEmpty) {
      next.remove(key);
    } else {
      next[key] = result;
    }
    await ExerciseVideoService.save(next);
    if (mounted) setState(() => _videos = next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plans = ref.watch(customTrainingPlanProvider);
    final names = <String, String>{};
    for (final p in plans) {
      for (final d in p.days) {
        for (final e in d.exercises) {
          final n = e.customName.trim();
          if (n.isNotEmpty) names.putIfAbsent(ExerciseVideoService.norm(n), () => n);
        }
      }
    }
    final q = _query.trim().toLowerCase();
    final list = names.values.where((n) {
      if (q.isNotEmpty && !n.toLowerCase().contains(q)) return false;
      if (_onlyMissing && ExerciseVideoService.urlFor(_videos, n) != null) {
        return false;
      }
      return true;
    }).toList()
      ..sort();
    final withVideo =
        names.values.where((n) => ExerciseVideoService.urlFor(_videos, n) != null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Videa ke cvikům'),
        actions: const [HelpButton(topic: 'videos')],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Ke cviku přidej odkaz na video s technikou (třeba z tvého '
                'Instagramu). Klient ho uvidí jako „Technika – video“ '
                'u každého tréninku, který mu pošleš.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Hledat cvik',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Jen bez videa'),
                    selected: _onlyMissing,
                    onSelected: (v) => setState(() => _onlyMissing = v),
                  ),
                  const Spacer(),
                  Text('$withVideo / ${names.length} s videem',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 6),
              if (names.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Zatím žádné cviky – vytvoř nebo vlož klientovi tréninkový '
                    'plán a jeho cviky se tu objeví.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              for (final n in list)
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: Icon(
                      ExerciseVideoService.urlFor(_videos, n) != null
                          ? Icons.play_circle
                          : Icons.play_circle_outline,
                      color: ExerciseVideoService.urlFor(_videos, n) != null
                          ? cs.primary
                          : cs.outline,
                    ),
                    title: Text(n),
                    subtitle: Text(
                      ExerciseVideoService.urlFor(_videos, n) ?? 'bez videa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _edit(n),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
