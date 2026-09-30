import 'package:flutter/material.dart';
import '../help/help_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/coach/coach_auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../settings/appearance_card.dart';
import '../paywall/paywall_screen.dart';
import '../../services/pdf/pdf_author.dart';
import 'pdf_branding_screen.dart';
import '../common/about_app.dart';
import 'exercise_videos_screen.dart';
import 'finance/income_screen.dart';
import '../help/help_screen.dart';
import '../help/widgets/help_and_reset_actions.dart';

/// Nastavení trenéra: jazyk, vzhled, nápověda, změna režimu, odhlášení.
/// Nevratné akce (tovární nastavení, smazání účtu) jsou odděleně dole.
class CoachSettingsScreen extends ConsumerStatefulWidget {
  const CoachSettingsScreen({super.key});

  @override
  ConsumerState<CoachSettingsScreen> createState() =>
      _CoachSettingsScreenState();
}

class _CoachSettingsScreenState extends ConsumerState<CoachSettingsScreen> {
  Future<void> _signOut(
    BuildContext context,
  ) async {
    final l10n =
        AppLocalizations.of(context)!;

    final colorScheme =
        Theme.of(context).colorScheme;

    try {
      await ref
          .read(
            coachAuthControllerProvider
                .notifier,
          )
          .signOut();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.coachSignedOut,
          ),
          backgroundColor:
              colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.signOutFailed(
              e.toString(),
            ),
          ),
          backgroundColor:
              colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (password == null || password.isEmpty) return;

    try {
      await ref
          .read(coachAuthControllerProvider.notifier)
          .deleteAccount(password: password);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeleted)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteAccountFailed(e.toString())),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = ref.watch(localeProvider);

    final languageLabel = locale == null
        ? l10n.automatic
        : (locale.languageCode == 'cs' ? l10n.czech : l10n.english);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        actions: const [HelpButton(topic: 'settings')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(languageLabel),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (code) {
                  ref.read(localeProvider.notifier).state =
                      code == 'auto' ? null : Locale(code);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'auto', child: Text(l10n.automatic)),
                  PopupMenuItem(value: 'cs', child: Text(l10n.czech)),
                  PopupMenuItem(value: 'en', child: Text(l10n.english)),
                ],
              ),
            ),
          ),
          const PlanStatusCard(),
          const SizedBox(height: 8),
          const AppearanceCard(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Příjmy a statistiky'),
              subtitle: const Text('Kolik jsi vydělal/a, grafy a porovnání'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncomeScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Videa ke cvikům'),
              subtitle: const Text('Odkazy na techniku (Instagram, YouTube)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExerciseVideosScreen()),
              ),
            ),
          ),
          const _PdfSignatureCard(),
          const AboutAppTile(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(l10n.helpTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l10n.changeMode),
              onTap: () => switchToRoleSelect(context, ref),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.logoutCoach),
              onTap: () => _signOut(context),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.dangerZone,
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.restore_from_trash_outlined,
                color: colorScheme.error,
              ),
              title: Text(l10n.factoryReset),
              onTap: () =>
                  const HelpAndResetActions().handleResetTap(context, ref),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.no_accounts, color: colorScheme.error),
              title: Text(
                l10n.deleteAccount,
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () => _deleteAccount(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountWarning),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscured,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.deleteAccountPasswordLabel,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, _passwordController.text),
          child: Text(l10n.deleteAccountConfirm),
        ),
      ],
    );
  }
}

/// Podpis, který se tiskne na jídelníčky, plány a souhrny
/// („Vypracoval/a: …“) spolu s upozorněním, že nejde o lékařskou péči.
class _PdfSignatureCard extends StatefulWidget {
  const _PdfSignatureCard();

  @override
  State<_PdfSignatureCard> createState() => _PdfSignatureCardState();
}

class _PdfSignatureCardState extends State<_PdfSignatureCard> {
  String _name = '';
  PdfBrand _brand = const PdfBrand();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await PdfAuthor.loadSaved();
    final brand = await PdfAuthor.loadBrand();
    if (mounted) {
      setState(() {
        _name = name;
        _brand = brand;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = [
      _name.isEmpty ? 'Podpis nenastaven' : 'Vypracoval/a: $_name',
      if (_brand.hasContacts) _brand.contactLine,
      _brand.logo == null ? 'bez loga' : 'logo ✓',
    ];
    return Card(
      child: ListTile(
        leading: _brand.logo == null
            ? const Icon(Icons.badge_outlined)
            : SizedBox(
                width: 40,
                height: 40,
                child: Image.memory(_brand.logo!, fit: BoxFit.contain),
              ),
        title: const Text('Údaje na dokumentech (PDF)'),
        subtitle: Text(parts.join('\n')),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PdfBrandingScreen()),
          );
          _load();
        },
      ),
    );
  }
}
