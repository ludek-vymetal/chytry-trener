import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../role/role_select_screen.dart';
import 'spal_menu.dart';
import 'spal_rezervace.dart';
import 'spal_service.dart';
import 'spal_styl.dart';
import 'spal_ucet.dart';

/// Sekce SPAL Strength Gym – vzhledem jako aplikace Clubspire:
/// Přehled · Rezervace · (+ nová rezervace) · Účet · Menu.
class SpalScreen extends ConsumerWidget {
  const SpalScreen({super.key, this.samostatne = false});

  /// Hlavní obrazovka aplikace (člen fitka bez režimu Chytrého trenéra).
  final bool samostatne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prihlasen = ref.watch(spalPrihlasenProvider).valueOrNull ?? SpalService.prihlasen;
    return Theme(
      data: spalTema(context),
      child: prihlasen
          ? SpalDomov(samostatne: samostatne)
          : Scaffold(
              appBar: AppBar(
                title: const Text('SPAL Strength Gym'),
                automaticallyImplyLeading: !samostatne,
              ),
              body: const SpalPrihlaseni(),
            ),
    );
  }
}

/// Výběr režimu Chytrého trenéra z menu fitka (trénink, jídelníček…).
void otevritChytrehoTrenera(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
    );

// ---------------------------------------------------------------------
// Hlavní rozložení se spodní lištou
// ---------------------------------------------------------------------

class SpalDomov extends ConsumerStatefulWidget {
  const SpalDomov({super.key, required this.samostatne});
  final bool samostatne;
  @override
  ConsumerState<SpalDomov> createState() => _SpalDomovState();
}

class _SpalDomovState extends ConsumerState<SpalDomov> {
  int _i = 0;

  void prepnout(int i) => setState(() => _i = i);

  @override
  Widget build(BuildContext context) {
    final stranky = [
      SpalPrehled(onUcet: () => prepnout(2)),
      const SpalMojeRezervace(),
      const SpalUcet(),
      SpalMenu(samostatne: widget.samostatne),
    ];
    Widget polozka(int i, IconData ikona, String text) {
      final vybrano = _i == i;
      final barva = vybrano ? spalZluta : spalCerna;
      return Expanded(
        child: InkWell(
          onTap: () => prepnout(i),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(ikona, color: barva, size: 30),
            Text(text, style: TextStyle(color: barva, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _i, children: stranky),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 68,
        height: 68,
        child: FloatingActionButton(
          heroTag: 'spal_nova_rezervace',
          shape: const CircleBorder(),
          backgroundColor: _i == 0 ? spalCerna : spalZluta,
          foregroundColor: Colors.white,
          tooltip: 'Nová rezervace',
          onPressed: () => otevritNovouRezervaci(context),
          child: const Icon(Icons.add, size: 40),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 72,
        padding: EdgeInsets.zero,
        child: Row(children: [
          polozka(0, Icons.dashboard, 'Přehled'),
          polozka(1, Icons.event, 'Rezervace'),
          const SizedBox(width: 76),
          polozka(2, Icons.credit_card, 'Účet'),
          polozka(3, Icons.menu, 'Menu'),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Přehled
// ---------------------------------------------------------------------

class SpalPrehled extends ConsumerWidget {
  const SpalPrehled({super.key, required this.onUcet});
  final VoidCallback onUcet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ucet = ref.watch(spalUcetProvider).valueOrNull;
    final prehled = ref.watch(spalPrehledProvider).valueOrNull;
    final rez = ref.watch(spalRezervaceProvider).valueOrNull ?? const [];
    final novinky = (ref.watch(spalInfoProvider).valueOrNull?['novinky'] as List?) ?? const [];
    final ted = DateTime.now();
    final nadchazejici = rez
        .where((r) => r['stav'] == 'aktivni' && DateTime.parse(r['zacatek'] as String).isAfter(ted))
        .toList()
      ..sort((a, b) => (a['zacatek'] as String).compareTo(b['zacatek'] as String));
    final depozit = (ucet?['depozit_kc'] as num?) ?? (prehled?['depozit_kc'] as num?) ?? 0;
    final depozitDo = ucet?['depozit_platny_do'] ?? prehled?['depozit_platny_do'];

    Widget tlacitko(String text, IconData ikona, VoidCallback onTap, {bool hlavni = false}) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Material(
            color: hlavni ? spalZluta : const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(10),
            elevation: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: SizedBox(
                height: 58,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(ikona, color: hlavni ? spalCerna : spalZluta, size: 30),
                  const SizedBox(width: 18),
                  Text(text,
                      style: TextStyle(
                          color: hlavni ? spalCerna : spalZluta, fontSize: 21, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: spalTmava,
      appBar: AppBar(
        backgroundColor: spalTmava,
        elevation: 0,
        automaticallyImplyLeading: Navigator.canPop(context),
        actions: [
          IconButton(
            tooltip: 'Novinky',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpalNovinky())),
            icon: Badge(
              isLabelVisible: novinky.isNotEmpty,
              label: Text('${novinky.length}'),
              child: const Icon(Icons.notifications_none, size: 32),
            ),
          ),
        ],
      ),
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: () async {
            spalObnovit(ref);
            ref.invalidate(spalInfoProvider);
          },
          child: ListView(padding: const EdgeInsets.only(top: 8, bottom: 100), children: [
            tlacitko('Nová rezervace', Icons.event_available, () => otevritNovouRezervaci(context), hlavni: true),
            tlacitko('Koupit členství', Icons.workspace_premium_outlined,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KoupitClenstvi()))),
            tlacitko('Koupit permanentku', Icons.confirmation_number_outlined,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KoupitPermanentku()))),
            tlacitko('Koupit voucher', Icons.card_giftcard,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KoupitVoucher()))),
            const SizedBox(height: 20),
            InkWell(
              onTap: onUcet,
              child: Column(children: [
                Text(spalKc(depozit),
                    style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Depozit • ${depozitDo == null ? 'platný neomezeně' : 'platný do ${spalDatum(depozitDo)}'}',
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
                ]),
              ]),
            ),
            if (prehled != null) _StavVstupu(prehled: prehled),
            const SizedBox(height: 20),
            // karta Rezervace
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A3F2A), Color(0xFF1C1C1C)],
                ),
              ),
              child: Column(children: [
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.event, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Text('Rezervace', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 20),
                if (nadchazejici.isEmpty)
                  const Text('Nemáte žádné rezervace', style: TextStyle(color: Colors.white, fontSize: 19))
                else
                  for (final r in nadchazejici.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${_den(r['zacatek'])} ${spalCas(DateTime.parse(r['zacatek'] as String).toLocal())} · ${r['nazev']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
              ]),
            ),
          ]),
        ),
        // plovoucí QR kód (jako v Clubspire)
        Positioned(
          right: 16,
          bottom: 16,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: spalZluta,
              foregroundColor: spalCerna,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => otevritQr(context),
            icon: const Icon(Icons.qr_code_2, size: 32),
            label: const Text('QR kód', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }

  static String _den(Object? iso) {
    final d = DateTime.parse(iso as String).toLocal();
    return '${spalDny[d.weekday - 1]} ${d.day}.${d.month}.';
  }
}

/// Krátce pod depozitem: čím projdu dveřmi (členství / permanentka / nic).
class _StavVstupu extends StatelessWidget {
  const _StavVstupu({required this.prehled});
  final Map<String, dynamic> prehled;

