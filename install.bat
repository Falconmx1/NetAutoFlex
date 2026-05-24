@echo off
title NetAutoFlex Installer for Windows
color 0A

:: ==============================================
:: NetAutoFlex - Windows Installer
:: Version: 1.0
:: Author: Falconmx1
:: License: MIT
:: ==============================================

setlocal enabledelayedexpansion

:: Colores para cmd
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: Mostrar banner
echo %BLUE%
echo ╔══════════════════════════════════════════════════════════╗
echo ║                                                          ║
echo ║   ╔═══╗╔╗   ╔╗     ╔═══╗╔╗╔╗╔══╗╔═══╗╔══╗╔╗ ╔╗╔═══╗     ║
echo ║   ║╔═╗║║║   ║║     ║╔══╝║║║║╚╣╠╝║╔═╗║╚╣╠╝║║ ║║║╔══╝     ║
echo ║   ║╚═╝║║║   ║║     ║╚══╗║╚╝║ ║║ ║╚═╝║ ║║ ║║ ║║║╚══╗     ║
echo ║   ║╔╗╔╝║║   ║║     ║╔══╝║╔╗║ ║║ ║╔╗╔╝ ║║ ║║ ║║║╔══╝     ║
echo ║   ║║║╚╗║╚══╗║╚══╗  ║╚══╗║║║║╔╣╠╗║║║╚╗╔╣╠╗║╚═╝║║╚══╗     ║
echo ║   ╚╝╚═╝╚═══╝╚═══╝  ╚═══╝╚╝╚╝╚══╝╚╝╚═╝╚══╝╚═══╝╚═══╝     ║
echo ║                                                          ║
echo ║         Network Automation Tool - Installer              ║
echo ╚══════════════════════════════════════════════════════════╝
echo %NC%
echo.

echo %GREEN%Iniciando instalación de NetAutoFlex para Windows...%NC%
echo.

:: Verificar administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%✗ Error: Se requieren permisos de Administrador%NC%
    echo %YELLOW%→ Ejecuta este script como Administrador%NC%
    echo %YELLOW%→ Haz clic derecho en install.bat ^> "Ejecutar como administrador"%NC%
    pause
    exit /b 1
)
echo %GREEN%✓ Permisos de administrador verificados%NC%

:: Crear directorios
echo %BLUE%▶ Creando directorios...%NC%
set "INSTALL_DIR=C:\NetAutoFlex"
set "LOG_DIR=C:\NetAutoFlex\logs"

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
echo %GREEN%✓ Directorios creados%NC%

:: Copiar script principal
echo %BLUE%▶ Instalando NetAutoFlex...%NC%
copy /Y "windows\netautoflex.ps1" "%INSTALL_DIR%\netautoflex.ps1" > nul
echo %GREEN%✓ Script copiado a %INSTALL_DIR%%NC%

:: Crear archivo de configuración de PowerShell para ejecución
echo %BLUE%▶ Configurando PowerShell...%NC%
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force" > nul 2>&1
echo %GREEN%✓ Política de ejecución configurada%NC%

:: Verificar/Instalar winget (Windows Package Manager)
echo %BLUE%▶ Verificando herramientas necesarias...%NC%

:: Verificar PowerShell version
powershell -Command "$PSVersionTable.PSVersion.Major" > "%TEMP%\psversion.txt"
set /p PS_VERSION=<"%TEMP%\psversion.txt"
del "%TEMP%\psversion.txt"

if %PS_VERSION% LSS 5 (
    echo %YELLOW%⚠ PowerShell 5.1 o superior recomendado%NC%
    echo %YELLOW%→ Descarga desde: https://aka.ms/pscore6%NC%
) else (
    echo %GREEN%✓ PowerShell %PS_VERSION% detectado%NC%
)

:: Verificar e instalar iperf3 usando winget
echo %BLUE%▶ Verificando iperf3...%NC%
winget list --name iperf3 > nul 2>&1
if %errorLevel% neq 0 (
    echo %YELLOW%⚠ iperf3 no encontrado. Instalando...%NC%
    winget install -e --id iperf3.iperf3 --silent > nul 2>&1
    if !errorLevel! equ 0 (
        echo %GREEN%✓ iperf3 instalado correctamente%NC%
    ) else (
        echo %YELLOW%⚠ No se pudo instalar iperf3 automáticamente%NC%
        echo %YELLOW%→ Descarga manual desde: https://iperf.fr/iperf-download.php#windows%NC%
    )
) else (
    echo %GREEN%✓ iperf3 ya está instalado%NC%
)

