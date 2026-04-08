🏋️ FITNESS APP – HLAVNÍ PLÁN (MASTER v2)

Tento dokument je:

jediný zdroj pravdy projektu

přehled hotových částí

plán dalšího vývoje

architektonický základ (nejen UI)

🎯 VIZE APLIKACE

Aplikace pro:

běžné uživatele

profesionální trenéry (placený mód)

Cíl aplikace:

dlouhodobá motivace

periodizace tréninku a stravy

přesná diagnostika

měřitelné výsledky v čase

práce s datem a vývojem

🧱 HLAVNÍ PILÍŘE

Tělo / Diagnostika

Jídlo / Makra

Výkonnost / Cviky

Trenérský mód / Klienti

🧠 ZÁSADNÍ FILOZOFIE (DŮLEŽITÉ)

Aplikace NENÍ:

statická kalkulačka

jednorázový výpočet maker

Aplikace JE:

systém pracující s časem

reagující na změny těla

připravující uživatele na konkrétní cíl v konkrétním datu

📅 GLOBÁLNÍ PRAVIDLO DAT (NEPORUŠITELNÉ)

Každý záznam, který se porovnává, MUSÍ mít datum.

Bez datumu:

❌ neexistuje porovnání

❌ neexistuje graf

❌ neexistuje vyhodnocení

Platí pro:

tělesná měření

obvody

výkonnost cviků (PR)

trenérský mód

AI vyhodnocení

Porovnání je možné pouze:

vůči předchozímu záznamu

nebo vůči zvolenému počátečnímu datu

🎯 KONCEPT CÍLE (KLÍČOVÁ ČÁST)

Cíl NENÍ jen jeden výběr.

Cíl má 3 úrovně:

1️⃣ SMĚR (CO)

síla

postava

hubnutí

vytrvalost

2️⃣ DŮVOD (PROČ)

závody

léto

zdraví

výkon

estetika

3️⃣ ČAS (KDY)

počáteční datum

cílové datum

Bez PROČ + KDY:

nelze správně nastavit makra

nelze plánovat trénink

nelze aplikovat superkompenzaci

🧍‍♂️ POSTAVA – SPECIÁLNÍ LOGIKA

Pokud uživatel zvolí postava, musí být určeno:

🔹 nabrat svalovou hmotu

🔹 rýsovat

🔹 automatická periodizace

Automatika znamená:

nabírací fáze

silová fáze

rýsovací fáze

udržovací fáze

Fáze se mění:

podle času

podle vývoje váhy a měření

podle blížícího se cílového data

🔄 DYNAMICKÉ PŘEPOČTY (VELMI DŮLEŽITÉ)

Makra NIKDY nejsou statická.

Přepočet probíhá:

při každém novém měření

při změně cíle

při změně data

při změně fáze (postava)

Zdroj pravdy:

poslední uložené měření

✅ HOTOVO
🧍‍♂️ Uživatelský profil

 věk

 pohlaví

 výška

 váha

 základní cíl (směr)

🔥 Metabolismus

 BMR

 TDEE

 dashboard

⚖️ Tělo – InBody

 váha

 svalová hmota

 tuková hmota

 datum měření

 historie měření

 poslední měření = aktuální stav

📏 Obvody těla

 biceps

 hrudník

 pas

 stehno

 krk

 datum

 historie

🏋️ Výkonnost

 cvik

 váha

 opakování

 datum

 historie

 PR výpočet

🟡 ROZPRACOVANÉ
🍽️ Jídlo

 ukládání jídel

 přesná makra podle cíle

 „kolik zbývá sníst“

 reakce na změnu váhy

🎨 UI

 čitelnější dashboard

 lepší struktura dat

🔵 PLÁNOVANÉ MODULY
1️⃣ JÍDLO / MAKRA

cyklování sacharidů

změny dle fáze

AI návrh jídel

intolerance

2️⃣ VÝKONNOST

grafy vývoje

dlouhodobé porovnání

plánování vrcholu výkonu

3️⃣ TRENÉRSKÝ MÓD (PLACENÝ)

PIN / heslo

klienti (100+)

diagnostický formulář

poznámky

zdravotní omezení

plná historie a grafy

🚀 DLOUHODOBÝ SMĚR

