import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nápověda'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jak aplikace funguje',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _HelpSectionCard(
                title: 'Ukládání dat',
                icon: Icons.save_outlined,
                children: const [
                  'Aplikace funguje offline-first. To znamená, že data se ukládají lokálně přímo do zařízení.',
                  'Změny klientů, měření, poznámek, výkonů a plánů se neodesílají automaticky na externí server.',
                  'Pokud zařízení odinstalujete, resetujete nebo ztratíte bez exportu dat, můžete o uložené informace přijít.',
                ],
              ),
              const SizedBox(height: 12),
              _HelpSectionCard(
                title: 'Export klienta',
                icon: Icons.upload_file_outlined,
                children: const [
                  'Každého klienta lze exportovat pro zálohu nebo přenos.',
                  'Export obsahuje JSON, PDF report, CSV soubory a manifest.',
                  'Doporučený postup je dělat export pravidelně, hlavně před většími změnami nebo před resetem aplikace.',
                ],
              ),
              const SizedBox(height: 12),
              _HelpSectionCard(
                title: 'Import klienta',
                icon: Icons.download_outlined,
                children: const [
                  'Klienta lze importovat z JSON nebo z archivní složky.',
                  'Pokud už v aplikaci existuje klient se stejným ID, aplikace vytvoří nové bezpečné ID, aby nedošlo ke kolizi.',
                  'Po importu doporučujeme zkontrolovat detail klienta a ověřit, že jsou všechna data v pořádku.',
                ],
              ),
              const SizedBox(height: 12),
              _HelpSectionCard(
                title: 'Tovární nastavení',
                icon: Icons.warning_amber_rounded,
                children: const [
                  'Tovární nastavení nevratně smaže všechna lokálně uložená data aplikace.',
                  'Mažou se klienti, poznámky, inbody, obvody, detaily klientů a interní čítače ID.',
                  'Před resetem vždy nejdřív proveď export důležitých klientů.',
                ],
                accentColor: Colors.orange,
              ),
              const SizedBox(height: 12),
              _HelpSectionCard(
                title: 'Důležité upozornění',
                icon: Icons.error_outline,
                children: const [
                  'Tato aplikace aktuálně spoléhá na lokální úložiště zařízení.',
                  'Bez pravidelné zálohy může při ztrátě zařízení, odinstalaci aplikace nebo továrním resetu dojít ke ztrátě dat.',
                  'Nejdůležitější klienty doporučujeme průběžně exportovat.',
                ],
                accentColor: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> children;
  final Color? accentColor;

  const _HelpSectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}