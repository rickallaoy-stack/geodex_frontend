$KASSIM_URL = "https://0df3dgx7-3000.uks1.devtunnels.ms"
$LOCAL_URL  = "http://localhost:3000"
$DEVICE     = "chrome"

Write-Host "`n🔍 Détection du serveur backend..." -ForegroundColor Cyan

$useUrl = $null

try {
    $r = Invoke-RestMethod -Uri "$KASSIM_URL/api/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body '{"email":"demo.ministere@mines.ci","password":"demo1234"}' `
        -TimeoutSec 4 `
        -ErrorAction Stop

    if ($r.success) {
        $useUrl = $KASSIM_URL
        Write-Host "✅ Serveur Kassim disponible → $KASSIM_URL" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Serveur Kassim inaccessible, bascule sur local..." -ForegroundColor Yellow

    try {
        $r = Invoke-RestMethod -Uri "$LOCAL_URL/api/auth/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body '{"email":"demo.ministere@mines.ci","password":"demo1234"}' `
            -TimeoutSec 3 `
            -ErrorAction Stop

        if ($r.success) {
            $useUrl = $LOCAL_URL
            Write-Host "✅ Serveur local disponible → $LOCAL_URL" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Aucun serveur disponible. Lance le backend d'abord." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n🚀 Lancement Flutter avec : $useUrl`n" -ForegroundColor Cyan

flutter run -d $DEVICE `
    --dart-define=GEODEX_API_BASE_URL=$useUrl `
    --dart-define=GEODEX_ENV=development
