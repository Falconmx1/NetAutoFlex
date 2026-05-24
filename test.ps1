<#
.SYNOPSIS
    NetAutoFlex - Test Suite para Windows
.DESCRIPTION
    Verifica que todas las funcionalidades de NetAutoFlex funcionen correctamente
.AUTHOR
    Falconmx1
.LICENSE
    MIT
#>

# Colores para PowerShell
$Colors = @{
    RED     = "`e[91m"
    GREEN   = "`e[92m"
    YELLOW  = "`e[93m"
    BLUE    = "`e[94m"
    CYAN    = "`e[96m"
    NC      = "`e[0m"
}

# Contadores
$TestsPassed = 0
$TestsFailed = 0
$TestsTotal = 0

# Función para imprimir banner
function Show-Banner {
    Write-Host "$($Colors.CYAN)"
    @"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   ████████╗███████╗███████╗████████╗                     ║
║   ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝                     ║
║      ██║   ███████╗███████╗   ██║                        ║
║      ██║   ╚════██║╚════██║   ██║                        ║
║      ██║   ███████║███████║   ██║                        ║
║      ╚═╝   ╚══════╝╚══════╝   ╚═╝                        ║
║                                                          ║
║              NetAutoFlex - Test Suite                    ║
╚══════════════════════════════════════════════════════════╝
"@
    Write-Host "$($Colors.NC)"
}

# Función para ejecutar pruebas
function Invoke-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestCommand,
        [int]$ExpectedExitCode = 0
    )
    
    $script:TestsTotal++
    
    Write-Host "$($Colors.BLUE)▶ Prueba $script:TestsTotal : $TestName$($Colors.NC)"
    
    try {
        $result = & $TestCommand 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq $ExpectedExitCode) {
            Write-Host "$($Colors.GREEN)  ✓ PASÓ (código de salida: $exitCode)$($Colors.NC)"
            $script:TestsPassed++
            return $true
        } else {
            throw "Código de salida $exitCode (esperaba $ExpectedExitCode)"
        }
    }
    catch {
        Write-Host "$($Colors.RED)  ✗ FALLÓ: $_$($Colors.NC)"
        $script:TestsFailed++
        return $false
    }
}

# Función para verificar comando
function Test-Command {
    param([string]$Command)
    
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    if ($?) {
        Write-Host "$($Colors.GREEN)  ✓ $Command instalado$($Colors.NC)"
        return $true
    } else {
        Write-Host "$($Colors.RED)  ✗ $Command NO instalado$($Colors.NC)"
        return $false
    }
}

# Función para verificar NetAutoFlex
function Test-NetAutoFlex {
    $scriptPath = ".\netautoflex.ps1"
    if (Test-Path $scriptPath) {
        Write-Host "$($Colors.GREEN)  ✓ netautoflex.ps1 encontrado$($Colors.NC)"
        return $true
    } else {
        Write-Host "$($Colors.RED)  ✗ netautoflex.ps1 NO encontrado$($Colors.NC)"
        return $false
    }
}

# ==============================================
# PRUEBAS PRINCIPALES
# ==============================================

