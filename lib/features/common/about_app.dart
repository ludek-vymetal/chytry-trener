import 'package:flutter/material.dart';

/// Informace o aplikaci a jejím autorovi.
class AboutApp {
  AboutApp._();

  static const name = 'Chytrý trenér';
  static const version = '1.0.0';
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
      ],
    );
  }
}

/// Položka „O aplikaci“ do nastavení a profilu.
class AboutAppTile extends StatelessWidget {
  const AboutAppTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('O aplikaci'),
        subtitle: const Text(
          '${AboutApp.name} ${AboutApp.version} · autor ${AboutApp.author}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => AboutApp.show(context),
      ),
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
