import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/accent_provider.dart';
import '../../providers/theme_provider.dart';

/// Karta „Vzhled“: světlý / tmavý / automatický režim a barva aplikace.
/// Stejná v nastavení trenéra i v profilu klienta.
class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    final accent = ref.watch(accentProvider);
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  'Vzhled',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Světlý'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Tmavý'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('Auto'),
                  ),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    ref.read(themeProvider.notifier).setTheme(s.first),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Barva aplikace',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final a in AppAccent.all)
                  Tooltip(
                    message: a.name,
                    child: Semantics(
                      button: true,
                      selected: a.id == accent.id,
                      label: a.name,
                      child: InkResponse(
                        onTap: () =>
                            ref.read(accentProvider.notifier).setAccent(a),
                        radius: 28,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: a.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: a.id == accent.id
                                  ? cs.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: a.id == accent.id
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 22)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              accent.name,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