AI trenér

AI výživa

fotky těla v čase

cloud synchronizace

tým trenérů

předplatné

📅 DENNÍ ZÁZNAM (DOPLŇUJE SE PRŮBĚŽNĚ)
Datum:

Co jsme dnes udělali:

…

Co zbývá:

…

Další krok:

…
🟢 TOHLE VLOŽ DO PLÁNU
🔄 PRAVIDLA PŘEPOČTU MAKER

Makra se MUSÍ přepočítat při:

zadání nového měření

změně váhy o více než ±1 kg

změně fáze cíle

přiblížení se k cílovému datu o:

12 týdnů

6 týdnů

2 týdny

Zdroj výpočtu:

vždy POSLEDNÍ uložená váha

nikoli původní z onboardingu

🧮 METODIKA VÝPOČTU PODLE CÍLE
🏋️ SÍLA

kalorie: +10–15 % nad TDEE

protein: 2.0 g/kg

tuky: 0.9–1.0 g/kg

sacharidy: zbytek

Důraz:

progresivní přetížení

dostatek sacharidů pro CNS

před závody:

deload

superkompenzace

💪 POSTAVA

Má 4 fáze:

NABÍRACÍ

+8 % kcal

protein 2.2 g/kg

SILOVÁ

+5 % kcal

vyšší sacharidy

RÝSOVACÍ

−15 až −20 %

protein 2.3–2.5 g/kg

UDRŽOVACÍ

TDEE

protein 2.0 g/kg

Přepínání:

podle času

podle % tuku

podle tempa změny váhy

🔥 HUBNUTÍ

deficit −15 až −22 %

protein 2.2–2.5 g/kg

tuky min 0.7 g/kg

ochrana svalů

Bezpečnost:

max −1 % váhy týdně

jinak snížit deficit

🏃 VYTRVALOST

kcal = TDEE až +5 %

protein 1.6–1.8 g/kg

důraz sacharidy

periodizace podle tréninku

🛡️ OCHRANNÉ MECHANISMY

Aplikace NESMÍ dovolit:

tuky < 0.6 g/kg

protein < 1.6 g/kg

deficit > 25 %

hubnutí rychlejší než 1.2 % týdně

📊 VAZBA MODULŮ
Měření → Nová váha  
        ↓  
Přepočet TDEE  
        ↓  
Výpočet maker dle cíle a fáze  
        ↓  
Denní jídelníček  
        ↓  
Vyhodnocení výkonu

🎯 LOGIKA BLÍŽÍCÍHO SE CÍLE

Pokud je důvod = závody:

8 týdnů → stabilizace

4 týdny → specifická fáze

1 týden → peak / deload

Pokud = léto:

posledních 6 týdnů automaticky rýsování

🧪 VALIDACE DAT

každé měření musí mít datum

výkon musí mít datum

porovnání jen v časové ose

graf = min 2 body

🧠 ARCHITEKTURA PRO DALŠÍ CHAT

Přidej na konec plánu tohle:

🧩 ARCHITEKTONICKÉ PRAVIDLO

Aplikace je:

stavový systém

nikoli kalkulačka

pracuje s vývojem člověka v čase

Hlavní entity:

UserProfile

Goal (typ + důvod + datum + fáze)

Measurement

Performance

Macros (vypočtené – neuložené natvrdo)

✅ DALŠÍ KROK

Teď máme 2 cesty:

🧱 Nejprve udělat
👉 LOGIKU PŘEPOČTU PO NOVÉM MĚŘENÍ

🧠 Nebo
👉 FORMULÁŘ „PROČ a DO KDY“ u cíle

🧠 PERIODIZACE ŘÍZENÁ DATEM – ROZŠÍŘENÁ LOGIKA
1) Základní princip

U cíle POSTAVA a u všech soutěžních cílů je hlavním řídicím prvkem:

📅 DATUM – nikoli přání uživatele

Aplikace musí fungovat jako trenér, který může rozhodnutí uživatele korigovat.

2) Dva odlišné režimy
A) Běžný uživatel (léto / estetika / zdraví)

Platí:

roční periodizace

fáze určuje aktuální měsíc + čas do cíle

směr „nabrat svaly“ ≠ automaticky objem

Logika:

