import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'spal_menu.dart';
import 'spal_screen.dart';
import 'spal_service.dart';
import 'spal_styl.dart';

/// Můj účet: Depozit · Členství · Permanentky · Vouchery (jako v Clubspire).
class SpalUcet extends ConsumerWidget {
  const SpalUcet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(spalUcetProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'QR kód',
            icon: const Icon(Icons.qr_code_2, size: 32),
            onPressed: () => otevritQr(context),
          ),
          title: const Text('Můj účet'),
          actions: [
            IconButton(
              tooltip: 'Můj profil',
              icon: const Icon(Icons.account_circle, size: 34),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpalProfil())),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: ColoredBox(
              color: spalCerna,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: [Tab(text: 'Depozit'), Tab(text: 'Členství'), Tab(text: 'Permanentky'), Tab(text: 'Vouchery')],
              ),
            ),
          ),
        ),
        body: data.when(
          loading: () => const Center(child: CircularProgressIndicator(color: spalZluta)),
          error: (e, _) => Center(child: Text(SpalService.chyba(e))),
          data: (u) => TabBarView(children: [
            _Depozit(u: u),
            _Seznam(
              polozky: (u['clenstvi'] as List?) ?? const [],
              aktualni: 'Aktuální',
              prazdne: 'Nemáš žádné členství',
              radek: (c) => _Radek(
                nazev: '${c['nazev']}',
                vpravoNahore: c['cena_kc'] == null ? '' : spalKc(c['cena_kc']),
                vlevoDole: c['do'] == null ? 'neomezené' : '${spalDatum(c['od'])} – ${spalDatum(c['do'])}',
              ),
              tlacitko: SpalSpodniTlacitko(
                text: 'Koupit členství',
                ikona: Icons.workspace_premium_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KoupitClenstvi())),
              ),
            ),
            _Seznam(
              polozky: (u['permanentky'] as List?) ?? const [],
              aktualni: 'Aktuální',
              prazdne: 'Nemáš žádnou permanentku',
              radek: (p) => _Radek(
                nazev: '${p['nazev']}',
                vpravoNahore: spalKc(p['cena_kc']),
                vlevoDole: [
                  if (p['druh'] == 'vstupova') 'zbývá ${p['zbyva']} vstupů',
                  if (p['pozastaveno'] == true) 'pozastavená',
                ].join(' · '),
                vpravoDole: p['do'] == null ? spalDatum(p['od']) : 'do ${spalDatum(p['do'])}',
              ),
              tlacitko: SpalSpodniTlacitko(
                text: 'Koupit permanentku',
                ikona: Icons.confirmation_number_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KoupitPermanentku())),
              ),
            ),
            _Seznam(
              polozky: [
                for (final v in (u['vouchery'] as List?) ?? const [])
                  {...Map<String, dynamic>.from(v as Map), 'aktualni': v['stav'] == 'platny'}
              ],
              aktualni: 'Nepoužité',
              historie: 'Použité',
              prazdne: 'Nemáš žádný voucher',
              radek: (v) => _Radek(
                nazev: '${v['obsah'] ?? 'Voucher'}',
                vpravoNahore: '${v['cislo']}',
                vlevoDole: [
                  if (v['od'] != null) spalDatum(v['od']),
                  if (v['do'] != null) spalDatum(v['do']),
                ].join(' - '),
              ),
              tlacitko: SpalSpodniTlacitko(
                text: 'Koupit voucher',
                ikona: Icons.card_giftcard,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KoupitVoucher())),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Depozit extends StatelessWidget {
  const _Depozit({required this.u});
  final Map<String, dynamic> u;

  static String _druh(String? d) => switch (d) {
        'dobiti' => 'vklad',
        'cerpani' => 'výběr',
        'vraceni' => 'výběr zůstatku depozitu',
        'expirace' => 'propadnutí',
        'voucher' => 'voucher',
        'import' => 'převod z Clubspire',
        'storno' => 'storno',
        _ => 'oprava',
      };

  @override
  Widget build(BuildContext context) {
    final pohyby = (u['depozit_pohyby'] as List?) ?? const [];
    return ListView(children: [
      const SizedBox(height: 16),
      const Text('Aktuální stav depozitu',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Center(
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: const Color(0xFF2ECC40),
          child: Text(spalKc(u['depozit_kc']),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ),
      ),
      const SizedBox(height: 10),
      Text(u['depozit_platny_do'] == null ? 'Platný neomezeně' : 'Platný do ${spalDatum(u['depozit_platny_do'])}',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
      const Divider(height: 28, indent: 12, endIndent: 12),
      for (final p in pohyby)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
          child: Row(children: [
            Expanded(child: Text(spalDatum(p['kdy']), style: const TextStyle(fontSize: 17))),
            Expanded(
              flex: 2,
              child: Text(_druh(p['druh'] as String?),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
            ),
            Expanded(
              child: Text(
                '${((p['castka'] as num?) ?? 0) >= 0 ? '+' : ''}${spalKc(p['castka'])}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 17,
                  color: ((p['castka'] as num?) ?? 0) >= 0 ? Colors.green.shade600 : Colors.red,
                ),
              ),
            ),
          ]),
        ),
      if (pohyby.isEmpty)
        const Padding(padding: EdgeInsets.all(20), child: Text('Zatím žádné pohyby na depozitu.')),
      const SizedBox(height: 90),
    ]);
  }
}

class _Seznam extends StatelessWidget {
  const _Seznam({
    required this.polozky,
    required this.radek,
    required this.tlacitko,
    required this.aktualni,
    required this.prazdne,
    this.historie = 'Historie',
  });
  final List polozky;
  final Widget Function(Map<String, dynamic>) radek;
  final Widget tlacitko;
  final String aktualni;
  final String historie;
  final String prazdne;

  @override
  Widget build(BuildContext context) {
    final vse = [for (final p in polozky) Map<String, dynamic>.from(p as Map)];
    final akt = vse.where((p) => p['aktualni'] == true).toList();
    final hist = vse.where((p) => p['aktualni'] != true).toList();
    return Column(children: [
      Expanded(
        child: ListView(children: [
          if (akt.isNotEmpty) ...[SpalNadpis(aktualni), for (final p in akt) radek(p)],
          if (hist.isNotEmpty) ...[SpalNadpis(historie), for (final p in hist) radek(p)],
          if (vse.isEmpty)
            Padding(padding: const EdgeInsets.all(24), child: Text(prazdne, style: const TextStyle(fontSize: 17))),
        ]),
      ),
      tlacitko,
      const SizedBox(height: 72), // místo pro spodní lištu s „+“
    ]);
  }
}

class _Radek extends StatelessWidget {
  const _Radek({required this.nazev, this.vpravoNahore = '', this.vlevoDole = '', this.vpravoDole = ''});
  final String nazev;
  final String vpravoNahore;
  final String vlevoDole;
  final String vpravoDole;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(nazev, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
            Text(vpravoNahore, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ]),
          if (vlevoDole.isNotEmpty || vpravoDole.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Text(vlevoDole, style: const TextStyle(fontSize: 17))),
              Text(vpravoDole, style: const TextStyle(fontSize: 17)),
            ]),
          ],
        ]),
      );
}