  @override
  Widget build(BuildContext context) {
    final clenstvi = (prehled['clenstvi'] as List?) ?? const [];
    final perm = (prehled['permanentky'] as List?) ?? const [];
    final preruseni = prehled['preruseni'];
    String text;
    Color barva = Colors.white70;
    if (preruseni != null) {
      text = 'Členství je přerušené';
      barva = Colors.orangeAccent;
    } else if (clenstvi.isNotEmpty) {
      final c = clenstvi.first as Map;
      text = '${c['nazev']}${c['do'] == null ? '' : ' • do ${spalDatum(c['do'])}'}';
    } else if (perm.isNotEmpty) {
      final p = perm.first as Map;
      text = '${p['nazev']}${p['druh'] == 'vstupova' ? ' • zbývá ${p['zbyva']} vstupů' : ''}';
    } else {
      text = 'Nemáš platné členství ani permanentku';
      barva = Colors.orangeAccent;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: barva, fontSize: 16)),
    );
  }
}

// ---------------------------------------------------------------------
// QR kód
// ---------------------------------------------------------------------

void otevritQr(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Theme(
          data: spalTema(context),
          child: Scaffold(
            appBar: AppBar(title: const Text('QR kód')),
            body: const Center(child: SpalQrKarta()),
          ),
        ),
      ),
    );

/// QR kód pro čtečku u dveří. Mění se každých 30 s (screenshot kamarádovi nefunguje).
class SpalQrKarta extends StatefulWidget {
  const SpalQrKarta({super.key});
  @override
  State<SpalQrKarta> createState() => _SpalQrKartaState();
}

