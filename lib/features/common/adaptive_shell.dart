import 'package:flutter/material.dart';

import '../help/help_button.dart';

class ShellDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Číslo v červeném kolečku (např. nové rezervace). 0 = nic.
  final int badge;

  const ShellDestination(this.icon, this.selectedIcon, this.label,
      {this.badge = 0});

  Widget iconWidget(bool selected) {
    final i = Icon(selected ? selectedIcon : icon);
    if (badge <= 0) return i;
    return Badge(label: Text('$badge'), child: i);
  }
}

/// Hlavní rozložení aplikace podle šířky obrazovky:
/// - mobil (< 840 px): spodní lišta,
/// - tablet (840–1199 px): boční lišta s ikonami,
/// - počítač (≥ 1200 px): rozbalený boční panel s názvy.
class AdaptiveShell extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final List<ShellDestination> destinations;
  final List<Widget> pages;
  final String helpTopic;

  const AdaptiveShell({
    super.key,
    required this.index,
    required this.onSelect,
    required this.destinations,
    required this.pages,
    this.helpTopic = 'start',
  });

  static const tabletBreakpoint = 840.0;
  static const desktopBreakpoint = 1200.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final body = IndexedStack(index: index, children: pages);
    final cs = Theme.of(context).colorScheme;

    if (width < tabletBreakpoint) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onSelect,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: d.iconWidget(false),
                selectedIcon: d.iconWidget(true),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = width >= desktopBreakpoint;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 220,
            backgroundColor: cs.surface,
            selectedIndex: index,
            onDestinationSelected: onSelect,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              child: _Logo(extended: extended),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: HelpButton(topic: helpTopic, withLabel: extended),
                ),
              ),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: d.iconWidget(false),
                  selectedIcon: d.iconWidget(true),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.6),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final bool extended;
  const _Logo({required this.extended});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mark = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'CT',
        style: TextStyle(
          color: cs.onPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
    if (!extended) return mark;
    return SizedBox(
      width: 196,
      child: Row(
        children: [
          mark,
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Chytrý trenér',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rozložení s pravým bočním panelem (jako na návrhu pro počítač):
/// na širokých obrazovkách je vpravo pevný sloupec s doplňkovými
/// informacemi, na užších se panel neukazuje – obsah [side] si pak
/// obrazovka vloží do hlavního sloupce sama.
class SidePanelLayout extends StatelessWidget {
  final Widget main;
  final List<Widget> side;
  final double sideWidth;

  const SidePanelLayout({
    super.key,
    required this.main,
    required this.side,
    this.sideWidth = 330,
  });

  /// Šířka okna, od které se ukazuje pravý panel.
  static const breakpoint = 1100.0;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpoint;

  @override
  Widget build(BuildContext context) {
    if (!isWide(context)) return main;
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: main),
        Container(
          width: sideWidth,
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              left: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: SafeArea(
            left: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                for (var i = 0; i < side.length; i++) ...[
                  if (i > 0) const SizedBox(height: 18),
                  side[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Nadpis sekce v bočním panelu (malá kapitálka).
class SideTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SideTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Obsah stránky na širokých obrazovkách vycentrovaný a omezený na
/// čitelnou šířku.
class PageWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PageWidth({super.key, required this.child, this.maxWidth = 1100});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