// ---------------------------------------------------------------------
// Koupit členství / permanentku / voucher
// ---------------------------------------------------------------------

const _brzyGoPay = 'Platba kartou v aplikaci (GoPay) bude spuštěna brzy. '
    'Zatím si členství nebo permanentku kup na recepci.';

class _Nakup extends StatelessWidget {
  const _Nakup({required this.titulek, required this.deti});
  final String titulek;
  final List<Widget> deti;

  @override
  Widget build(BuildContext context) => Theme(
        data: spalTema(context),
        child: Scaffold(
          appBar: AppBar(title: Text(titulek)),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            ...deti,
            const SizedBox(height: 24),
            const Text('Zaplacením souhlasíte s obchodními podmínkami.',
                style: TextStyle(decoration: TextDecoration.underline)),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: spalTmava,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: null,
              icon: const Icon(Icons.credit_card),
              label: const Text('ZAPLATIT KARTOU'),
            ),
            const SizedBox(height: 10),
            const Text(_brzyGoPay, style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
}

Widget _vyber<T>({
  required String popis,
  required T? hodnota,
  required List<T> moznosti,
  required String Function(T) text,
  required ValueChanged<T?> onChanged,
}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(popis, style: const TextStyle(color: spalZluta, fontSize: 21, fontWeight: FontWeight.w800)),
      DropdownButton<T>(
        value: hodnota,
        isExpanded: true,
        iconEnabledColor: spalZluta,
        iconSize: 36,
        underline: Container(height: 2, color: spalZluta),
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: spalCerna),
        items: [for (final m in moznosti) DropdownMenuItem(value: m, child: Text(text(m)))],
        onChanged: onChanged,
      ),
    ]);

Widget _udaj(String a, String b, {bool zlute = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(a, style: const TextStyle(fontSize: 19))),
        Text(b, style: TextStyle(fontSize: 19, color: zlute ? spalZluta : spalCerna)),
      ]),
    );

class KoupitPermanentku extends ConsumerStatefulWidget {
  const KoupitPermanentku({super.key});
  @override
  ConsumerState<KoupitPermanentku> createState() => _KoupitPermanentkuState();
}

class _KoupitPermanentkuState extends ConsumerState<KoupitPermanentku> {
  late final Future<Map<String, dynamic>> _data = SpalService.nabidka();
  int? _vybrana; // id typu (mapy se při každém načtení mění)

