import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/subscription/subscription_provider.dart';

enum PaywallTarget { client, coach }

/// Nabídne plnou verzi, když uživatel narazí na zamčenou funkci.
/// Vrací `true`, pokud se po zavření okna plná verze odemkla.
Future<bool> showUpgradeSheet(
  BuildContext context,
  WidgetRef ref, {
  required String feature,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _UpgradeSheet(feature: feature),
  );
  return ref.read(accessProvider).isFull;
}

/// Když je funkce zamčená, ukáže nabídku a vrátí `false`.
/// Použití: `if (!await requireFull(context, ref, 'Nákupní seznam')) return;`
Future<bool> requireFull(
  BuildContext context,
  WidgetRef ref,
  String feature,
) async {
  if (ref.read(accessProvider).isFull) return true;
  return showUpgradeSheet(context, ref, feature: feature);
}

class _UpgradeSheet extends ConsumerWidget {
  final String feature;
  const _UpgradeSheet({required this.feature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.workspace_premium_outlined, size: 40, color: cs.primary),
            const SizedBox(height: 10),
            Text(
              '$feature je v plné verzi',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Ve zkušební verzi si můžeš vyzkoušet kousek od každé funkce. '
              'Plná verze odemkne všechno – neomezeně klientů, celé programy, '
              'týdenní jídelníčky, podrobný rozbor InBody a PDF souhrny.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.lock_open),
                label: const Text('Zobrazit plnou verzi'),
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const PaywallScreen(target: PaywallTarget.coach),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.key_outlined),
                label: const Text('Mám aktivační kód'),
                onPressed: () async {
                  final ok = await showRedeemCodeDialog(context, ref);
                  if (ok && context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog pro zadání aktivačního kódu. Vrací `true` při úspěchu.
Future<bool> showRedeemCodeDialog(BuildContext context, WidgetRef ref) async {
  final ctrl = TextEditingController();
  String? error;
  var busy = false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('Aktivační kód'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kód ti dá tvůj trenér nebo trenérka po zaplacení předplatného.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Kód',
                hintText: 'CT-XXXX-XXXX',
                errorText: error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialogContext, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    final err = await ref
                        .read(subscriptionProvider.notifier)
                        .redeemCode(ctrl.text);
                    if (!dialogContext.mounted) return;
                    if (err == null) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      setState(() {
                        busy = false;
                        error = err;
                      });
                    }
                  },
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Aktivovat'),
          ),
        ],
      ),
    ),
  );

  ctrl.dispose();
  if (ok == true && context.mounted) {
    final until = ref.read(accessProvider).validUntil;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          until == null
              ? 'Plná verze je aktivní.'
              : 'Plná verze je aktivní do ${until.day}. ${until.month}. ${until.year}.',
        ),
      ),
    );
  }
  return ok == true;
}

/// Obrazovka „Plná verze“: srovnání, stav předplatného a aktivační kód.
class PaywallScreen extends ConsumerWidget {
  final PaywallTarget target;
  const PaywallScreen({super.key, required this.target});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(accessProvider);
    final cs = Theme.of(context).colorScheme;

    Widget row(String feature, String free, String full) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                feature,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(free, style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            Expanded(
              flex: 5,
              child: Text(
                full,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final days = sub.daysLeft;

    return Scaffold(
      appBar: AppBar(title: const Text('Plná verze')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        sub.isFull
                            ? Icons.workspace_premium
                            : Icons.lock_outline,
                        color: cs.onPrimaryContainer,
                        size: 36,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            if (days != null)
                              Text(
                                'Zbývá $days ${days == 1 ? 'den' : days < 5 ? 'dny' : 'dní'}',
                                style: TextStyle(color: cs.onPrimaryContainer),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      row('', 'Zkušební', 'Plná verze'),
                      const Divider(),
                      row('Klienti', '1', 'neomezeně'),
                      row('Jídelníček', '1 den', 'celý týden, levná varianta'),
                      row('Nákupní seznam', '–', 'ano'),
                      row('Programy', 'náhled', 'Hollywood, Bikini, Kulatý zadek, '
                          'Ruský cyklus…'),
                      row('InBody', 'zadání a skóre', 'podrobný rozbor a plán'),
                      row('PDF souhrn', 's nápisem „Zkušební“',
                          'čistý, barevný i černobílý'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Předplatné v obchodě – brzy'),
                  onPressed: null,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('Mám aktivační kód'),
                  onPressed: () => showRedeemCodeDialog(context, ref),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                Text(
                  'Testování (jen ve vývojové verzi)',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => ref
                          .read(subscriptionProvider.notifier)
                          .simulateFree(true),
                      child: const Text('Zkušební verze (TEST)'),
                    ),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(subscriptionProvider.notifier)
                          .activateTestFor30Days(),
                      child: const Text('Plná na 30 dní (TEST)'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(subscriptionProvider.notifier).clear(),
                      child: const Text('Vynulovat (TEST)'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Karta stavu předplatného do nastavení / profilu.
class PlanStatusCard extends ConsumerWidget {
  const PlanStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(accessProvider);
    final days = sub.daysLeft;
    return Card(
      child: ListTile(
        leading: Icon(
          sub.isFull ? Icons.workspace_premium : Icons.lock_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(sub.label),
        subtitle: days == null
            ? const Text('Srovnání verzí a aktivační kód')
            : Text('Zbývá $days ${days == 1 ? 'den' : days < 5 ? 'dny' : 'dní'}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PaywallScreen(target: PaywallTarget.coach),
          ),
        ),
      ),
    );
  }
}

/// Karta místo zamčeného obsahu (např. další dny jídelníčku).
class LockedFeatureCard extends ConsumerWidget {
  final String feature;
  final String description;

  const LockedFeatureCard({
    super.key,
    required this.feature,
    required this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 36, color: cs.primary),
            const SizedBox(height: 10),
            Text(
              feature,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.lock_open),
              label: const Text('Odemknout plnou verzi'),
              onPressed: () => showUpgradeSheet(context, ref, feature: feature),
            ),
          ],
        ),
      ),
    );
  }
}

/// Celá obrazovka pro zamčenou funkci.
class LockedFeatureScreen extends StatelessWidget {
  final String title;
  final String description;

  const LockedFeatureScreen({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LockedFeatureCard(feature: title, description: description),
          ),
        ),
      ),
    );
  }
}