pokud je datum v jarně–letním období → priorita rýsování

pokud podzim–zima → povolen objem / síla

přepnutí fází probíhá automaticky podle kalendáře

Makra se přepočítají:

každý měsíc podle nové fáze

při novém měření

při změně váhy > ±1 kg

B) Soutěžní režim (závody)

Týká se:

kulturistika

men’s physique

silové sporty

vytrvalostní závody

❗ ZDE ROČNÍ PERIODIZACE NEPLATÍ

Vše je řízeno výhradně:

datem závodu

počtem týdnů do startu

aktuální formou z měření

Struktura před závodem

Aplikace musí umět:

klasický výpočet maker dle cíle

následně přechod do specifických fází:

Přípravná redukční

Cyklické sacharidy

Peak week

Superkompenzace

Odvodnění

Tyto kroky se aktivují automaticky podle:

8 týdnů do závodu

4 týdny

2 týdny

7 dní

3) Dynamický přepočet

I během pevně dané fáze platí:

Každé nové měření = nový člověk

Proto:

makra vypočtená dnes

za měsíc neplatí, pokud je jiná váha

Systém musí:

vzít POSLEDNÍ váhu

přepočítat TDEE

zachovat aktuální fázi

vygenerovat nová makra pro daný měsíc

4) Konflikty logik

Priorita:

1️⃣ Datum závodu (pokud existuje)
2️⃣ Kalendářní periodizace
3️⃣ Přání uživatele
4️⃣ Jednorázový výpočet

5) Klíčové pravidlo

Uživatel říká:

„Chci nabrat svaly“

Aplikace rozhoduje:

„Jaká fáze je dnes pro tebe reálně správná.“

🧩 Doporučené rozšíření entity GOAL

Goal musí obsahovat:

typ cíle

důvod

datum cíle

režim:

běžný

soutěžní

aktivní fáze (vypočtená)

✅ Výsledek

Makra jsou vždy:

funkce (datum, poslední váha, typ cíle, důvod, fáze)

nikoli uložená hodnota.
🧭 FITNESS APP – MASTER PLAN (aktuální stav)
📌 STAV PROJEKTU

Tento dokument je:

jediný zdroj pravdy

přehled hotových částí

plán dalšího vývoje

architektonický základ (logika > UI)

✅ HOTOVO (IMPLEMENTOVÁNO)
🧠 ZÁKLADNÍ FILOZOFIE

aplikace je stavový systém

vše je řízeno časem a vývojem uživatele

žádné statické výpočty

👤 UserProfile

věk, pohlaví, výška

aktuální váha

historie měření

uložený cíl (Goal)

🎯 Goal (3 úrovně)

CO – GoalType (síla / postava / hubnutí / vytrvalost)

PROČ – GoalReason (závody / léto / zdraví / výkon / estetika)

KDY – cílové datum

AKTUÁLNÍ FÁZE – GoalPhase

⚖️ Měření těla

váha

svaly / tuk (volitelné)

datum

historie

poslední měření = zdroj pravdy

🔄 Reaktivní logika

po nastavení cíle:

přepočet fáze podle data

po každém měření:

aktualizace váhy

přepočet fáze

hook pro přepočet maker

🔥 Metabolismus

BMR

TDEE

aktivita

🍽️ Makra (základ)

výpočet podle:

cíle

fáze

aktuální váhy

makra nejsou ukládána, pouze počítána

🟡 ROZPRACOVÁNO (PRÁVĚ TEĎ)
⏱️ ČASOVĚ ŘÍZENÁ PERIODIZACE

fáze nejsou voleny ručně

fáze se určují:

podle dnešního data

podle cílového data

podle typu cíle

aktuálně řešíme POSTAVU

🧠 NOVÁ ARCHITEKTURA (SCHVÁLENO)
🔑 Time-driven systém

Všechny moduly (jídlo, trénink, výkon) budou číst stejný časový kontext.

Nové entity:

TimeContext

PlanMode

normal

accelerated

PhasePlan

⚡ ZRYCHLENÝ REŽIM (měkká pravidla)

pokud uživatel zvolí nereálné datum:

aplikace upozorní

nabídne alternativy

zrychlený režim:

ovlivňuje jídlo i trénink

počítá se od cílového data zpětně