  String _platnost(Map<String, dynamic> p) => p['platnost_mesicu'] != null
      ? '${p['platnost_mesicu']} ${(p['platnost_mesicu'] as num) == 1 ? 'měsíc' : (p['platnost_mesicu'] as num) < 5 ? 'měsíce' : 'měsíců'}'
      : p['platnost_dni'] != null
          ? '${p['platnost_dni']} dní'
          : 'neomezeně';

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _data,
        builder: (context, snap) {
          final seznam = [
            for (final p in (snap.data?['permanentky'] as List?) ?? const []) Map<String, dynamic>.from(p as Map)
          ];
          final p = seznam.where((x) => x['id'] == _vybrana).firstOrNull ?? (seznam.isEmpty ? null : seznam.first);
          return _Nakup(titulek: 'Koupit permanentku', deti: [
            if (snap.hasError) Text(SpalService.chyba(snap.error!)),
            if (!snap.hasData && !snap.hasError) const LinearProgressIndicator(color: spalZluta),
            if (snap.hasData && seznam.isEmpty) const Text('Teď není v nabídce žádná permanentka.'),
            if (p != null) ...[
              _vyber<int>(
                popis: 'Vyberte permanentku',
                hodnota: p['id'] as int,
                moznosti: [for (final x in seznam) x['id'] as int],
                text: (id) => '${seznam.firstWhere((x) => x['id'] == id)['nazev']}',
                onChanged: (id) => setState(() => _vybrana = id),
              ),
              const SizedBox(height: 10),
              _udaj('Platnost', _platnost(p)),
              _udaj('Cena', spalKc(p['cena_kc']), zlute: true),
              if (p['druh'] == 'vstupova') _udaj('Obsahuje', '${p['pocet_vstupu']}× vstup do posilovny'),
              if (p['popis'] != null) Text('${p['popis']}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              const Text('Platná od', style: TextStyle(color: spalZluta, fontSize: 20)),
              Text(spalDatum(DateTime.now()), style: const TextStyle(fontSize: 21)),
              Container(height: 2, color: spalZluta),
            ],
          ]);
        },
      );
}

class KoupitClenstvi extends ConsumerStatefulWidget {
  const KoupitClenstvi({super.key});
  @override
  ConsumerState<KoupitClenstvi> createState() => _KoupitClenstviState();
}

class _KoupitClenstviState extends ConsumerState<KoupitClenstvi> {
  late final Future<Map<String, dynamic>> _data = SpalService.nabidka();
  int? _vybrane;
  DateTime _od = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _data,
        builder: (context, snap) {
          final seznam = [
            for (final c in (snap.data?['clenstvi'] as List?) ?? const []) Map<String, dynamic>.from(c as Map)
          ];
          final c = seznam.where((x) => x['id'] == _vybrane).firstOrNull ?? (seznam.isEmpty ? null : seznam.first);
          return _Nakup(titulek: 'Koupit členství', deti: [
            if (snap.hasError) Text(SpalService.chyba(snap.error!)),
            if (!snap.hasData && !snap.hasError) const LinearProgressIndicator(color: spalZluta),
            if (snap.hasData && seznam.isEmpty) const Text('Teď není v nabídce žádné členství.'),
            if (c != null) ...[
              _vyber<int>(
                popis: 'Vyberte členství',
                hodnota: c['id'] as int,
                moznosti: [for (final x in seznam) x['id'] as int],
                text: (id) => '${seznam.firstWhere((x) => x['id'] == id)['nazev']}',
                onChanged: (id) => setState(() => _vybrane = id),
              ),
              const SizedBox(height: 16),
              const Text('Typ členství', style: TextStyle(color: spalZluta, fontSize: 21, fontWeight: FontWeight.w800)),
              Text('${c['delka_mesicu']} měsíc(ů)', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              Container(height: 2, color: spalZluta),
              const SizedBox(height: 10),
              _udaj('cena', spalKc(c['cena_kc']), zlute: true),
              if (c['popis'] != null) Text('${c['popis']}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              const Text('Platné od', style: TextStyle(color: spalZluta, fontSize: 20)),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _od,
                    firstDate: DateUtils.dateOnly(DateTime.now()),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (d != null) setState(() => _od = d);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(spalDatum(_od), style: const TextStyle(fontSize: 21)),
                ),
              ),
              Container(height: 2, color: spalZluta),
            ],
          ]);
        },
      );
}

class KoupitVoucher extends StatefulWidget {
  const KoupitVoucher({super.key});
  @override
  State<KoupitVoucher> createState() => _KoupitVoucherState();
}

class _KoupitVoucherState extends State<KoupitVoucher> {
  int _castka = 500;

  @override
  Widget build(BuildContext context) => _Nakup(titulek: 'Koupit voucher', deti: [
        _vyber<int>(
          popis: 'Voucher na částku',
          hodnota: _castka,
          moznosti: const [300, 500, 1000, 2000],
          text: (x) => spalKc(x),
          onChanged: (x) => setState(() => _castka = x ?? 500),
        ),
        const SizedBox(height: 10),
        _udaj('Platnost', '6 měsíců'),
        _udaj('Cena', spalKc(_castka), zlute: true),
        const SizedBox(height: 8),
        const Text('Dárkový poukaz ti přijde e-mailem jako PDF k vytištění.', style: TextStyle(color: Colors.grey)),
      ]);
}
