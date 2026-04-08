import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/coach_setup_data.dart';
import '../../../providers/coach/coach_auth_provider.dart';
import '../../../providers/coach/coach_clients_controller.dart';
import '../../../providers/coach/coach_setup_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/app_reset_service.dart';
import '../help_screen.dart';

class HelpAndResetActions extends ConsumerWidget {
  const HelpAndResetActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Nápověda',
          icon: const Icon(Icons.help_outline),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpScreen(),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Tovární nastavení',
          icon: const Icon(Icons.restore_from_trash_outlined),
          onPressed: () => _handleResetTap(context, ref),
        ),
      ],
    );
  }

  Future<void> _handleResetTap(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final setup = await ref.read(coachSetupProvider.future);

      if (setup == null || !setup.isComplete) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Nejdřív dokonči nastavení trenéra a vytvoř bezpečnostní kód.',
            ),
          ),
        );
        return;
      }

      if (!context.mounted) return;
      await _showFactoryResetDialog(context, ref, setup);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Nepodařilo se načíst bezpečnostní kód: $e'),
        ),
      );
    }
  }

  Future<void> _showFactoryResetDialog(
    BuildContext context,
    WidgetRef ref,
    CoachSetupData setup,
  ) async {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureText = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tovární nastavení'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trenér ${setup.firstName}, opravdu chcete vymazat lokální data na tomto zařízení?',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tato akce smaže lokálně uložená data aplikace a odhlásí trenéra z tohoto zařízení.',
                      ),
                      const SizedBox(height: 8),
                      const Text('• klienty uložené v zařízení'),
                      const Text('• poznámky'),
                      const Text('• inbody'),
                      const Text('• obvody'),
                      const Text('• detaily klientů'),
                      const Text('• nastavení aplikace'),
                      const SizedBox(height: 12),
                      const Text(
                        'Cloudová data trenéra se touto akcí nemažou.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pro potvrzení zadejte svůj bezpečnostní kód:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: codeController,
                        obscureText: obscureText,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        maxLength: 4,
                        decoration: InputDecoration(
                          labelText: 'Bezpečnostní kód',
                          hintText: 'Zadej svůj 4místný kód',
                          border: const OutlineInputBorder(),
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          final input = value?.trim() ?? '';
                          if (input.isEmpty) {
                            return 'Zadej bezpečnostní kód.';
                          }
                          if (input != setup.securityPin) {
                            return 'Neplatný kód.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Zrušit'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: const Text('Vymazat zařízení'),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();

    if (confirmed != true || !context.mounted) return;

    await _runFactoryReset(context, ref);
  }

  Future<void> _runFactoryReset(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final navigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text('Probíhá reset aplikace...'),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await AppResetService.factoryReset();

      ref.invalidate(coachClientsControllerProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(coachSetupProvider);
      ref.invalidate(coachAuthStateProvider);

      if (!context.mounted) return;

      rootNavigator.pop();
      navigator.popUntil((route) => route.isFirst);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Zařízení bylo vymazáno a trenér byl odhlášen.'),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        rootNavigator.pop();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Reset se nepodařilo dokončit: $e'),
        ),
      );
    }
  }
}