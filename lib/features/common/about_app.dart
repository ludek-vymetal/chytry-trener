import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Informace o aplikaci a jejím autorovi.
class AboutApp {
  AboutApp._();

  static const name = 'Chytrý trenér';
  static const version = '1.0.1';
  static const author = 'Luděk Vymětal';
  static const year = 2026;

  static void show(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showAboutDialog(
      context: context,
      applicationName: name,
      applicationVersion: 'verze $version',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.fitness_center, color: cs.onPrimaryContainer),
      ),
      applicationLegalese: '© $year $author\nVšechna práva vyhrazena.',
      children: const [
        SizedBox(height: 16),
        Text('Autor aplikace: $author'),
        SizedBox(height: 6),
        Text(
          'Aplikace pro osobní trenéry a jejich klienty – tréninkové plány, '
          'jídelníčky, měření a online koučink.',
        ),
        SizedBox(height: 12),
        Text(LegalInfo.healthShort),
        SizedBox(height: 6),
        Text('Zásady ochrany osobních údajů: ${LegalInfo.privacyUrl}'),
      ],
    );
  }
}

/// Právní informace: zásady ochrany osobních údajů a upozornění ke zdraví.
class LegalInfo {
  LegalInfo._();

  static const privacyUrl =
      'https://ludektrener.cz/zasady-ochrany-osobnich-udaju/';

  static const healthShort =
      'Aplikace nenahrazuje lékaře. Tréninky, jídelníčky a doporučení jsou '
      'obecné informace, ne lékařská rada.';

  static const _ackKey = 'health_disclaimer_ack_v1';

  static Future<void> openPrivacy(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(privacyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odkaz se nepodařilo otevřít: $privacyUrl')),
      );
    }
  }

  /// Upozornění ke zdraví. [firstRun] = při prvním spuštění s tlačítkem
  /// „Rozumím“, které se zapamatuje.
  static Future<void> showHealth(
    BuildContext context, {
    bool firstRun = false,
  }) async {
    final cs = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      barrierDismissible: !firstRun,
      builder: (d) => AlertDialog(
        icon: Icon(Icons.health_and_safety_outlined, color: cs.primary, size: 36),
        title: const Text('Upozornění ke zdraví'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chytrý trenér je pomocník pro trénink, výživu a sledování '
                'pokroku. Nenahrazuje lékaře, fyzioterapeuta ani nutričního '
                'terapeuta.',
              ),
              SizedBox(height: 10),
              Text(
                '• Tréninky, jídelníčky, kalorie a doporučení jsou obecné '
                'informace, ne lékařská rada ani diagnóza.',
              ),
              SizedBox(height: 6),
              Text(
                '• Máš-li zdravotní potíže, užíváš léky, jsi těhotná nebo '
                'začínáš po delší pauze, poraď se před změnou tréninku či '
                'stravy s lékařem.',
              ),
              SizedBox(height: 6),
              Text(
                '• Při bolesti na hrudi, závratích, dušnosti nebo jiné bolesti '
                'cvičení hned přeruš a vyhledej lékaře.',
              ),
              SizedBox(height: 6),
              Text(
                '• Údaje z hodinek a měření jsou orientační a nejsou určeny '
                'k lékařským účelům.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(d),
            child: Text(firstRun ? 'Rozumím' : 'Zavřít'),
          ),
        ],
      ),
    );
    if (firstRun) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_ackKey, true);
      } catch (_) {}
    }
  }

  /// Ukáže upozornění, pokud ho uživatel v tomto zařízení ještě nepotvrdil.
  static Future<void> showHealthOnce(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_ackKey) == true) return;
    } catch (_) {
      return;
    }
    if (!context.mounted) return;
    await showHealth(context, firstRun: true);
  }
}

/// Zásady ochrany osobních údajů a upozornění ke zdraví (nastavení, profil).
class LegalTiles extends StatelessWidget {
  const LegalTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Zásady ochrany osobních údajů'),
            subtitle: const Text('ludektrener.cz'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => LegalInfo.openPrivacy(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Upozornění ke zdraví'),
            subtitle: const Text('Aplikace nenahrazuje lékaře'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => LegalInfo.showHealth(context),
          ),
        ],
      ),
    );
  }
}

/// Položka „O aplikaci“ do nastavení a profilu.
class AboutAppTile extends StatelessWidget {
  const AboutAppTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LegalTiles(),
        Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('O aplikaci'),
        subtitle: const Text(
          '${AboutApp.name} ${AboutApp.version} · autor ${AboutApp.author}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => AboutApp.show(context),
      ),
        ),
      ],
    );
  }
}

/// Nenápadný podpis autora dole na obrazovce.
class AuthorFooter extends StatelessWidget {
  const AuthorFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => AboutApp.show(context),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            '${AboutApp.name} ${AboutApp.version} · © ${AboutApp.year} '
            '${AboutApp.author}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
