# Webová verze Chytrého trenéra (do té doby, než ji schválí Apple) – nahraje se na Cloudflare Pages.
#   cd D:\Fitness\dart_application_1
#   powershell -ExecutionPolicy Bypass -File .\nahrat_web.ps1
# Adresa: https://chytry-trener.pages.dev  (později vlastní doména, např. app.spalgym.cz)
# Zákazník ji otevře v telefonu a dá „Přidat na plochu“ (iPhone: Sdílet → Přidat na plochu).
# Po každé úpravě aplikace stačí skript spustit znovu.
$ErrorActionPreference = "Continue"
$slozka = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $slozka
try {
  Write-Host "1) Sestavení webové verze (pár minut)…" -ForegroundColor Cyan
  cmd /c "flutter pub get 2>&1"
  cmd /c "flutter build web --release 2>&1"
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path "build\web\index.html")) { throw "Sestavení se nepovedlo – pošli Claudovi výpis výše." }

  Write-Host "`n2) Nahrání na Cloudflare…" -ForegroundColor Cyan
  cmd /c "npx --yes wrangler@3 pages project list >nul 2>&1"
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Přihlášení do Cloudflare – otevře se prohlížeč, potvrď Allow." -ForegroundColor Yellow
    npx --yes wrangler@3 login
  }
  cmd /c "npx --yes wrangler@3 pages project create chytry-trener --production-branch main >nul 2>&1"  # poprvé založí
  cmd /c "npx --yes wrangler@3 pages deploy build\web --project-name chytry-trener --branch main --commit-dirty=true 2>&1"
  if ($LASTEXITCODE -ne 0) { throw "Nahrání na Cloudflare se nepovedlo – pošli Claudovi výpis výše." }
} finally { Pop-Location }
Write-Host ""
Write-Host "Webová aplikace: https://chytry-trener.pages.dev" -ForegroundColor Green
Write-Host "Poprvé ještě: Firebase → Authentication → Settings → Authorized domains → přidat chytry-trener.pages.dev" -ForegroundColor Yellow
