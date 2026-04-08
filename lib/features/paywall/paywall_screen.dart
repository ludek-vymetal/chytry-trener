import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/subscription/subscription_provider.dart';

enum PaywallTarget { client, coach }

class PaywallScreen extends ConsumerWidget {
  final PaywallTarget target;
  const PaywallScreen({super.key, required this.target});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Předplatné')),
      body: subAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
        data: (sub) {
          final untilText = sub.validUntil == null ? '—' : sub.validUntil!.toLocal().toString();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target == PaywallTarget.coach ? 'Coach Mode (pro trenéry)' : 'Client Mode',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Aktivní do: $untilText'),
                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      target == PaywallTarget.coach
                          ? 'Coach Mode je zamčený. Po aktivaci budeš mít přístup ke správě klientů.'
                          : 'Client Mode je zamčený. Po aktivaci budeš mít přístup k AI plánu.',
                    ),
                  ),
                ),

                const Spacer(),

                if (target == PaywallTarget.client) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(subscriptionProvider.notifier).activateClientFor30Days();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Aktivovat Client na 30 dní (TEST)'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(subscriptionProvider.notifier).activateCoachFor30Days();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Aktivovat Coach na 30 dní (TEST)'),
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(subscriptionProvider.notifier).clear();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Smazat předplatné (TEST)'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
