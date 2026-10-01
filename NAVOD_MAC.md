# SPAL – příprava na Macu (iPhone + Mac aplikace)

Postup krok za krokem. Příkazy piš do aplikace **Terminál** (Cmd+mezerník → „Terminál“).
Řádky začínající `#` jsou jen poznámky, ty nepiš.

---

## 0. Co je potřeba

- Mac s aktuálním macOS. **Xcode 26** (nutný pro App Store od dubna 2026) potřebuje
  macOS Sequoia 15.6 nebo novější – ověř v App Store u Xcode.
- Apple ID (stačí běžné) – pro vyzkoušení na vlastním iPhonu kabelem.
- **Apple Developer Program** (placený, developer.apple.com) – pro TestFlight,
  napojení na Apple Zdraví (hodinky) a App Store.
- Asi 40 GB volného místa (Xcode je velký).

---

## 1. Instalace nástrojů (jednou)

1. **Xcode** – nainstaluj z App Store, jednou ho otevři a potvrď licenci.
   V Xcode → Settings → Components stáhni **iOS** (platformu pro iPhone).
2. Pak v Terminálu:

```bash
sudo xcode-select -s /Applications/Xcode.app
sudo xcodebuild -license accept

# Homebrew (správce programů pro Mac)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Na konci instalace Homebrew vypíše 2 řádky „Next steps“ – zkopíruj je a spusť.

brew install --cask flutter
brew install cocoapods node
npm install -g firebase-tools
dart pub global activate flutterfire_cli
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc

flutter doctor
```

`flutter doctor` musí mít zelenou fajfku u **Flutter** a **Xcode**. Android Studio a Chrome
na Macu nepotřebuješ – to, že u nich nejsou fajfky, nevadí.

---

## 2. Stažení projektu

Poprvé:

```bash
cd ~/Documents
git clone https://github.com/ludek-vymetal/chytry-trener.git
cd chytry-trener
```

Když už projekt na Macu máš:

```bash
cd ~/Documents/chytry-trener
git pull
```

> **Pravidlo:** na Windows po práci `git push`, na Macu před prací `git pull` (a obráceně).

---

## 3. Napojení na Firebase (jednou)

Aplikace má nový identifikátor **cz.spal.chytrytrener** (dřív `com.example…`, se kterým
Apple aplikaci nepustí). Firebase o něm musí vědět:

```bash
# smazat starý chybný soubor (má v názvu mezeru)
rm -f "ios/Runner/GoogleService-Info .plist"

firebase login
flutterfire configure --project=fitness-app-spal --platforms=android,ios,macos,windows
```

- Když se zeptá na **iOS bundle ID** nebo **macOS bundle ID**, napiš `cz.spal.chytrytrener`.
- Když se zeptá, jestli přepsat `firebase_options.dart` / `firebase.json`, dej **Yes**.

Pak to ulož do gitu, ať to má i Windows:

```bash
git add -A
git commit -m "Firebase pro iOS a macOS (cz.spal.chytrytrener)"
git push
```

> Po `flutterfire configure` zkontroluj v souboru `firebase.json`, že tam pořád je
> `"firestore": { "rules": "firestore.rules" }`. Kdyby zmizel, napiš mi.

---

## 4. Příprava iOS projektu

```bash
flutter clean
flutter pub get
cd ios
pod install --repo-update
cd ..
open ios/Runner.xcworkspace
```

V Xcode:

1. Vlevo klikni na **Runner** (modrá ikona) → uprostřed target **Runner** → záložka
   **Signing & Capabilities**.
2. **Team** – vyber svůj účet (Add an Account… → přihlas se Apple ID).
3. **Bundle Identifier** musí být `cz.spal.chytrytrener`.
4. V seznamu Capabilities má být **HealthKit** (hodinky).
   - S **placeným** Developer účtem: nech ho tam.
   - Se **zdarma** Apple ID HealthKit nejde – klikni u HealthKit na **×** (jen dočasně,
     tuhle změnu **necommituj**; před dalším `git pull` ji vrať příkazem
     `git checkout ios/`).

