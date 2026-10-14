import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'spal_service.dart';
import 'spal_styl.dart';

/// „+“ → Zvolte aktivitu → časy → potvrzení rezervace (jako v Clubspire).
void otevritNovouRezervaci(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Theme(data: spalTema(context), child: const _ZvolteAktivitu())),
    );

IconData _ikonaArealu(String? ikona) => switch (ikona) {
      'masaz' => Icons.spa,
      _ => Icons.sports_gymnastics,
    };

// ---------------------------------------------------------------------
// Zvolte aktivitu
// ---------------------------------------------------------------------

class _ZvolteAktivitu extends StatefulWidget {
  const _ZvolteAktivitu();
  @override
  State<_ZvolteAktivitu> createState() => _ZvolteAktivituState();
}

class _ZvolteAktivituState extends State<_ZvolteAktivitu> {
  late final Future<List<Map<String, dynamic>>> _data = SpalService.rezNabidka();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zvolte aktivitu')),
      body: FutureBuilder(
        future: _data,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(SpalService.chyba(snap.error!)));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: spalZluta));
          final arealy = snap.data!;
          if (arealy.isEmpty) return const Center(child: Text('Teď nejde nic rezervovat přes aplikaci.'));
          return GridView.count(
            padding: const EdgeInsets.all(10),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final a in arealy)
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Theme(data: spalTema(context), child: _VolneTerminy(areal: a)),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_ikonaArealu(a['ikona'] as String?), color: spalZluta, size: 76),
                      const SizedBox(height: 18),
                      Text('${a['nazev']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: spalZluta, fontSize: 20, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Volné termíny: datum, záložky trenérů, časy po hodinách
// ---------------------------------------------------------------------

class _VolneTerminy extends StatefulWidget {
  const _VolneTerminy({required this.areal});
  final Map<String, dynamic> areal;
  @override
  State<_VolneTerminy> createState() => _VolneTerminyState();
}

class _VolneTerminyState extends State<_VolneTerminy> {
  late DateTime _den = DateUtils.dateOnly(DateTime.now());
  final Map<String, Future<List<DateTime>>> _cache = {};

  List<Map<String, dynamic>> get _objekty =>
      [for (final o in (widget.areal['objekty'] as List)) Map<String, dynamic>.from(o as Map)];

  Future<List<DateTime>> _volne(int objekt) =>
      _cache.putIfAbsent('$objekt-${_den.toIso8601String()}', () => SpalService.volne(objekt, _den));

  void _posun(int dny) {
    final novy = _den.add(Duration(days: dny));
    if (novy.isBefore(DateUtils.dateOnly(DateTime.now()))) return;
    setState(() => _den = novy);
  }

  @override
  Widget build(BuildContext context) {
    final objekty = _objekty;
    return DefaultTabController(
      length: objekty.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.areal['nazev']}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month, size: 30),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _den,
                  firstDate: DateUtils.dateOnly(DateTime.now()),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (d != null) setState(() => _den = d);
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: Container(
              color: spalCerna,
              child: Column(children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                    onPressed: () => _posun(-1),
                  ),
                  Expanded(
                    child: Text(
                      '${spalDny[_den.weekday - 1]} ${_den.day}.${_den.month}.${_den.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                    onPressed: () => _posun(1),
                  ),
                ]),
                TabBar(
                  isScrollable: objekty.length > 2,
                  tabAlignment: objekty.length > 2 ? TabAlignment.center : TabAlignment.fill,
                  tabs: [for (final o in objekty) Tab(text: '${o['nazev']}')],
                ),
              ]),
            ),
          ),
        ),
        body: TabBarView(children: [
          for (final o in objekty)
            FutureBuilder(
              key: ValueKey('${o['id']}-$_den'),
              future: _volne(o['id'] as int),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text(SpalService.chyba(snap.error!)));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: spalZluta));
                final casy = snap.data!;
                if (casy.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Tento den není volný termín.\nZkus jiný den šipkou nahoře.',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 17)),
                    ),
                  );
                }
                final hodiny = <int, List<DateTime>>{};
                for (final c in casy) {
                  hodiny.putIfAbsent(c.hour, () => []).add(c);
                }
                return ListView(padding: const EdgeInsets.symmetric(horizontal: 14), children: [
                  for (final h in hodiny.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(h.key.toString().padLeft(2, '0'),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    ),
                    const Divider(color: spalCerna, thickness: 1.5, height: 10),
                    Wrap(spacing: 12, runSpacing: 10, children: [
                      for (final c in h.value)
                        SizedBox(
                          width: (MediaQuery.sizeOf(context).width - 40) / 2,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: spalCerna,
                              shape: const RoundedRectangleBorder(),
                              side: BorderSide(color: Colors.grey.shade500),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Theme(
                                  data: spalTema(context),
                                  child: _PotvrzeniRezervace(objekt: o, zacatek: c),
                                ),
                              ),
                            ),
                            child: Text(spalCas(c), style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 24),
                ]);
              },
            ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Potvrzení rezervace
// ---------------------------------------------------------------------

class _PotvrzeniRezervace extends ConsumerStatefulWidget {
  const _PotvrzeniRezervace({required this.objekt, required this.zacatek});
  final Map<String, dynamic> objekt;
  final DateTime zacatek;
  @override
  ConsumerState<_PotvrzeniRezervace> createState() => _PotvrzeniRezervaceState();
}

class _PotvrzeniRezervaceState extends ConsumerState<_PotvrzeniRezervace> {
  final _poznamka = TextEditingController();
  late final List<Map<String, dynamic>> _cinnosti = [
    for (final c in (widget.objekt['cinnosti'] as List)) Map<String, dynamic>.from(c as Map)
  ];
  late Map<String, dynamic> _cinnost = _cinnosti.first;
  bool _pracuji = false;

  Future<void> _rezervovat() async {
    setState(() => _pracuji = true);
    try {
      await SpalService.rezervovat(
          widget.objekt['id'] as int, _cinnost['id'] as int, widget.zacatek, _poznamka.text);
      spalObnovit(ref);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Rezervace vytvořena'),
          content: Text('${_cinnost['nazev']}\n${spalDatum(widget.zacatek)} v ${spalCas(widget.zacatek)}'
              '${(_cinnost['cena_kc'] as num? ?? 0) > 0 ? '\n\nCenu zaplatíš na recepci.' : ''}'),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
      // zpět na přehled fitka (zavřít potvrzení, termíny a výběr aktivity)
      var n = 0;
      if (mounted) Navigator.of(context).popUntil((r) => n++ >= 3 || r.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _pracuji = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(SpalService.chyba(e))));
      }
    }
  }

  @override
  void dispose() {
    _poznamka.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delka = (_cinnost['delka_min'] as num?)?.toInt() ?? 60;
    final konec = widget.zacatek.add(Duration(minutes: delka));
    final cena = (_cinnost['cena_kc'] as num?) ?? 0;
    Widget radek(IconData i, String t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Icon(i, color: spalZluta, size: 26),
            const SizedBox(width: 14),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 17))),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Rezervace')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          const Icon(Icons.sports_gymnastics, color: spalZluta, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${_cinnost['nazev']}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          ),
        ]),
        const Divider(height: 24),
        if (_cinnosti.length > 1)
          DropdownButtonFormField<int>(
            value: _cinnost['id'] as int,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Činnost'),
            items: [
              for (final c in _cinnosti)
                DropdownMenuItem(value: c['id'] as int, child: Text('${c['nazev']}  (${spalKc(c['cena_kc'])})')),
            ],
            onChanged: (v) => setState(() => _cinnost = _cinnosti.firstWhere((c) => c['id'] == v)),
          )
        else
          radek(Icons.sports_gymnastics, '${_cinnost['nazev']}'),
        radek(Icons.event, '${spalDatum(widget.zacatek)} ${spalCas(widget.zacatek)} – ${spalCas(konec)}'),
        radek(Icons.dashboard, '${widget.objekt['nazev']}'),
        radek(Icons.attach_money, '${spalKc(cena)}/osoba'),
        const SizedBox(height: 40),
        TextField(
          controller: _poznamka,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Poznámka', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        Row(children: [
          const Text('Celkem', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(spalKc(cena), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: spalTmava,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: _pracuji ? null : _rezervovat,
          child: _pracuji
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('REZERVOVAT', style: TextStyle(fontSize: 17, letterSpacing: 1.2)),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------
// Moje rezervace (záložka Rezervace)
// ---------------------------------------------------------------------

class SpalMojeRezervace extends ConsumerWidget {
  const SpalMojeRezervace({super.key});

  Future<void> _zrusit(BuildContext context, WidgetRef ref, Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Zrušit rezervaci?'),
        content: Text('${r['nazev']}\n${spalDatum(r['zacatek'])} '
            '${spalCas(DateTime.parse(r['zacatek'] as String).toLocal())}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ne')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Zrušit rezervaci')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SpalService.zrusitRezervaci(r['id'] as int);
      spalObnovit(ref);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(SpalService.chyba(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(spalRezervaceProvider);
    final storno = ref.watch(spalInfoProvider).valueOrNull?['storno_hodin'];
    return Scaffold(
      appBar: AppBar(title: const Text('Moje rezervace'), automaticallyImplyLeading: false),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator(color: spalZluta)),
        error: (e, _) => Center(child: Text(SpalService.chyba(e))),
        data: (rez) {
          final ted = DateTime.now();
          final budouci = rez
              .where((r) => r['stav'] == 'aktivni' && DateTime.parse(r['konec'] as String).isAfter(ted))
              .toList()
            ..sort((a, b) => (a['zacatek'] as String).compareTo(b['zacatek'] as String));
          final historie = rez.where((r) => !budouci.contains(r)).toList();
          Widget polozka(Map<String, dynamic> r, {bool aktivni = false}) {
            final z = DateTime.parse(r['zacatek'] as String).toLocal();
            final k = DateTime.parse(r['konec'] as String).toLocal();
            final zrusena = r['stav'] != 'aktivni';
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${r['nazev']}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        decoration: zrusena ? TextDecoration.lineThrough : null)),
                subtitle: Text(
                    '${spalDny[z.weekday - 1]} ${spalDatum(z)} ${spalCas(z)}–${spalCas(k)} · ${r['objekt']}'
                    '${zrusena ? ' · zrušeno' : ''}',
                    style: const TextStyle(fontSize: 15)),
                trailing: aktivni && r['lze_zrusit'] == true
                    ? TextButton(onPressed: () => _zrusit(context, ref, r), child: const Text('Zrušit'))
                    : null,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => spalObnovit(ref),
            child: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
              const SpalNadpis('Nadcházející'),
              if (budouci.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text('Nemáte žádné rezervace. Novou vytvoříte tlačítkem +.',
                      style: TextStyle(fontSize: 16)),
                ),
              for (final r in budouci) polozka(r, aktivni: true),
              if (storno != null && budouci.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text('Zrušit jde nejpozději $storno h před začátkem, později jen přes recepci.',
                      style: const TextStyle(color: Colors.grey)),
                ),
              if (historie.isNotEmpty) ...[
                const SpalNadpis('Historie'),
                for (final r in historie) polozka(r),
              ],
            ]),
          );
        },
      ),
    );
  }
}
