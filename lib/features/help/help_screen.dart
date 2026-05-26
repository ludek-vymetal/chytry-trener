import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.help,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                l10n.howAppWorks,
                style: theme
                    .textTheme.headlineSmall
                    ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _HelpSectionCard(
                title: l10n.dataStorage,
                icon: Icons.save_outlined,
                children: [
                  l10n.helpStorage1,
                  l10n.helpStorage2,
                  l10n.helpStorage3,
                ],
              ),

              const SizedBox(height: 12),

              _HelpSectionCard(
                title: l10n.clientExport,
                icon: Icons.upload_file_outlined,
                children: [
                  l10n.helpExport1,
                  l10n.helpExport2,
                  l10n.helpExport3,
                ],
              ),

              const SizedBox(height: 12),

              _HelpSectionCard(
                title: l10n.clientImport,
                icon: Icons.download_outlined,
                children: [
                  l10n.helpImport1,
                  l10n.helpImport2,
                  l10n.helpImport3,
                ],
              ),

              const SizedBox(height: 12),

              _HelpSectionCard(
                title: l10n.factoryReset,
                icon: Icons.warning_amber_rounded,
                children: [
                  l10n.helpReset1,
                  l10n.helpReset2,
                  l10n.helpReset3,
                ],
                accentColor: Colors.orange,
              ),

              const SizedBox(height: 12),

              _HelpSectionCard(
                title: l10n.importantWarning,
                icon: Icons.error_outline,
                children: [
                  l10n.helpWarning1,
                  l10n.helpWarning2,
                  l10n.helpWarning3,
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

    final color =
        accentColor ??
            theme.colorScheme.primary;

    return Card(
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(
              alpha: 0.18,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    style: theme
                        .textTheme.titleMedium
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...children.map(
              (text) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.only(
                        top: 6,
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        text,
                        style: theme
                            .textTheme.bodyMedium,
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