function Main {
    Show-Banner
    
    Write-Host "$($Colors.YELLOW)╔══════════════════════════════════════════════════════════╗"
    Write-Host "║                    VERIFICANDO SISTEMA                         ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝$($Colors.NC)`n"
    
    # Verificar sistema
    Write-Host "$($Colors.CYAN)▶ Sistema Operativo:$($Colors.NC)"
    $osInfo = Get-ComputerInfo
    Write-Host "$($Colors.GREEN)  ✓ Windows $($osInfo.WindowsVersion) detectado$($Colors.NC)"
    Write-Host "$($Colors.GREEN)  ✓ PowerShell $($PSVersionTable.PSVersion)$($Colors.NC)"
    
    # Verificar permisos
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Host "$($Colors.GREEN)  ✓ Ejecutando como Administrador$($Colors.NC)"
    } else {
        Write-Host "$($Colors.YELLOW)  ⚠ No se ejecuta como Administrador (algunas pruebas fallarán)$($Colors.NC)"
    }
    
    Write-Host "`n$($Colors.YELLOW)╔══════════════════════════════════════════════════════════╗"
    Write-Host "║              VERIFICANDO DEPENDENCIAS                         ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝$($Colors.NC)`n"
    
    # Verificar dependencias
    Write-Host "$($Colors.CYAN)▶ Dependencias requeridas:$($Colors.NC)"
    Test-Command "nmap"
    Test-Command "iperf3"
    Test-Command "curl"
    
    Write-Host "`n$($Colors.CYAN)▶ NetAutoFlex:$($Colors.NC)"
    Test-NetAutoFlex
    
    Write-Host "`n$($Colors.YELLOW)╔══════════════════════════════════════════════════════════╗"
    Write-Host "║                    EJECUTANDO PRUEBAS                           ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝$($Colors.NC)`n"
    
    # Prueba 1: Help
    Invoke-Test -TestName "Mostrar ayuda" -TestCommand {
        powershell.exe -File ".\netautoflex.ps1" -Help
    } -ExpectedExitCode 0
    
    # Prueba 2: Ping sweep (localhost)
    Invoke-Test -TestName "Ping sweep a localhost/32" -TestCommand {
        powershell.exe -File ".\netautoflex.ps1" -PingScan "127.0.0.1/32"
    } -ExpectedExitCode 0
    
    # Prueba 3: Port scan localhost
    Invoke-Test -TestName "Port scan a localhost (puertos 22,80,443)" -TestCommand {
        powershell.exe -File ".\netautoflex.ps1" -PortScan "127.0.0.1" -Ports "22,80,443"
    } -ExpectedExitCode 0
    
    # Prueba 4: Traceroute básico
    Invoke-Test -TestName "Traceroute a google.com" -TestCommand {
        powershell.exe -File ".\netautoflex.ps1" -TraceRoute "google.com"
    } -ExpectedExitCode 0
    
    # Prueba 5: Geo-traceroute
    Invoke-Test -TestName "Geo-traceroute a google.com" -TestCommand {
        powershell.exe -File ".\netautoflex.ps1" -TraceRoute "google.com" -Geo
    } -ExpectedExitCode 0
    
    # Prueba 6: ARP scan (solo si es Admin)
    if ($isAdmin) {
        Invoke-Test -TestName "ARP scan" -TestCommand {
            powershell.exe -File ".\netautoflex.ps1" -ArpScan
        } -ExpectedExitCode 0
    } else {
        Write-Host "$($Colors.YELLOW)  ⚠ ARP scan omitido (requiere Administrador)$($Colors.NC)"
        $script:TestsTotal++
        $script:TestsPassed++
    }
    
    # Prueba 7: Comando inválido
    Invoke-Test -TestName "Comando inválido (debe fallar)" -TestCommand {
        powershell.exe -File ".\netautoflex.ps1" -ComandoInvalido
    } -ExpectedExitCode 1
    
    Write-Host "`n$($Colors.YELLOW)╔══════════════════════════════════════════════════════════╗"
    Write-Host "║                    RESULTADOS FINALES                          ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝$($Colors.NC)`n"
    
    # Mostrar resumen
    Write-Host "$($Colors.CYAN)📊 Resumen de pruebas:$($Colors.NC)"
    Write-Host "   Total: $TestsTotal"
    Write-Host "$($Colors.GREEN)✅ Pasadas: $TestsPassed$($Colors.NC)"
    Write-Host "$($Colors.RED)❌ Fallidas: $TestsFailed$($Colors.NC)"
    
    if ($TestsTotal -gt 0) {
        $Percent = [math]::Round(($TestsPassed * 100 / $TestsTotal), 2)
        Write-Host "   📈 Tasa de éxito: ${Percent}%"
    }
    
    # Verificar logs
    Write-Host "`n$($Colors.CYAN)📁 Verificando logs:$($Colors.NC)"
    $logDir = ".\logs"
    if (Test-Path $logDir) {
        $logs = Get-ChildItem -Path $logDir -Filter "*.log" | Sort-Object LastWriteTime -Descending
        if ($logs.Count -gt 0) {
            Write-Host "$($Colors.GREEN)  ✓ Logs generados correctamente en $logDir$($Colors.NC)"
            Write-Host "  → Último log: $($logs[0].Name)"
        } else {
            Write-Host "$($Colors.YELLOW)  ⚠ Directorio de logs existe pero está vacío$($Colors.NC)"
        }
    } else {
        Write-Host "$($Colors.YELLOW)  ⚠ No se encontró el directorio de logs$($Colors.NC)"
    }
    
    # Resultado final
    Write-Host "`n$($Colors.YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($Colors.NC)"
    if ($TestsFailed -eq 0) {
        Write-Host "$($Colors.GREEN)🎉 ¡TODAS LAS PRUEBAS PASARON! NetAutoFlex funciona correctamente.$($Colors.NC)"
        exit 0
    } else {
        Write-Host "$($Colors.RED)⚠️ $TestsFailed prueba(s) fallaron. Revisa la instalación.$($Colors.NC)"
        Write-Host "$($Colors.YELLOW)→ Ejecuta '.\install.bat' como Administrador para reinstalar$($Colors.NC)"
        exit 1
    }
}

# Ejecutar pruebas
Main
