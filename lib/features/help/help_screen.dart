import '../common/about_app.dart';
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
          'pokrok. Trenér/ka spravuje klienty, jejich plány, měření a online '
          'koučink. Trenérský režim je chráněný přihlášením a PINem.'),
      ('Mám pozvánku od trenéra', 'Když ti trenér/ka poslal/a kód, zvol na '
          'úvodní obrazovce „Mám pozvánku od trenéra“. Víc v návodu '
          '„Připojení k trenérovi“.'),
      ('Vyplň základní údaje', 'Pohlaví, věk, výška a váha. Z nich aplikace '
          'spočítá energii, makra i tréninkovou zátěž.'),
      ('Zvol cíl', 'Síla, postava, hubnutí nebo vytrvalost. Podle cíle se '
          'nastaví jídelníček i trénink.'),
      ('Hlavní lišta', 'Klient: Dnes · Jídlo · Trénink · Pokrok · Profil. '
          'Trenér: Přehled · Klienti · Nastavení. Na tabletu a počítači je '
          'lišta vlevo a vpravo je panel s přehledem.'),
      ('Nápověda všude', 'Otazník v horní liště otevře návod k obrazovce, '
          'na které právě jsi. Nahoře v nápovědě můžeš i vyhledávat.'),
    ],
  ),

  // ----------------------------------------------------------------
  // ONLINE KOUČINK
  // ----------------------------------------------------------------
  HelpArticle(
    id: 'online',
    icon: Icons.phonelink_ring_outlined,
    title: 'Online koučink – propojení s klientem (trenér)',
    summary: 'Jak klienta pozvat, co uvidí a co se sdílí.',
    steps: [
      ('Co to je', 'Klient má aplikaci ve svém telefonu a je propojený s '
          'tebou. Posíláš mu tréninky a jídelníčky, on zapisuje výkony, jídlo '
          'a váhu a vy dva si píšete zprávy. Všechno se synchronizuje přes '
          'zabezpečený cloud.'),
      ('1. Pozvánka', 'Klienti → vyber klienta → záložka Přehled → karta '
          '„Online coaching“ → „Pozvat klienta do aplikace“. Vytvoří se kód '
          've tvaru KL-XXXX-XXXX.'),
      ('2. Pošli kód', 'V okně pozvánky klikni na „Kopírovat zprávu“ a vlož '
          'ji klientovi do WhatsAppu, Messengeru nebo SMS. Zpráva obsahuje '
          'návod i kód. Kód platí jen pro tohoto klienta a jde použít jednou.'),
      ('3. Klient se připojí', 'Klient si nainstaluje aplikaci, zvolí „Mám '
          'pozvánku od trenéra“, zadá kód a potvrdí souhlas se sdílením. '
          'Karta u klienta se pak přepne na zelené „Připojeno“.'),
      ('Co klient uvidí', 'Tréninky, které mu pošleš (jen na dny, které '
          'určíš – nikdy celý plán), jídelníčky, které mu uložíš, své cíle, '
          'měření a zprávy od tebe. Tvoje šablony, poznámky a ostatní '
          'klienty nevidí.'),
      ('Co uvidíš ty', 'Odcvičené tréninky s váhami a opakováními, jeho '
          'poznámky, zapsané jídlo, váhu a zprávy. Na Přehledu trenéra je '
          'karta „Online klienti“ s tím, co je potřeba řešit.'),
      ('Synchronizace', 'Probíhá sama – po každé změně, při otevření '
          'aplikace a každé 2 minuty. Tlačítko „Synchronizovat teď“ ji '
          'spustí hned.'),
      ('Nový kód / zrušení', 'Dokud se klient nepřipojí, můžeš vytvořit '
          'nový kód nebo pozvánku zrušit. „Ukončit coaching“ klienta odpojí; '
          'data u tebe zůstanou.'),
    ],
  ),
  HelpArticle(
    id: 'online_client',
    icon: Icons.link,
    title: 'Připojení k trenérovi (klient)',
    summary: 'Jak se připojit kódem a jak spolupráce funguje.',
    steps: [
      ('Instalace', 'Nainstaluj si aplikaci Chytrý trenér podle odkazu, '
          'který ti poslal/a trenér/ka.'),
      ('Zadej kód', 'Na úvodní obrazovce zvol „Mám pozvánku od trenéra“ '
          '(nebo Profil → „Mám pozvánku od trenéra“). Opiš kód '
          'KL-XXXX-XXXX – na velikosti písmen a pomlčkách nezáleží.'),
      ('Souhlas', 'Potvrď, že trenér uvidí, co zapíšeš (jídlo, tréninky, '
          'váha, měření). Souhlas můžeš kdykoli odvolat odpojením.'),
      ('Dnešní trénink', 'Na obrazovce Dnes a v záložce Trénink uvidíš '
          'tréninky od trenéra. Klepni na „Začít trénink“, u každé série '
          'zapiš kg a opakování, zaškrtni ji a nakonec „Odeslat trenérovi“.'),
      ('Jídelníček od trenéra', 'Najdeš ho nahoře v záložce Jídlo. Můžeš '
          'si ho vytisknout nebo uložit jako PDF.'),
      ('Zprávy', 'Karta „Zprávy s trenérem“ na obrazovce Dnes. Číslo '
          'u ikony ukazuje nepřečtené zprávy.'),
      ('Na co nezapomenout', 'Na obrazovce Dnes tě aplikace upozorní na '
          'týdenní check-in a na tréninky, které jsi ještě neodeslal/a.'),
      ('Nic nového nevidím?', 'Stáhni obrazovku dolů, nebo Profil → '
          '„Synchronizovat“. Potřebuješ připojení k internetu.'),
      ('Odpojení', 'Profil → karta trenéra → „Odpojit“. Data v telefonu '
          'ti zůstanou.'),
    ],
  ),
  HelpArticle(
    id: 'workouts',
    icon: Icons.send_outlined,
    title: 'Posílání tréninků online klientovi',
    summary: 'Trénink na dnešek nebo na týden dopředu – po kouskách.',
    steps: [
      ('Proč po kouskách', 'Klient nikdy nedostane celý plán najednou – '
          'jen jednotlivé tréninky na konkrétní dny (max. 7 dní dopředu). '
          'Plán tak nejde „odnést“ a zneužít.'),
      ('Kde', 'Klienti → klient → záložka Trénink → karta „Tréninky pro '
          'klienta“ → „Poslat trénink“. Klient musí mít tréninkový plán '
          '(Trénink → Programy).'),
      ('Co poslat', 'Vyber den plánu (např. Trénink A), datum (Dnes, '
          'zítra…) a případně vzkaz. Můžeš vybrat víc dní a víc tréninků '
          'najednou – spárují se v pořadí, jak je vybereš.'),
      ('Výsledky', 'Když klient trénink odešle, objeví se „✓ odcvičeno“. '
          'Klepnutím uvidíš série, váhy a jeho poznámku. Nejlepší výkony se '
          'mu uloží do výkonů u cviků.'),
      ('Neodcvičené', 'Tréninky z minulých dnů, které klient neodeslal, '
          'uvidíš v kartě „Online klienti“ na Přehledu.'),
      ('Celý týden', 'Vyber víc tréninků (např. A, B, C) a klikni '
          '„Rozvrhnout do týdne“ – dny se nastaví samy (dnes, za 2 a za 4 '
          'dny). Dny můžeš ještě upravit.'),
      ('Více klientům', 'V okně „Poslat trénink“ v části 3) označ další '
          'online klienty – dostanou stejné tréninky.'),
      ('Smazání', 'Poslaný trénink, který ještě nebyl odcvičený, můžeš '
          'smazat ikonou koše.'),
    ],
  ),
  HelpArticle(
    id: 'calendar',
    icon: Icons.calendar_month_outlined,
    title: 'Kalendář tréninků a masáží',
    summary: 'Termíny na týden, opakování a odečet z permanentky.',
    steps: [
      ('Kde', 'Záložka Kalendář (v liště vlevo / dole). Dnešní termíny '
          'vidíš i na Přehledu trenéra.'),
      ('Nový termín', '„+ Termín“ nebo + u konkrétního dne. Vyber klienta, '
          'druh (trénink, masáž, konzultace), den, čas a délku. „Opakovat '
          'každý týden“ vytvoří termíny na 4, 8 nebo 12 týdnů najednou.'),
      ('Po tréninku', 'Klepni na termín → „Proběhlo“. Má-li klient '
          'permanentku, rovnou se odečte vstup (masáž z masážní, trénink '
          'z tréninkové).'),
      ('Zrušení', '„Zrušeno / omluveno“ – termín zůstane přeškrtnutý, '
          'vstup se neodečte.'),
      ('U klienta', 'Karta „Permanentky a platby“ → „Naplánovat termín“.'),
    ],
  ),
  HelpArticle(
    id: 'income',
    icon: Icons.bar_chart,
    title: 'Příjmy a statistiky',
    summary: 'Kolik jsi vydělal/a za měsíc, čtvrtletí a rok.',
    steps: [
      ('Kde', 'Nastavení → „Příjmy a statistiky“, nebo na Přehledu v kartě '
          'Permanentky → „Příjmy a grafy“.'),
      ('Co se počítá', 'Zaplacené permanentky s cenou (podle data zaplacení) '
          'a jednorázové platby.'),
      ('Jednorázová platba', 'Tlačítko „Platba“ – částka, za co (trénink, '
          'masáž, koučink, jídelníček), klient a datum. Jde přidat i u '
          'klienta v kartě Permanentky.'),
      ('Porovnání', 'Přepínač Měsíc / Čtvrtletí / Rok a šipky pro posun. '
          'Uvidíš rozdíl oproti minulému období i stejnému období loni.'),
      ('Graf', 'Posledních 12 měsíců, průměr za měsíc, rozpad podle služeb '
          'a podle klientů.'),
    ],
  ),
  HelpArticle(
    id: 'videos',
    icon: Icons.play_circle_outline,
    title: 'Videa s technikou cviků',
    summary: 'Odkaz na video u každého cviku pro klienta.',
    steps: [
      ('Kde', 'Nastavení → „Videa ke cvikům“. Seznam obsahuje cviky ze '
          'všech tréninkových plánů.'),
      ('Přidat', 'Klepni na cvik a vlož odkaz (Instagram: u příspěvku ⋯ → '
          'Kopírovat odkaz). „Vyzkoušet“ ho rovnou otevře.'),
      ('Klient', 'U cviku v tréninku uvidí „Technika – video“. Odkazy se '
          'přidají k tréninkům, které pošleš po jejich uložení.'),
    ],
  ),
  HelpArticle(
    id: 'passes',
    icon: Icons.confirmation_number_outlined,
    title: 'Permanentky a platby',
    summary: 'Vstupy, předplatné koučinku, kdo zaplatil a komu co dochází.',
    steps: [
      ('Nová permanentka', 'Klient → Přehled → karta „Permanentky a platby“ '
          '→ +. Rychlý výběr: osobní trénink 10/5 vstupů, masáž 5×, online '
          'koučink 1/3 měsíce, jídelníček. Vše jde upravit.'),
      ('Dva typy', 'Počet vstupů (trénink, masáž) – po každém tréninku '
          'klikni „Odečíst vstup“. Časové období (online koučink) – platí '
          'od–do.'),
      ('Omyl?', 'Po odečtení je v oznámení tlačítko „Vrátit“, případně '
          'v menu permanentky „Vrátit poslední vstup“.'),
      ('Platba', 'Přepínač „Zaplaceno“ nebo tlačítko „Zaplaceno“ u '
          'permanentky. Nezaplacené svítí červeně.'),
      ('Přehled', 'Na Přehledu trenéra karta „Permanentky a platby“: '
          'zaplaceno tento měsíc, nezaplacené, komu zbývají max. 2 vstupy '
          'nebo končí platnost do 7 dní a co nedávno vypršelo.'),
      ('Záloha', 'Permanentky se zálohují do cloudu s ostatními daty. '
          'Klient je zatím nevidí.'),
    ],
  ),
  HelpArticle(
    id: 'checkin',
    icon: Icons.fact_check_outlined,
    title: 'Týdenní check-in',
    summary: 'Jednou týdně váha a jak se klient cítí.',
    steps: [
      ('Klient', 'Na obrazovce Dnes se po 7 dnech objeví „Týdenní check-in“ '
          '(nebo Profil → „Týdenní check-in“). Vyplní váhu, spánek, energii, '
          'hlad, stres a dodržování jídelníčku (1–5) a vzkaz.'),
      ('Váha', 'Váha z check-inu se uloží i do profilu klienta, takže se '
          'podle ní počítají jídelníčky.'),
      ('Trenér', 'Klient → Přehled → karta „Týdenní check-in“: posledních '
          '6 check-inů, změna váhy a barevné hodnocení (zelená = dobré, '
          'oranžová = průměr, červená = problém).'),
      ('Chybí check-in', 'Na Přehledu v kartě „Online klienti“ uvidíš „Check-in '
          'chybí“. Tlačítko „Připomenout“ otevře zprávy s klientem.'),
    ],
  ),
  HelpArticle(
    id: 'chat',
    icon: Icons.chat_bubble_outline,
    title: 'Zprávy trenér ↔ klient',
    summary: 'Psaní si přímo v aplikaci.',
    steps: [
      ('Trenér', 'V detailu klienta ikona bubliny vpravo nahoře, nebo '
          'v kartě „Online klienti“ na Přehledu. Číslo = nepřečtené zprávy.'),
      ('Klient', 'Obrazovka Dnes → „Zprávy s trenérem“, nebo Profil → '
          '„Napsat trenérovi“.'),
      ('Přečteno', 'Jedna fajfka = odesláno, dvě = druhá strana si zprávu '
          'přečetla.'),
      ('Rychlé odpovědi', 'Ikona blesku vedle pole pro psaní – uložené '
          'věty jako „Super výkon, příště +2,5 kg“. Můžeš přidávat vlastní '
          'a mazat.'),
      ('Soukromí', 'Zprávy vidí jen trenér a daný klient. Nejsou vidět '
          'jiným klientům ani v PDF.'),
      ('Upozornění', 'Nové zprávy uvidíš po otevření aplikace (číslo '
          'u ikony). Upozornění na zamčeném telefonu zatím nejsou.'),
    ],
  ),
  HelpArticle(
    id: 'coach_home',
    icon: Icons.dashboard_outlined,
    title: 'Přehled trenéra',
    summary: 'Co znamenají karty na úvodní obrazovce.',
    steps: [
      ('Čísla nahoře', 'Aktivní klienti, kdo tento týden trénoval, průměrné '
          'skóre a kolik klientů potřebuje pozornost.'),
      ('Online klienti', 'Nové zprávy, jestli dnes odcvičil, kolik tréninků '
          'neodcvičil a komu chybí naplánovaný trénink. Kdo potřebuje '
          'reakci, je nahoře. Klepnutím otevřeš klienta.'),
      ('Potřebuje pozornost', 'Klienti bez tréninku, bez měření nebo '
          's poklesem skóre.'),
      ('Záloha', 'Stav cloudové zálohy a tlačítka pro ruční zálohu / '
          'obnovu.'),
    ],
  ),

  // ----------------------------------------------------------------
  // DEN, JÍDLO, TRÉNINK
  // ----------------------------------------------------------------
  HelpArticle(
    id: 'today',
    icon: Icons.home_outlined,
    title: 'Obrazovka Dnes',
    summary: 'Tvůj den na jednom místě.',
    steps: [
      ('Cesta k cíli', 'Karta nahoře ukazuje, kolik ti chybí do cílové váhy '
          'a jak se ti daří od začátku.'),
      ('Dnešní trénink', 'Tlačítko „Začít trénink“ otevře dnešní cviky. Když '
          'máš trenéra online, uvidíš tu trénink, který ti poslal.'),
      ('Zprávy s trenérem', 'U online klientů – nové zprávy jsou zvýrazněné.'),
      ('Jídlo dnes', 'Kolik kalorií ti ještě zbývá a jak jsi na tom s '
          'bílkovinami, sacharidy a tuky.'),
      ('Týden', 'Kolečka ukazují, které dny jsi už odtrénoval/a.'),
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
      ('Styl jídelníčku', 'Jídlo → ikona knihy „Můj jídelníček“. Lineární, '
          'sacharidové vlny, keto, přerušovaný půst nebo jídelníček '
          'k programu (Hollywood, Bikini…).'),
      ('Výběrový plán', 'Ke každému jídlu dne 10 možností se stejnými '
          'makry – klient si vybírá podle chuti. Dá se vytisknout po '
          'jednotlivých jídlech.'),
      ('Vegetarián, vegan, levná varianta', 'Přepínače ve stylu jídelníčku.'),
      ('Nákupní seznam', 'Z týdenního jídelníčku se sám vytvoří seznam '
          's gramážemi.'),
      ('Celá čísla', 'Makra a kalorie jsou vždy v celých gramech, vejce '
          'v celých kusech, porce po 5 g.'),
    ],
  ),
  HelpArticle(
    id: 'meal_editor',
    icon: Icons.edit_note,
    title: 'Vlastní jídelníčky a šablony',
    summary: 'Vlastní název, úpravy, výměna jídel a přepočet na klienta.',
    steps: [
      ('Nový jídelníček', 'Klient → záložka Strava → karta „Jídelníčky '
          'klienta“ → „Nový jídelníček“. Nebo Jídlo → Můj jídelníček → '
          '„Vlastní jídelníček“.'),
      ('Upravit vygenerovaný', 'V zobrazení jídelníčku ikona tužky, nebo '
          'u jídla ikona ⇄ „Vyměnit jídlo“. Upravená verze se uloží jako '
          'nový jídelníček.'),
      ('Dny, jídla, potraviny', 'Nahoře přepínáš dny (+ Den přidá kopii nebo '
          'prázdný den). U jídla „+ Potravina“, množství měníš −/+ nebo '
          'klepnutím na číslo, × potravinu odebere.'),
      ('Cíl klienta', 'Horní lišta ukazuje součet dne proti cíli: zelená = '
          'do 5 %, oranžová = do 12 %, červená = víc. Menu dne (⋮) → '
          '„Doladit den na cíl“ přepočítá porce přesně na jeho kalorie.'),
      ('Vyměnit za podobné', 'Menu jídla (⋮) → „Vyměnit za podobné jídlo“ '
          'nabídne až 10 jídel se stejnými makry. Alergie klienta se '
          'respektují.'),
      ('Vlastní potraviny', 'V seznamu potravin „Nová vlastní potravina“ – '
          'název a makra na 100 g z obalu (případně váha 1 kusu). Uloží se '
          'natrvalo, jsou nahoře s hvězdičkou.'),
      ('Uložení a název', 'Tlačítko „Uložit jídelníček“ – zadáš vlastní '
          'název a poznámku. Přepínač „Jídelníček klienta“ ho přiřadí '
          'klientovi (online klient ho hned uvidí), vypnutý = obecná šablona.'),
      ('Šablona pro jiného klienta', 'Každý uložený jídelníček je šablona. '
          'U klienta „Ze šablony“, nebo v Knihovně „Použít pro klienta“. '
          'Aplikace nabídne kalorie podle cíle klienta, porce přepočítá '
          'a zaokrouhlí a makra spočítá znovu.'),
      ('Knihovna', 'Všechny jídelníčky s hledáním a filtrem Šablony / '
          'Klientské. Menu karty: tisk, PDF, upravit, přejmenovat, uložit '
          'jako šablonu, smazat.'),
    ],
  ),
  HelpArticle(
    id: 'allergies',
    icon: Icons.no_food_outlined,
    title: 'Alergie a vyloučené potraviny',
    summary: 'Co klient nejí, se do jídelníčku nedostane.',
    steps: [
      ('Kde zadat', 'Při přidání klienta, nebo klient → Strava → karta '
          '„Alergie a co klient nejí“. Piš oddělené čárkou, např. '
          '„laktóza, ořechy, vejce“.'),
      ('Skupiny', 'Aplikace zná skupiny – laktóza/mléko, lepek, ořechy, '
          'sója, ryby… vyřadí všechny potraviny ze skupiny.'),
      ('Kde to platí', 'Všechny generované jídelníčky, výběrový plán '
          'i výměna jídla. V editoru jsou vyloučené potraviny červeně '
          'a aplikace se před přidáním zeptá.'),
      ('PDF', 'Na jídelníčku v PDF je řádek „Bez: …“.'),
    ],
  ),
  HelpArticle(
    id: 'training',
    icon: Icons.fitness_center_outlined,
    title: 'Trénink a programy',
    summary: 'Tréninkové plány, knihovna programů a zapisování výkonů.',
    steps: [
      ('Vlastní plán', 'Vytvoř plán s dny a cviky, nebo vlož hotový program '
          'z knihovny.'),
      ('Knihovna programů', 'Kulturistika a postava, Síla a vzpírání, Běh, '
          'Příprava na fyzické testy (policie, hasiči, armáda) a Kondice. '
          'Náhled ukáže dny a cviky před vložením.'),
      ('Programy s datem', 'Hollywood training, Bikini fitness, Kulatý '
          'zadek, Ruský cyklus a příprava na trojboj – zadáš datum akce '
          'a fáze i váhy se spočítají samy.'),
      ('Zapisování', 'U každého cviku zapiš váhu a opakování. Z toho se '
          'počítá progres a odhad maxima.'),
      ('Tisk plánu', 'V detailu plánu tlačítka Tisk / Uložit PDF – '
          's podpisem a upozorněním.'),
      ('Online klient', 'Online klientovi plán neposíláš celý – viz návod '
          '„Posílání tréninků“.'),
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
      ('Výkony', 'Nejlepší výkony u cviků a jejich vývoj v grafu. Výkony '
          'z tréninků od trenéra se sem ukládají samy.'),
      ('Hodinky', 'Pokrok → „Aktivita a hodinky“ – kroky, pohyb, spánek, tep '
          'a tréninky z chytrých hodinek. Podrobně v článku „Chytré hodinky“.'),
    ],
  ),
  HelpArticle(
    id: 'activity',
    icon: Icons.watch_outlined,
    title: 'Chytré hodinky a aktivita',
    summary: 'Kroky, pohyb, spánek a tréninky se zapíšou samy.',
    steps: [
      ('Jak to funguje', 'SPAL čte data z aplikace Apple Zdraví (iPhone) nebo '
          'Health Connect (Android). Tam posílá data skoro každé hodinky: '
          'Apple Watch, Garmin, Samsung, Fitbit, Xiaomi, Amazfit, Polar…'),
      ('Propojení', 'Pokrok → „Aktivita a hodinky“ → Propojit a povolit '
          'všechny položky. Nebo na obrazovce Dnes karta „Máš chytré '
          'hodinky?“.'),
      ('Hodinky jiné značky', 'V aplikaci hodinek (Garmin Connect, Samsung '
          'Health, Fitbit, Mi Fitness, Zepp…) zapni sdílení do Apple Zdraví '
          'nebo do Health Connect. Bez toho se data do telefonu nedostanou.'),
      ('Android', 'Potřebuješ aplikaci Health Connect od Googlu – na novějších '
          'telefonech už je, jinak ji SPAL nabídne k instalaci.'),
      ('Co uvidíš', 'Dnešní kroky s cílem, kalorie spálené pohybem, '
          'vzdálenost, spánek, klidový tep, váhu z chytré váhy, graf za 7 '
          'a 30 dní, průměry a tréninky zaznamenané hodinkami.'),
      ('Kalorie', 'Tvůj denní cíl už počítá s běžným pohybem. Když se hýbeš '
          'víc než obvykle, Jídlo ti ukáže, kolik si můžeš dát navíc. Cíl od '
          'trenéra se sám nemění.'),
      ('Check-in', 'Váha z chytré váhy se do check-inu předvyplní a trenér '
          'vidí i průměr kroků a spánku.'),
      ('Trenér', 'Klient → Přehled → karta „Aktivita z hodinek“: průměry za '
          '7 dní, porovnání s dřívějškem a detail s grafy. Data se obnoví, '
          'když klient otevře aplikaci.'),
      ('Nevidím data', 'iPhone: Zdraví → profil → Aplikace → SPAL → zapni vše. '
          'Android: Health Connect → Oprávnění aplikací → SPAL. Pak v SPAL '
          'potáhni obrazovku dolů pro načtení.'),
      ('Soukromí', 'Data se jen čtou, nic se do hodinek nezapisuje. Vidíš je '
          'ty a tvůj trenér, nikdy se nepoužívají k reklamě. „Odpojit '
          'hodinky“ je smaže z telefonu i u trenéra.'),
      ('Počítač', 'Na Windows se hodinky propojit nedají – jen v aplikaci '
          'na telefonu. Trenér ale data klienta vidí i na počítači.'),
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
          'hydratace, vývoj od minula a cílová váha.'),
      ('Akční plán', 'Konkrétní kroky pro stravu, trénink a regeneraci podle '
          'výsledků.'),
    ],
  ),
  HelpArticle(
    id: 'clients',
    icon: Icons.groups_outlined,
    title: 'Klienti (pro trenéry)',
    summary: 'Přidání klienta, jeho detail a práce za něj.',
    steps: [
      ('Přidat klienta', 'Záložka Klienti → tlačítko +. Rovnou můžeš zadat '
          'i alergie.'),
      ('Seznam a detail', 'Na počítači je vlevo seznam a vpravo detail '
          'vybraného klienta. Hledání a filtry jsou nahoře.'),
      ('Záložky klienta', 'Přehled (skóre, akční plán, online coaching), '
          'Postava (InBody, obvody), Trénink (tréninky pro klienta, plány), '
          'Strava (jídelníčky, alergie), Poznámky.'),
      ('Otevřít jako klient', 'Uvidíš aplikaci očima klienta a můžeš za něj '
          'zapisovat.'),
      ('Import / export', 'Zálohy klientů a přenos mezi zařízeními najdeš '
          'v nabídce Import / export.'),
    ],
  ),
  HelpArticle(
    id: 'pdf',
    icon: Icons.picture_as_pdf_outlined,
    title: 'PDF a tisk',
    summary: 'Souhrn klienta, jídelníčky a tréninkové plány.',
    steps: [
      ('Souhrn klienta', 'Detail klienta → „Souhrn PDF“. Vyber období '
          '(doporučeno „Od začátku“).'),
      ('Jídelníček a trénink', 'Ikona tiskárny u jídelníčku nebo plánu. '
          'V tisku můžeš zvolit i „Uložit jako PDF“; druhá ikona PDF sdílí.'),
      ('Logo a kontakty', 'Nastavení → „Údaje na dokumentech (PDF)“: jméno '
          'a zaměření, telefon, e-mail, Instagram, web a logo (PNG/JPG). '
          'Logo a kontakty jsou nahoře na stránce, podpis a kontakt na konci.'),
      ('Upozornění', 'Na každém PDF je i upozornění, že nejde o lékařskou '
          'radu – chrání tě to.'),
      ('Černobílý tisk', 'Přepínač pro černobílou tiskárnu – šetří toner.'),
    ],
  ),
  HelpArticle(
    id: 'security',
    icon: Icons.lock_outline,
    title: 'Zabezpečení a soukromí',
    summary: 'PIN, trenérský účet a kdo co vidí.',
    steps: [
      ('Trenérský účet', 'Trenérský režim vyžaduje přihlášení e-mailem '
          'a heslem. Heslo nikomu neposílej a nefoť.'),
      ('PIN', 'Po spuštění aplikace a po každém přepnutí režimu se trenérský '
          'režim zamkne PINem – když se k zařízení dostane někdo jiný, data '
          'klientů neuvidí.'),
      ('Klient s trenérem', 'Na telefonu propojeného klienta je trenérský '
          'režim skrytý.'),
      ('Cloud', 'Data jsou v cloudu Google Firebase, přístup mají jen '
          'přihlášený trenér a jeho propojený klient.'),
    ],
  ),

  // ----------------------------------------------------------------
  // OSTATNÍ
  // ----------------------------------------------------------------
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
    summary: 'Tmavý režim, barva aplikace a podpis.',
    steps: [
      ('Světlý / tmavý / auto', 'Auto se řídí nastavením zařízení.'),
      ('Barva aplikace', 'Smaragdová, růžová, fialová, modrá, oranžová nebo '
          'grafitová – změní se celá aplikace.'),
      ('Údaje na dokumentech', 'Jméno, kontakty a logo, které se tisknou '
          'na PDF.'),
    ],
  ),
  HelpArticle(
    id: 'data',
    icon: Icons.cloud_outlined,
    title: 'Data a zálohy',
    summary: 'Kde jsou data a jak o ně nepřijít.',
    steps: [
      ('Automatická záloha', 'Trenérská data (klienti, měření, plány, '
          'jídelníčky, vlastní potraviny, výkony) se po každé změně zálohují '
          'do cloudu k tvému účtu.'),
      ('Druhé zařízení', 'Na jiném počítači se stačí přihlásit stejným '
          'trenérským účtem – data se stáhnou z cloudu.'),
      ('Export klienta', 'Záloha do souboru s PDF souhrnem a tabulkami. '
          'Hodí se před většími změnami.'),
      ('Tovární nastavení', 'Nevratně smaže všechna data v zařízení.'),
    ],
  ),
  HelpArticle(
    id: 'problems',
    icon: Icons.build_outlined,
    title: 'Když něco nefunguje',
    summary: 'Nejčastější potíže a jejich řešení.',
    steps: [
      ('Klient nevidí trénink / jídelníček', 'Ať stáhne obrazovku dolů nebo '
          'dá Profil → Synchronizovat. Zkontroluj, že je u něj v kartě '
          '„Online coaching“ zelené „Připojeno“ a že má internet.'),
      ('Kód nefunguje', 'Kód jde použít jen jednou. Vytvoř u klienta „Nový '
          'kód“ a pošli ho znovu.'),
      ('„Přihlášení klientů není zapnuté“', 'Ve Firebase konzoli → '
          'Authentication → Sign-in method musí být zapnuté „Anonymous“.'),
      ('„Cloud odmítl přístup“', 'Ve Firebase konzoli → Firestore → '
          'Pravidla nejsou publikovaná aktuální pravidla ze souboru '
          'firestore.rules.'),
      ('Telefon se po přeinstalaci vrací do trenéra', 'Na úvodní obrazovce '
          'použij šipku zpět a zvol „Mám pozvánku od trenéra“ – připojení '
          'kódem trenérský účet v telefonu odhlásí.'),
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
              const AuthorFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
