# install.ps1 - Instalador moderno para Windows PowerShell
Write-Host "Instalando NetAutoFlex..." -ForegroundColor Cyan

# Crear directorios
$InstallDir = "C:\NetAutoFlex"
$LogDir = "$InstallDir\logs"

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

# Copiar script
Copy-Item "windows\netautoflex.ps1" -Destination "$InstallDir\" -Force

# Configurar ejecución
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# Instalar iperf3 con winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install -e --id iperf3.iperf3 --silent
}

# Crear acceso directo
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\NetAutoFlex.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoExit -Command `"cd '$InstallDir'; .\netautoflex.ps1 -Help`""
$Shortcut.Save()

Write-Host "Instalación completada!" -ForegroundColor Green
Write-Host "Ejecuta: cd C:\NetAutoFlex; .\netautoflex.ps1 -Help" -ForegroundColor Yellow