má bezpečnostní limity
## PHASE SYSTEM
- Jednotná periodizace pro jídlo i trénink
- Řízeno pouze datem
- Podpora normal / accelerated režimu
- Fáze: gaining / cutting / peaking / maintenance
- Zrychlený režim počítá fáze zpětně od cíle
### ✅ HOTOVO – Phase Engine (Core)
- Přidány core entity:
  - PhaseType (gaining/cutting/peaking/maintenance)
  - PhasePlan (časový úsek fáze + accelerated flag)
  - PlanMode (normal/accelerated)
  - TimeContext (now/targetDate/weeksToTarget)
- Implementován PhasePlannerService:
  - buildPlan(TimeContext) vrací List<PhasePlan>
  - normal režim: kalendářní plán (zima->gaining, jaro->cutting, před cílem->peaking)
  - accelerated režim: počítá fáze zpětně od cíle, zkracuje a přidá accelerated=true
- Implementován PhaseResolver:
  - z PhasePlan určí aktuální fázi pro dnešní den
  - vrací aktivní PhasePlan segment + helpers
### ✅ HOTOVO – Food Strategy Layer (Core)
- Přidán FoodStrategyAdapter:
  - převádí PhasePlan + GoalType/Reason na FoodStrategy (kalorie + makra)
  - podporuje PlanMode normal/accelerated (agresivnější cut v accelerated)
  - obsahuje safety guardrails (min protein, min tuky, max deficit)
  - připraveno pro budoucí carb cycling / peak week / refeedy
### ✅ HOTOVO – MacroService refactor (napojení na Phase Engine)
- MacroService už neřeší cíle a fáze ručně.
- Makra se počítají přes Core:
  - TimeContext → PhasePlannerService → PhaseResolver → FoodStrategyAdapter
- FoodStrategy určuje:
  - calorieMultiplier (TDEE násobek)
  - protein g/kg
  - fat g/kg
  - safety guardrails (min protein, min tuky, max deficit)
- MacroService pouze dopočítá:
  - targetCalories
  - protein/fat v gramech
  - carbs jako zbytek
- Připraveno na zrychlený režim: accelerated ovlivní jídlo automaticky.
### ✅ HOTOVO – UI napojení na nový MacroTarget (debug friendly)
- FoodSummaryScreen a DashboardScreen upraveny tak, aby:
  - používaly nový MacroTarget (včetně debug polí)
  - volitelně zobrazovaly: phaseLabel, planModeLabel, strategyLabel
- UI zůstává kompatibilní a výpočet maker je plně řízen Core Phase Engine + FoodStrategy.
### ✅ HOTOVO – Core struktura pro čas + fáze + jídlo
- Zavedena core struktura složek:
  - lib/core/time
  - lib/core/phase
  - lib/core/food
- Přidány soubory:
  - TimeContext, PlanMode
  - PhaseType, PhasePlan, PhasePlannerService, PhaseResolver
  - FoodStrategy, FoodStrategyAdapter
- UI (Dashboard, FoodSummary) napojeno na nový MacroTarget (debug-friendly).
### ✅ HOTOVO – Debug test screen napojený na Core engine
- PhaseTestScreen přepsán:
  - odstraněn starý PhaseService
  - testuje nový systém: TimeContext → PhasePlanner → Resolver → FoodStrategy → MacroService
  - zobrazuje: aktuální fázi, plan mode, celé PhasePlan segmenty + výsledná makra
### ✅ FIX – PhaseType.label
- Do core/phase/phase.dart doplněn extension getter `label`
- Debug obrazovky i UI mohou zobrazovat lidský název fáze (Nabírání/Shazování/Rýsování/Údržba)
### ✅ FIX – Extension import (PhaseType.label)
- PhaseTestScreen doplněn o přímý import core/phase/phase.dart
- Důvod: Dart extension metody jsou dostupné jen v souborech, které importují knihovnu s extension.
### ✅ HOTOVO – Goal jako stavový plán (ne jako uložená fáze)
- models/goal.dart rozšířen:
  - GoalPlanMode: auto / normal / accelerated
  - startDate (default = dnes) pro budoucí periodizaci (jídlo + trénink)
  - phase v Goal je nyní legacy (nepovinná) – fáze se počítá Core engine
