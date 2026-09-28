import 'package:flutter/material.dart';

/// Jeden návod v nápovědě.
class HelpArticle {
  final String id;
  final IconData icon;
  final String title;
  final String summary;
  final List<(String, String)> steps;

  const HelpArticle({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    required this.steps,
  });
}

/// Obsah nápovědy – krátké návody k jednotlivým částem aplikace.
const helpArticles = <HelpArticle>[
  HelpArticle(
    id: 'start',
    icon: Icons.rocket_launch_outlined,
    title: 'Začínáme',
    summary: 'Jak aplikaci nastavit a co kde najdeš.',
    steps: [
      ('Vyber režim', 'Klient používá aplikaci pro sebe – jídlo, trénink a '
          'pokrok. Trenér/ka spravuje své klienty, jejich plány a měření.'),
      ('Vyplň základní údaje', 'Pohlaví, věk, výška a váha. Z nich aplikace '
          'spočítá energii, makra i tréninkovou zátěž.'),
      ('Zvol cíl', 'Síla, postava, hubnutí nebo vytrvalost. Podle cíle se '
          'nastaví jídelníček i trénink.'),
      ('Hlavní lišta', 'Dnes · Jídlo · Trénink · Pokrok · Profil. Na tabletu '
          'a počítači je lišta po levé straně.'),
      ('Nápověda všude', 'Otazník v horní liště otevře návod k obrazovce, '
          'na které právě jsi.'),
    ],
  ),
  HelpArticle(
    id: 'today',
    icon: Icons.home_outlined,
    title: 'Obrazovka Dnes',
    summary: 'Tvůj den na jednom místě.',
    steps: [
      ('Cesta k cíli', 'Karta nahoře ukazuje, kolik ti chybí do cílové váhy '
          'a jak se ti daří od začátku.'),
      ('Dnešní trénink', 'Tlačítko „Začít trénink“ otevře dnešní cviky. Po '
          'každém cviku zapíšeš váhu a opakování – aplikace navrhne zátěž '
          'na příště.'),
      ('Jídlo dnes', 'Kolik kalorií ti ještě zbývá a jak jsi na tom s '
          'bílkovinami, sacharidy a tuky.'),
      ('Týden', 'Kolečka ukazují, které dny jsi už odtrénoval/a.'),
      ('Rychlé akce', 'Jídelníček, zápis váhy, pokrok a nápověda – vše '
          'jedním klepnutím.'),
    ],
  ),
  HelpArticle(
    id: 'food',
    icon: Icons.restaurant_outlined,
    title: 'Jídlo a jídelníčky',
    summary: 'Zapisování jídla, styly jídelníčků a nákupní seznam.',
    steps: [
      ('Zapsat jídlo', 'Na záložce Jídlo přidáš potravinu nebo hotové jídlo. '
          'Aplikace sčítá kalorie a makra.'),
      ('Dopočítat zbytek dne', 'Aplikace navrhne jídla, která doplní přesně '
          'to, co ti ještě chybí.'),
      ('Styl jídelníčku', 'Lineární, sacharidové vlny, keto nebo přerušovaný '
          'půst. Programy (Hollywood, Bikini…) mají vlastní jídelníček.'),
      ('Vegetarián, vegan, levná varianta', 'Přepínače ve stylu jídelníčku. '
          'Levná varianta používá levné suroviny a večeře je z oběda.'),
      ('Nákupní seznam', 'Z týdenního jídelníčku se sám vytvoří seznam '
          's gramážemi – můžeš ho sdílet.'),
    ],
  ),
  HelpArticle(
    id: 'training',
    icon: Icons.fitness_center_outlined,
    title: 'Trénink a programy',
    summary: 'Tréninkové plány, programy a zapisování výkonů.',
    steps: [
      ('Vlastní plán', 'Vytvoř plán s dny a cviky, nebo vlož hotový program.'),
      ('Programy', 'Hollywood training, Bikini fitness, Kulatý zadek, Ruský '
          'cyklus (bench press) a příprava na trojboj. Stačí zadat datum akce '
          '– váhy a fáze se spočítají samy a jídelníček se nastaví k tomu.'),
      ('Zapisování', 'U každého cviku zapiš váhu a opakování. Z toho se '
          'počítá progres a odhad maxima.'),
      ('Aktivní plán', 'Vždy je aktivní jeden plán – ten se ukazuje na '
          'obrazovce Dnes.'),
    ],
  ),
  HelpArticle(
    id: 'progress',
    icon: Icons.show_chart,
    title: 'Pokrok a měření',
    summary: 'Váha, obvody a výkony v čase.',
    steps: [
      ('Zapsat měření', 'Váhu zapisuj ideálně ráno nalačno, jednou týdně.'),
      ('Obvody', 'Pas, boky, stehno, paže… Měř vždy na stejném místě.'),
      ('Výkony', 'Nejlepší výkony u cviků a jejich vývoj v grafu.'),
    ],
  ),
  HelpArticle(
    id: 'inbody',
    icon: Icons.analytics_outlined,
    title: 'InBody a rozbor postavy',
    summary: 'Jak zadat měření a číst podrobný rozbor.',
    steps: [
      ('Zadání', 'U klienta klepni na „Přidat InBody“ a přepiš hodnoty '
          'z výpisu (váha, svaly, tuk, segmenty…).'),
      ('Kdy měřit', 'Jednou za měsíc, ráno, nalačno, po toaletě a bez '
          'tréninku předem – jen tak jsou měření srovnatelná.'),
      ('Podrobný rozbor', 'Složení těla, zdravotní rizika, symetrie stran, '
          'hydratace, vývoj od minula a cílová váha. Barva ukazuje, co je '
          'v pořádku a co zlepšit.'),
      ('Akční plán', 'Konkrétní kroky pro stravu, trénink a regeneraci podle '
          'výsledků.'),
    ],
  ),
  HelpArticle(
    id: 'clients',
    icon: Icons.groups_outlined,
    title: 'Klienti (pro trenéry)',
    summary: 'Přidání klienta, jeho plán a práce za něj.',
    steps: [
      ('Přidat klienta', 'Na záložce Klienti tlačítko „Přidat klienta“.'),
      ('Plán klienta', 'V detailu klienta nastavíš cíl, jídelníček, trénink '
          'i programy – vše pro daného klienta.'),
      ('Otevřít jako klient', 'Uvidíš aplikaci očima klienta a můžeš za něj '
          'zapisovat.'),
      ('Import / export', 'Zálohy klientů a přenos mezi zařízeními najdeš '
          'v nabídce Import / export.'),
    ],
  ),
  HelpArticle(
    id: 'pdf',
    icon: Icons.picture_as_pdf_outlined,
    title: 'PDF souhrn pro klienta',
    summary: 'Profesionální přehled postavy, tréninku a stravy.',
    steps: [
      ('Kde', 'Detail klienta → Analýza. Vyber období (doporučeno „Od '
          'začátku“).'),
      ('Tisk nebo PDF', 'Ikona tiskárny otevře tisk – můžeš zvolit i „Uložit '
          'jako PDF“. Ikona sdílení pošle PDF e-mailem nebo zprávou.'),
      ('Černobílý tisk', 'Přepínač pro černobílou tiskárnu – bez barevných '
          'ploch, šetří toner.'),
    ],
  ),
  HelpArticle(
    id: 'plan',
    icon: Icons.workspace_premium_outlined,
    title: 'Plná verze a aktivační kód',
    summary: 'Co obsahuje zkušební a plná verze.',
    steps: [
      ('Zkušební doba', 'Prvních 14 dní máš plnou verzi zdarma.'),
      ('Zkušební verze', 'Potom 1 klient a od každé funkce kousek – ať víš, '
          'co aplikace umí.'),
      ('Aktivační kód', 'Nastavení → karta plánu → „Mám aktivační kód“. Kód '
          've tvaru CT-XXXX-XXXX ti dá trenér/ka po zaplacení.'),
      ('Prodloužení', 'Další kód se přičte ke zbývajícímu předplatnému.'),
    ],
  ),
  HelpArticle(
    id: 'settings',
    icon: Icons.palette_outlined,
    title: 'Vzhled a nastavení',
    summary: 'Tmavý režim, barva aplikace a jazyk.',
    steps: [
      ('Světlý / tmavý / auto', 'Auto se řídí nastavením telefonu.'),
      ('Barva aplikace', 'Smaragdová, růžová, fialová, modrá, oranžová nebo '
          'grafitová – změní se celá aplikace.'),
    ],
  ),
  HelpArticle(
    id: 'data',
    icon: Icons.cloud_outlined,
    title: 'Data a zálohy',
    summary: 'Kde jsou data a jak o ně nepřijít.',
    steps: [
      ('Ukládání', 'Data se ukládají přímo v zařízení. Trenérský účet se po '
          'přihlášení zálohuje i do cloudu.'),
      ('Export klienta', 'Záloha obsahuje data, PDF souhrn a tabulky. Dělej '
          'ji pravidelně, hlavně před většími změnami.'),
      ('Import', 'Klienta lze načíst ze zálohy. Při shodě ID se vytvoří nové, '
          'aby se nic nepřepsalo.'),
      ('Tovární nastavení', 'Nevratně smaže všechna data v zařízení. Předtím '
          'vždy exportuj důležité klienty.'),
    ],
  ),
];

/// Centrum nápovědy. S [topic] se rovnou otevře daný návod.
class HelpScreen extends StatefulWidget {
  final String? topic;

  const HelpScreen({super.key, this.topic});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final articles = q.isEmpty
        ? helpArticles
        : helpArticles.where((a) {
            final text = [
              a.title,
              a.summary,
              for (final s in a.steps) '${s.$1} ${s.$2}',
            ].join(' ').toLowerCase();
            return text.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nápověda')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Hledat v nápovědě',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 16),
              if (articles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Nic jsme nenašli. Zkus jiné slovo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              for (final a in articles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      initiallyExpanded:
                          a.id == widget.topic || (q.isNotEmpty),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(a.icon, color: cs.onPrimaryContainer),
                      ),
                      title: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(a.summary),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        for (var i = 0; i < a.steps.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: cs.onPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.steps[i].$1,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        a.steps[i].$2,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Nenašel/nenašla jsi odpověď? Zeptej se svého trenéra '
                'nebo trenérky.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