---

## 5. Vyzkoušení na vlastním iPhonu (kabelem)

1. Připoj iPhone kabelem, na telefonu potvrď **Důvěřovat**.
2. iPhone: **Nastavení → Soukromí a zabezpečení → Režim vývojáře** → zapnout, restart.
3. Na Macu:

```bash
flutter devices          # iPhone musí být v seznamu
flutter run --release
```

4. Když iPhone hlásí „Nedůvěryhodný vývojář“: **Nastavení → Obecné → Správa VPN
   a zařízení** → tvůj účet → **Důvěřovat**.

Se zdarma účtem aplikace po **7 dnech** přestane fungovat – stačí ji znovu nahrát.

---

## 6. TestFlight – aplikace pro klienty (placený Developer účet)

### Jednou

1. **appstoreconnect.apple.com** → Aplikace → **+** → Nová aplikace
   - Platforma: iOS
   - Název: `SPAL – Chytrý trenér` (název musí být v App Store jedinečný)
   - Jazyk: čeština
   - Bundle ID: `cz.spal.chytrytrener` (když v nabídce není, vytvoř ho na
     developer.apple.com → Identifiers → **+**, se zaškrtnutým HealthKit)
   - SKU: `spal001`
2. Nainstaluj z Mac App Store aplikaci **Transporter** (zdarma).

### Každá nová verze

1. V `pubspec.yaml` zvyš číslo za `+` (např. `version: 1.0.1+3`).
2. Sestavení:

```bash
flutter clean
flutter pub get
flutter build ipa --release
```

3. Otevři **Transporter**, přihlas se, přetáhni soubor z `build/ios/ipa/` → **Doručit**.
4. Za 10–30 min se verze objeví v App Store Connect → **TestFlight**.
   (Otázku na šifrování už aplikace odpovídá sama – nemusíš nic vyplňovat.)

### Pozvání klientů

- **TestFlight → Externí testování → +** → skupina „Klienti“ → přidej sestavení.
  Poprvé ho Apple krátce zkontroluje (obvykle do 1 dne).
- Zapni **Veřejný odkaz** a pošli ho klientům.
- Klient si z App Store stáhne **TestFlight**, otevře odkaz a dá **Instalovat**.
  Další verze mu pak přijdou jako aktualizace.

---

## 7. Aplikace pro Mac (volitelné)

```bash
open macos/Runner.xcworkspace
```

V Xcode → Runner → **Signing & Capabilities** → vyber **Team** (stačí i zdarma Apple ID –
je potřeba kvůli přihlášení do Firebase). Zavři Xcode a:

```bash
flutter build macos --release
open build/macos/Build/Products/Release/
```

Aplikaci **SPAL.app** přetáhni do složky Aplikace. Poprvé ji otevři **pravým tlačítkem →
Otevřít** (macOS se ptá u aplikací mimo App Store).

Na Macu se hodinky nepropojují (to jde jen na telefonu). Exporty klientů se ukládají do
složky aplikace (Dokumenty → Klienti).

---

## 8. Když něco nejde

| Problém | Řešení |
|---|---|
| `pod install` hlásí chybu | `cd ios && rm -rf Pods Podfile.lock && pod install --repo-update && cd ..` |
| „No profiles for 'cz.spal.chytrytrener'“ | V Xcode není vybraný Team, nebo Bundle ID není zaregistrované. |
| „Personal development teams do not support HealthKit“ | Zdarma účet – odeber HealthKit (krok 4) nebo kup Developer Program. |
| iPhone není v `flutter devices` | Odemkni telefon, potvrď Důvěřovat, zapni Režim vývojáře. |
| Přihlášení do aplikace nefunguje | Spustil/a jsi `flutterfire configure` (krok 3)? |
| Cokoli jiného | Pošli mi posledních 30 řádků z Terminálu. |