- Důvod: aplikace je stavový systém, fáze je výpočet z času, ne uložená hodnota.
### ✅ HOTOVO – Validace cíle v GoalDetailScreen
- Přidána kontrola reálnosti cílového data pro typ POSTAVA
- Dialog s nabídkou:
  - upravit datum
  - zapnout zrychlený režim
  - ponechat plán i tak
- Ukládá se GoalPlanMode (auto / accelerated)
- Phase se už nebere jako zdroj pravdy – jen jako UI preference
### ✅ HOTOVO – Tréninkové cviky (Weekly Plan Generator v1)
- Přidán TrainingPlanService:
  - generuje týdenní plán cviků podle GoalType + fáze + režimu (normal/accelerated)
  - používá TrainingService (reps/sets/RIR) jako „parametry“
- Přidán model plánů:
  - PlannedExercise (název, série, opakování, RIR, poznámka)
  - TrainingDayPlan (den, fokus, list cviků)
- Přidána UI obrazovka:
  - TrainingPlanScreen – zobrazení týdenního plánu
- Přidán přechod:
  - z TrainingOverviewScreen tlačítko „Týdenní plán cviků“
## ✅ Stav: Phase Engine napojení (jídlo + trénink) – únor 2026

### Hotovo
- `UserProfileNotifier` přepnutý na nový Phase Engine:
  - `TimeContext` + `PhasePlannerService` + `PhaseResolver`
  - `_updatePhaseByDate()` mapuje `PhaseType` → `GoalPhase`
  - hook `_recalculateMacros()` připravený (zatím bez ukládání – makra jsou výpočet)
- Onboarding step1–3 zkontrolované a funkční (bez úprav logiky)

### Teď děláme
- Stabilizace UI obrazovek po refaktoru:
  - `DashboardScreen` sjednocení importů, const konstruktorů, scrollování (bez overflow)
  - Odstranění starých závislostí na `PhaseService`
  - Postupně procházet obrazovky:
    - `macros_screen.dart`
    - `food_summary_screen.dart`
    - `add_measurement_screen.dart`
    - `add_circumference_screen.dart`
    - `circumference_list_screen.dart`
    - `phase_test_screen.dart`

### Poznámka (architektura)
- Periodizace je společná pro JÍDLO i TRÉNINK:
  - stejné vstupy: `Goal (type, reason, targetDate)` + časový kontext
  - stejné výstupy: aktivní fáze + plan mode (normal/accelerated)
- UI nesmí fázi „vymýšlet“ – UI pouze zobrazuje výsledek z enginu.
## ✅ Phase Engine – sjednocení režimu (PlanMode) napříč cílem, jídlem a tréninkem

### Co máme hotové
- Goal má nově `startDate`, `targetDate` a `planMode` (`GoalPlanMode`: auto/normal/accelerated)
- Core Phase Engine běží přes `TimeContext` a generuje phase plán
- `Goal.phase` je označený jako LEGACY (`GoalPhase?`) – fáze se reálně počítá enginem

### Co teď děláme
- Mapujeme `GoalPlanMode -> PlanMode`, aby to šlo jednotně použít:
  - v jídle (MacroService / FoodStrategyAdapter)
  - v tréninku (TrainingService / TrainingStrategyAdapter)
  - v provideru (automatická aktualizace legacy fáze)

### Pravidlo (stavový systém)
- Goal pouze drží záměr (typ + důvod + datum + režim)
- Výpočet fáze je vždy runtime přes Phase Engine (stav v čase)
- Legacy `Goal.phase` se udržuje jen pro UI/kompatibilitu
📌 Výňatek do MASTER plánu (vlož do sekce HOTOVO)

✅ HOTOVO – Training Exercise Database (Core, MVP)

Přidána globální databanka cviků použitelná napříč cíli (síla/postava/hubnutí/vytrvalost)

Nové core soubory:

lib/core/training/exercises/exercise.dart (model cviku + logovací metriky)

lib/core/training/exercises/exercise_db.dart (MVP seed: S/B/D + variace + accessory + endurance)

lib/core/training/exercises/exercise_catalog.dart (lookup, filter by equipment, substitutions)
📌 Výňatek do MASTER plánu (vlož do HOTOVO)

