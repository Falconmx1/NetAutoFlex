# Prueba rápida de NetAutoFlex para Windows
Write-Host "🚀 Probando NetAutoFlex..." -ForegroundColor Cyan

# Verificar script
if (-not (Test-Path ".\netautoflex.ps1")) {
    Write-Host "❌ NetAutoFlex no encontrado. Ejecuta install.bat como Administrador" -ForegroundColor Red
    exit 1
}

# Probar ayuda
Write-Host "✓ Test 1: Mostrar ayuda" -ForegroundColor Yellow
powershell -File ".\netautoflex.ps1" -Help > $null 2>&1
if ($LASTEXITCODE -eq 0) { Write-Host "  ✅ OK" -ForegroundColor Green } else { Write-Host "  ❌ FAIL" -ForegroundColor Red }

# Probar ping sweep
Write-Host "✓ Test 2: Ping sweep a localhost" -ForegroundColor Yellow
powershell -File ".\netautoflex.ps1" -PingScan "127.0.0.1/32" > $null 2>&1
if ($LASTEXITCODE -eq 0) { Write-Host "  ✅ OK" -ForegroundColor Green } else { Write-Host "  ❌ FAIL" -ForegroundColor Red }

Write-Host "✅ Prueba rápida completada" -ForegroundColor Green
