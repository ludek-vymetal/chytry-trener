import 'package:flutter/material.dart';

import 'help_screen.dart';

/// Tlačítko nápovědy „?“ – do horní lišty každé hlavní obrazovky.
/// [topic] určuje, ke které části aplikace se nápověda otevře.
class HelpButton extends StatelessWidget {
  final String topic;
  final bool withLabel;

  const HelpButton({super.key, this.topic = 'start', this.withLabel = false});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HelpScreen(topic: topic)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (withLabel) {
      return TextButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.help_outline),
        label: const Text('Nápověda'),
      );
    }
    return IconButton(
      tooltip: 'Nápověda',
      icon: const Icon(Icons.help_outline),
      onPressed: () => _open(context),
    );
  }
}