class _SpalQrKartaState extends State<SpalQrKarta> with WidgetsBindingObserver {
  String? _kod;
  String? _chyba;
  Timer? _obnova;
  Timer? _odpocet;
  int _zbyva = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nacist();
    _obnova = Timer.periodic(const Duration(seconds: 30), (_) => _nacist());
    _odpocet = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _zbyva = _zbyva > 0 ? _zbyva - 1 : 0);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _nacist();
  }

  Future<void> _nacist() async {
    try {
      final q = await SpalService.qr();
      if (mounted) {
        setState(() {
          _kod = q.kod;
          _chyba = null;
          _zbyva = 30;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chyba = SpalService.chyba(e));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _obnova?.cancel();
    _odpocet?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Přilož ke čtečce u dveří', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 16),
        if (_kod != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(data: _kod!, size: 280, backgroundColor: Colors.white),
          )
        else if (_chyba != null)
          Column(children: [
            Text(_chyba!, textAlign: TextAlign.center),
            TextButton(onPressed: _nacist, child: const Text('Zkusit znovu')),
          ])
        else
          const SizedBox(height: 280, child: Center(child: CircularProgressIndicator(color: spalZluta))),
        const SizedBox(height: 10),
        Text(_kod == null ? '' : 'Kód se obnoví za $_zbyva s', style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------
// Přihlášení / propojení
// ---------------------------------------------------------------------

class SpalPrihlaseni extends ConsumerStatefulWidget {
  const SpalPrihlaseni({super.key});
  @override
  ConsumerState<SpalPrihlaseni> createState() => _SpalPrihlaseniState();
}

class _SpalPrihlaseniState extends ConsumerState<SpalPrihlaseni> {
  final _email = TextEditingController();
  final _heslo = TextEditingController();
  bool _pracuji = false;
  String? _chyba;

  Future<void> _prihlasit() async {
    setState(() {
      _pracuji = true;
      _chyba = null;
    });
    try {
      await SpalService.prihlasit(_email.text, _heslo.text);
    } on AuthException catch (e) {
      setState(() => _chyba = e.message.contains('Invalid') ? 'Špatný e-mail nebo heslo' : e.message);
    } catch (e) {
      setState(() => _chyba = SpalService.chyba(e));
    } finally {
      if (mounted) setState(() => _pracuji = false);
    }
  }

  Future<void> _zapomenute() async {
    if (!_email.text.contains('@')) {
      setState(() => _chyba = 'Nejdřív napiš svůj e-mail');
      return;
    }
    try {
      await SpalService.zapomenuteHeslo(_email.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Poslali jsme ti e-mail s odkazem na nastavení hesla.')));
      }
    } catch (e) {
      setState(() => _chyba = SpalService.chyba(e));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _heslo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SpalService.dostupne) {
      return const Center(child: Text('Připojení k fitku teď není dostupné. Zkus to později.'));
    }
    final logo = ref.watch(spalInfoProvider).valueOrNull?['logo_base64'] as String?;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (logo != null)
          Center(child: Image.memory(base64Decode(logo), height: 110))
        else
          const Icon(Icons.fitness_center, size: 64, color: spalZluta),
        const SizedBox(height: 16),
        const Text('Přihlášení do fitka',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text(
          'Přihlas se účtem, který ti založili na recepci SPAL Strength Gym – '
          'budeš chodit do fitka přes QR kód, rezervovat tréninky a uvidíš svoje permanentky.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _heslo,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Heslo'),
          onSubmitted: (_) => _prihlasit(),
        ),
        if (_chyba != null) ...[
          const SizedBox(height: 10),
          Text(_chyba!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _pracuji ? null : _prihlasit,
          style: FilledButton.styleFrom(
            backgroundColor: spalTmava,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
          child: _pracuji
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('PŘIHLÁSIT', style: TextStyle(fontSize: 17, letterSpacing: 1)),
        ),
        TextButton(
          onPressed: _pracuji ? null : _zapomenute,
          child: const Text('Zapomenuté heslo / první přihlášení', style: TextStyle(color: spalTmava)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nemáš účet? Požádej na recepci o přístup do aplikace – pošlou ti e-mail s odkazem.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

/// Karta v Profilu Chytrého trenéra: propojení s fitkem SPAL.
class SpalProfilKarta extends ConsumerWidget {
  const SpalProfilKarta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prihlasen = ref.watch(spalPrihlasenProvider).valueOrNull ?? SpalService.prihlasen;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.qr_code_2),
        title: Text(prihlasen ? 'SPAL Strength Gym' : 'Propojit s fitkem SPAL'),
        subtitle: Text(prihlasen
            ? 'QR pro vstup, rezervace, permanentky'
            : 'Vstup do fitka přes QR, rezervace, permanentky a členství'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpalScreen())),
      ),
    );
  }
}