✅ HOTOVO – Training Plan Models v2 (příprava na databanku a váhy)

Rozšířen model PlannedExercise o:

exerciseId (napojení na ExerciseDB, substituce, logování)

weightKg (budoucí %TM → kg výstup pro silový trénink)

intensityLabel (např. „80% TM“, „RPE 8“)

Zachována kompatibilita s v1 UI (pole name zůstává)
📌 Výňatek do MASTER plánu (vlož do HOTOVO)

✅ HOTOVO – Training Setup (dotazník) + uložení do profilu

UserProfileNotifier rozšířen o setTrainingIntake() pro uložení dotazníku

Přidána UI obrazovka:

lib/features/training/training_setup_screen.dart

dotazník: frequency/week + equipment + (pro síla/závody) 1RM S/B/D

TrainingOverviewScreen a TrainingPlanScreen mají fallback:

pokud trainingIntake == null → vyzvou uživatele k vyplnění nastavení
2) Rozšíření plánovacích modelů (příprava na váhy a ID)

PlannedExercise jsme rozšířili o pole:

exerciseId (napojení na databanku cviků)

weightKg (budoucí výpočet %TM → kg)

intensityLabel (např. “80% TM” / “RPE 8”)

✅ Výsledek: UI zatím jede pořád přes name, ale model je připraven na “pravé” plánování s váhama a ID.
📌 Výňatek do MASTER plánu (vlož do HOTOVO)

✅ HOTOVO – Weekly Plan respektuje frekvenci (TrainingIntake)

TrainingPlanService napojen na trainingIntake.frequencyPerWeek

Physique split se generuje podle 2–6× týdně (UL2 / FB3 / UL4 / PPL5 / PPL6)

Strength split se generuje podle frekvence (FB2 / ABC3 / UL4)

WeightLoss split podle frekvence (FB2–3 / UL4)
Výňatek do plánu (vlož do „HOTOVO“)

✅ HOTOVO – TrainingPlanScreen: zobrazení vah v kg

opraven rendering řádků cviků (žádné Expanded mimo Row)

přidán sloupec „kg“ (pokud weightKg != null)

pokud chybí trainingIntake, screen přesměruje na TrainingSetupScreen
✅ HOTOVO – Dnešní trénink (MVP)

přidán model TrainingSession (date + dayPlan)

přidán TodayTrainingService (vybere den z týdenního plánu podle frequencyPerWeek a dne v týdnu)

přidána obrazovka TodayTrainingScreen (zobrazuje dnešní jednotku včetně kg, pokud je dostupné)

doplněno tlačítko do TrainingOverviewScreen
✅ Výňatek do plánu (Master)

✅ HOTOVO – Slot model do planů

Do training_plan_models.dart přidán nový model SlotTrainingDayPlan

Slot plán používá ExerciseSlot (role + pattern + modality + parametry)
Výňatek do vašeho MASTER plánu (zkopíruj a vlož)

✅ UI – Trénink (únor 2026)

Dotazník tréninku a obrazovky jsou kompletně v češtině (vhodné i pro starší uživatele).

TrainingSetupScreen: frekvence, vybavení, zkušenost; u závodního „Síla“ i maximálky (1RM) s poznámkou o tréninkovém maximu (90 %).

TrainingOverviewScreen: přehled režimu + vstupy do týdenního plánu a dnešního tréninku.

TrainingPlanScreen: týdenní plán včetně zobrazení vypočtené váhy v kg (pokud je k dispozici).

TodayTrainingScreen: dnešní jednotka + tlačítko „Zapsat výkon“.
Přidali jsme model PlannedSet pro konkrétní série (rozcvička + pracovní).

Rozšířili PlannedExercise o plannedSets.

Doplnili WeightCalculator.buildWarmupAndWorkSets() pro automatické dopočítání z 1RM + TM%.

V plánu pro hlavní cviky začneme dosazovat plannedSets (např. bench).

