import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'spal_screen.dart';
import 'spal_service.dart';
import 'spal_styl.dart';

/// Menu (jako boční menu v Clubspire): profil, QR, novinky, kontakt, podmínky, odhlášení.
class SpalMenu extends ConsumerWidget {
  const SpalMenu({super.key, required this.samostatne});
  final bool samostatne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(spalInfoProvider).valueOrNull;
    final prehled = ref.watch(spalPrehledProvider).valueOrNull;
    final logo = info?['logo_base64'] as String?;
    final novinky = (info?['novinky'] as List?) ?? const [];

    Widget polozka(IconData i, String t, VoidCallback onTap, {int odznak = 0}) => ListTile(
          leading: Badge(
            isLabelVisible: odznak > 0,
            label: Text('$odznak'),
            child: Icon(i, color: spalZluta, size: 28),
          ),
          title: Text(t, style: const TextStyle(fontSize: 18)),
          onTap: onTap,
        );
    void jdi(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        Container(
          color: spalTmava,
          padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 20, 16, 20),
          child: Column(children: [
            if (logo != null)
              Image.memory(base64Decode(logo), height: 90)
            else
              const Icon(Icons.fitness_center, color: spalZluta, size: 64),
            const SizedBox(height: 12),
            Text(
              prehled == null ? (SpalService.email ?? '') : '${prehled['jmeno'] ?? ''} ${prehled['prijmeni'] ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ]),
        ),
        polozka(Icons.qr_code_2, 'QR kód', () => otevritQr(context)),
        polozka(Icons.notifications_none, 'Oznámení', () => jdi(const SpalNovinky()), odznak: novinky.length),
        polozka(Icons.account_circle, 'Můj profil', () => jdi(const SpalProfil())),
        if (samostatne)
          polozka(Icons.fitness_center, 'Chytrý trenér – tréninky a jídelníček',
              () => otevritChytrehoTrenera(context))
        else
          polozka(Icons.arrow_back, 'Zpět do Chytrého trenéra', () => Navigator.of(context).maybePop()),
        polozka(Icons.power_settings_new, 'Odhlásit', () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Odhlásit z fitka?'),
              content: const Text('Znovu se přihlásíš e-mailem a heslem.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Zrušit')),
                FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Odhlásit')),
              ],
            ),
          );
          if (ok == true) await SpalService.odhlasit();
        }),
        const Divider(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Informace', style: TextStyle(color: spalZluta, fontSize: 17, fontWeight: FontWeight.w600)),
        ),
        polozka(Icons.mail_outline, 'Kontakt', () => jdi(const SpalKontakt())),
        polozka(Icons.lock_outline, 'Obchodní podmínky a soukromí', () {
          final web = info?['web'] as String?;
          if (web != null) _otevrit(web.startsWith('http') ? web : 'https://$web');
        }),
        const SizedBox(height: 90),
      ]),
    );
  }
}

Future<void> _otevrit(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class SpalNovinky extends ConsumerWidget {
  const SpalNovinky({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novinky = (ref.watch(spalInfoProvider).valueOrNull?['novinky'] as List?) ?? const [];
    return Theme(
      data: spalTema(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Oznámení')),
        body: novinky.isEmpty
            ? const Center(child: Text('Žádná oznámení'))
            : ListView(padding: const EdgeInsets.all(20), children: [
                for (final n in novinky) ...[
                  Text('${n['nadpis']}',
                      style: const TextStyle(color: spalZluta, fontSize: 22, fontWeight: FontWeight.w800)),
                  const Divider(),
                  Text(spalDatum(n['datum']),
                      style: const TextStyle(color: Color(0xFF1E6FA8), fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text('${n['text'] ?? ''}', style: const TextStyle(fontSize: 17)),
                  const SizedBox(height: 28),
                ],
              ]),
      ),
    );
  }
}

class SpalKontakt extends ConsumerWidget {
  const SpalKontakt({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(spalInfoProvider).valueOrNull ?? const {};
    final logo = i['logo_base64'] as String?;
    Widget nadpis(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(t, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        );
    Widget odkaz(String t, String url) => InkWell(
          onTap: () => _otevrit(url),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(t, style: const TextStyle(fontSize: 17, decoration: TextDecoration.underline)),
          ),
        );
    final ig = i['instagram'] as String?;
    return Theme(
      data: spalTema(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Kontakty')),
        body: ListView(children: [
          Container(
            color: spalTmava,
            padding: const EdgeInsets.all(16),
            child: logo == null
                ? const Icon(Icons.fitness_center, color: spalZluta, size: 56)
                : Image.memory(base64Decode(logo), height: 70),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              nadpis('Adresa'),
              if (i['adresa'] != null)
                odkaz('${i['adresa']}',
                    'https://maps.google.com/?q=${Uri.encodeComponent('${i['adresa']}')}'),
              nadpis('Kontakt'),
              if (i['telefon'] != null) odkaz('${i['telefon']}', 'tel:${'${i['telefon']}'.replaceAll(' ', '')}'),
              if (i['email'] != null) odkaz('${i['email']}', 'mailto:${i['email']}'),
              nadpis('Web'),
              if (i['web'] != null)
                odkaz('${i['web']}', '${i['web']}'.startsWith('http') ? '${i['web']}' : 'https://${i['web']}'),
              nadpis('Sociální sítě'),
              Row(children: [
                if (i['facebook'] != null)
                  IconButton(
                    icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 36),
                    onPressed: () => _otevrit('${i['facebook']}'),
                  ),
                if (ig != null)
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFFC13584), size: 34),
                    onPressed: () => _otevrit(ig.startsWith('http') ? ig : 'https://instagram.com/$ig'),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class SpalProfil extends ConsumerWidget {
  const SpalProfil({super.key});

  Future<void> _zmenitHeslo(BuildContext context) async {
    final c = TextEditingController();
    final heslo = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Nové heslo'),
        content: TextField(
          controller: c,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Aspoň 6 znaků'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Zrušit')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('Uložit')),
        ],
      ),
    );
    if (heslo == null || !context.mounted) return;
    if (heslo.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Heslo musí mít aspoň 6 znaků')));
      return;
    }
    try {
      await SpalService.zmenitHeslo(heslo);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Heslo změněno')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(SpalService.chyba(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(spalPrehledProvider).valueOrNull;
    return Theme(
      data: spalTema(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Můj profil')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ListTile(
            leading: const Icon(Icons.person, color: spalZluta),
            title: Text(p == null ? '' : '${p['jmeno'] ?? ''} ${p['prijmeni'] ?? ''}',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            subtitle: const Text('Jméno a údaje změníš na recepci'),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline, color: spalZluta),
            title: Text(SpalService.email ?? ''),
            subtitle: const Text('Přihlašovací e-mail'),
          ),
          ListTile(
            leading: const Icon(Icons.key, color: spalZluta),
            title: const Text('Změnit heslo'),
            onTap: () => _zmenitHeslo(context),
          ),
        ]),
      ),
    );
  }
}