:: Verificar nmap (opcional)
echo %BLUE%▶ Verificando Nmap (opcional)...%NC%
nmap --version > nul 2>&1
if %errorLevel% neq 0 (
    echo %YELLOW%⚠ Nmap no encontrado (opcional para port scanning avanzado)%NC%
    echo %YELLOW%→ Descarga desde: https://nmap.org/download.html%NC%
) else (
    echo %GREEN%✓ Nmap detectado%NC%
)

:: Crear acceso directo en el escritorio
echo %BLUE%▶ Creando acceso directo...%NC%
set "DESKTOP=%USERPROFILE%\Desktop"
set "SHORTCUT=%DESKTOP%\NetAutoFlex.lnk"

powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT%'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-NoExit -Command \"cd ''%INSTALL_DIR%''; .\netautoflex.ps1 -Help\"'; $Shortcut.Description = 'NetAutoFlex - Network Automation Tool'; $Shortcut.IconLocation = 'powershell.exe,0'; $Shortcut.Save()" > nul 2>&1
echo %GREEN%✓ Acceso directo creado en el escritorio%NC%

:: Crear script de desinstalación
echo %BLUE%▶ Creando desinstalador...%NC%
(
echo @echo off
echo echo Desinstalando NetAutoFlex...
echo rmdir /S /Q "%INSTALL_DIR%"
echo del /Q "%DESKTOP%\NetAutoFlex.lnk"
echo echo Desinstalación completa.
echo pause
) > "%INSTALL_DIR%\uninstall.bat"
echo %GREEN%✓ Desinstalador creado en %INSTALL_DIR%\uninstall.bat%NC%

:: Mostrar información de instalación
echo.
echo %BLUE%╔══════════════════════════════════════════════════════════╗
echo ║                    INFORMACIÓN DE INSTALACIÓN                 ║
echo ╚══════════════════════════════════════════════════════════════╝%NC%
echo.
echo %GREEN%✓ Instalación completada en: %INSTALL_DIR%%NC%
echo %GREEN%✓ Script principal: netautoflex.ps1%NC%
echo %GREEN%✓ Logs guardados en: %LOG_DIR%%NC%
echo.

:: Mostrar ejemplos
echo %BLUE%╔══════════════════════════════════════════════════════════╗
echo ║                    EJEMPLOS DE USO                            ║
echo ╚══════════════════════════════════════════════════════════════╝%NC%
echo.
echo %GREEN%1. Abrir PowerShell como Administrador y navegar a la carpeta:%NC%
echo    cd C:\NetAutoFlex
echo.
echo %GREEN%2. Ping sweep:%NC%
echo    .\netautoflex.ps1 -PingScan "192.168.1.0/24"
echo.
echo %GREEN%3. Escaneo de puertos:%NC%
echo    .\netautoflex.ps1 -PortScan "192.168.1.1" -Ports "22,80,443"
echo.
echo %GREEN%4. Geo-traceroute:%NC%
echo    .\netautoflex.ps1 -TraceRoute "google.com" -Geo
echo.
echo %GREEN%5. ARP scan (requiere Administrador):%NC%
echo    .\netautoflex.ps1 -ArpScan
echo.
echo %GREEN%6. Prueba de ancho de banda:%NC%
echo    .\netautoflex.ps1 -BandwidthTest -BandwidthServer "iperf.he.net"
echo.

:: Crear variable de entorno (opcional)
echo %BLUE%▶ ¿Deseas agregar NetAutoFlex al PATH? (S/N)%NC%
set /p ADD_PATH="→ "

if /i "%ADD_PATH%"=="S" (
    setx PATH "%PATH%;%INSTALL_DIR%" > nul
    echo %GREEN%✓ NetAutoFlex agregado al PATH. Reinicia la terminal para aplicar cambios.%NC%
    echo %GREEN%→ Ahora puedes ejecutar 'netautoflex.ps1' desde cualquier ubicación%NC%
)

echo.
echo %GREEN%╔══════════════════════════════════════════════════════════╗
echo ║              ✓ INSTALACIÓN COMPLETA ✓                          ║
echo ╚══════════════════════════════════════════════════════════════╝%NC%
echo.
echo %YELLOW%🎉 NetAutoFlex está listo para usar!%NC%
echo.
echo %BLUE%📖 Para más ayuda: .\netautoflex.ps1 -Help%NC%
echo.
pause