UI umí zobrazit konkrétní série pod cvikem.
D:\FITNESS\DART_APPLICATION_1\LIB                          
├───core
│   ├───food
│   ├───nav
│   ├───nutrition
│   ├───phase
│   ├───time
│   └───training
│       ├───exercises
│       ├───intake
│       ├───loads
│       ├───progression
│       ├───sessions
│       └───slots
├───data
├───features
│   ├───body
│   ├───coach
│   │   ├───clients
│   │   └───dashboard
│   ├───dashboard
│   ├───debug
│   ├───diet_plans
│   │   ├───logic
│   │   ├───models
│   │   ├───providers
│   │   └───screens
│   ├───food
│   ├───nutrition
│   ├───onboarding
│   ├───paywall
│   ├───performance
│   ├───role
│   └───training
├───models
│   ├───coach
│   └───onboarding
├───providers
│   ├───coach
│   └───subscription
└───services
    ├───coach
    └───pdf
PS D:\Fitness\dart_application_1>  tree lib /f
Folder PATH listing
Volume serial number is B808-6717
D:\FITNESS\DART_APPLICATION_1\LIB
│   app.dart
│   main.dart
│   plan.md
│
├───core
│   ├───food
│   │       food_strategy.dart
│   │       food_strategy_adapter.dart
│   │
│   ├───nav
│   │       active_client_profile_sync.dart
│   │       switch_mode.dart
│   │
│   ├───nutrition
│   │       calorie_calculator.dart
│   │       weight_basis.dart
│   │
│   ├───phase
│   │       phase.dart
│   │       phase_plan.dart
│   │       phase_planner_service.dart
│   │       phase_resolver.dart
│   │       plan_mode.dart
│   │
│   ├───time
│   │       time_context.dart
│   │
│   └───training
│       │   actual_set.dart
│       │   training_plan_models.dart
│       │   training_set.dart
│       │   training_split.dart
│       │   training_strategy.dart
│       │   training_strategy_adapter.dart
│       │
│       ├───exercises
│       │       exercise.dart
│       │       exercise_catalog.dart
│       │       exercise_db.dart
│       │       exercise_presets.dart
│       │       exercise_selector.dart
│       │
│       ├───intake
│       │       training_intake.dart
│       │
│       ├───loads
│       │       e1rm_calculator.dart
│       │       weight_calculator.dart
│       │
│       ├───progression
│       │       progression_service.dart
│       │
│       ├───sessions
│       │       exercise_log_entry.dart
│       │       training_session.dart
│       │
│       └───slots
│               exercise_slot.dart
│               exercise_slot_selector.dart
│
├───data
│       food_bank_seed.dart
│       food_combo_seed.dart
│       keto_bank.dart
│       sacharidove_vlny_bank.dart
│
├───features
│   ├───body
│   │       add_circumference_screen.dart
│   │       add_measurement_screen.dart
│   │       circumference_list_screen.dart
│   │
│   ├───coach
│   │   │   coach_shell.dart
│   │   │
│   │   ├───clients
│   │   │       add_circumference_entry_screen.dart
│   │   │       add_client_screen.dart
│   │   │       add_diagnostic_entry_screen.dart
│   │   │       add_inbody_entry_screen.dart
│   │   │       client_detail_screen.dart
│   │   │       client_list_screen.dart
│   │   │       client_monthly_report_screen.dart
│   │   │       edit_client_details_screen.dart
│   │   │
│   │   └───dashboard
│   │           coach_dashboard_screen.dart
│   │
│   ├───dashboard
│   │       dashboard_screen.dart
│   │       macros_screen.dart
│   │
│   ├───debug
│   │       phase_test_screen.dart
│   │
│   ├───diet_plans
│   │   │   diet_strategy_screen.dart
│   │   │
│   │   ├───logic
│   │   │       fasting_logic.dart
│   │   │       keto_calculator.dart
│   │   │
│   │   ├───models
│   │   │       carb_cycling_food_logic.dart
│   │   │       carb_cycling_plan.dart
│   │   │       survey_result.dart
│   │   │
│   │   ├───providers
│   │   │       diet_plan_provider.dart
│   │   │       diet_settings_provider.dart
│   │   │
│   │   └───screens
│   │           carb_cycling_logic.dart
│   │           carb_cycling_result_screen.dart
│   │           carb_cycling_survey_screen.dart
│   │           daily_menu_screen.dart
│   │           home_screen.dart
│   │           keto_logic.dart
│   │           keto_result_screen.dart
│   │           meal_plan_view.dart
│   │           shopping_list_screen.dart
│   │           weekly_meal_plan_screen.dart
│   │
│   ├───food
│   │       food_bank_screen.dart
│   │       food_entry_screen.dart
│   │       food_strategy.dart
│   │       food_strategy_adapter.dart
│   │       food_summary_screen.dart
│   │       measurement_history_screen.dart
│   │
│   ├───nutrition
│   │       today_food_screen.dart
│   │
│   ├───onboarding
│   │       goal_detail_screen.dart
│   │       onboarding_goal_screen.dart
│   │       onboarding_link_client_screen.dart
│   │       onboarding_profile_screen.dart
│   │       onboarding_step1.dart
│   │       onboarding_step2.dart
│   │       onboarding_step3.dart
│   │
│   ├───paywall
│   │       paywall_screen.dart
│   │
│   ├───performance
│   │       add_performance_screen.dart
│   │       performance_chart_screen.dart
│   │       performance_detail_screen.dart
│   │       performance_list_screen.dart
│   │       performance_provider.dart
│   │
│   ├───role
│   │       role_select_screen.dart
│   │
│   └───training
│           custom_training_plan_screen.dart
│           eating_support_setup_screen.dart
│           exercise_picker_screen.dart
│           log_training_screen.dart
│           slot_plan_debug_screen.dart
│           split_selector_screen.dart
│           today_training_screen.dart
│           training_log_screen.dart
│           training_overview_screen.dart
│           training_plan_screen.dart
│           training_setup_screen.dart
│
├───models
│   │   body_circumference.dart
│   │   body_scan.dart
│   │   circumferece_measument.dart
│   │   coach_overrides.dart
│   │   custom_training_plan.dart
│   │   daily_intake.dart
│   │   exercise_performance.dart
│   │   food_combo.dart
│   │   goal.dart
│   │   macros.dart
│   │   meal.dart
│   │   measurement.dart
│   │   user_profile.dart
│   │
│   ├───coach
│   │       coach_body_diagnostic_entry.dart
│   │       coach_circumference_entry.dart
│   │       coach_client.dart
│   │       coach_client_details.dart
│   │       coach_goal.dart
│   │       coach_inbody_entry.dart
│   │       coach_note.dart
│   │       coach_overrides.dart
│   │
│   └───onboarding
│           onboarding_step1.dart
│
├───providers
│   │   active_client_provider.dart
│   │   daily_history_provider.dart
│   │   daily_intake_provider.dart
│   │   diet_settings_provider.dart
│   │   food_bank_provider.dart
│   │   food_combo_provider.dart
│   │   performance_provider.dart
│   │   slot_selection_provider.dart
│   │   training_session_provider.dart
│   │   user_profile_provider.dart
│   │
│   ├───coach
│   │       active_client_data_providers.dart
│   │       active_client_provider.dart
│   │       active_goal_provider.dart
│   │       app_role_provider.dart
│   │       coach_circumference_controller.dart
│   │       coach_clients_controller.dart
│   │       coach_clients_provider.dart
│   │       coach_client_details_controller.dart
│   │       coach_diagnostic_controller.dart
│   │       coach_goal_controller.dart
│   │       coach_inbody_controller.dart
│   │       coach_notes_controller.dart
│   │       coach_notes_provider.dart
│   │       custom_training_plan_provider.dart
│   │
│   └───subscription
│           subscription_provider.dart
│
└───services
    │   ai_engine.dart
    │   body_scan_repository.dart
    │   custom_training_plan_mapper.dart
    │   food_combo_service.dart
    │   local_storage_service.dart
    │   macro_calculator_service.dart
    │   macro_service.dart
    │   meal_suggestion_service.dart
    │   metabolism_service.dart
    │   phase_service.dart
    │   tm_adaptation_service.dart
    │   today_training_service.dart
    │   trainer_engine_service.dart
    │   training_log_service.dart
    │   training_plan_service.dart
    │   training_service.dart
    │   training_slot_plan_service.dart
    │
    ├───coach
    │       active_client_service.dart
    │       client_export_service.dart
    │       coach_insights_service.dart
    │       coach_metrics_service.dart
    │       coach_storage_service.dart
    │       id_service.dart
    │
    └───pdf
            client_report_pdf_service.dart