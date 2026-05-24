<#
.SYNOPSIS
    NetAutoFlex - Windows Network Automation Tool
.DESCRIPTION
    Herramienta de automatización de tareas de red para Windows
.VERSION
    1.0
.AUTHOR
    Falconmx1
.LICENSE
    MIT
#>

# ==============================================
# CONFIGURACIÓN INICIAL
# ==============================================

# Colores para output (PowerShell 5.1+)
$Colors = @{
    RED     = "`e[91m"
    GREEN   = "`e[92m"
    YELLOW  = "`e[93m"
    BLUE    = "`e[94m"
    NC      = "`e[0m"
}

# Crear directorio de logs
$LogDir = ".\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$LogFile = "$LogDir\netautoflex_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Función de logging
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Level,
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp [$Level] - $Message"
    
    # Colorear según nivel
    switch ($Level) {
        "ERROR"   { Write-Host "$($Colors.RED)$LogMessage$($Colors.NC)" }
        "SUCCESS" { Write-Host "$($Colors.GREEN)$LogMessage$($Colors.NC)" }
        "WARNING" { Write-Host "$($Colors.YELLOW)$LogMessage$($Colors.NC)" }
        "INFO"    { Write-Host "$($Colors.BLUE)$LogMessage$($Colors.NC)" }
        default   { Write-Host $LogMessage }
    }
    
    # Guardar en log (sin colores)
    $LogMessage | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

function Write-Info {
    param([string]$Message)
    Write-Log -Level "INFO" -Message $Message
}

function Write-Success {
    param([string]$Message)
    Write-Log -Level "SUCCESS" -Message $Message
}

function Write-Error {
    param([string]$Message)
    Write-Log -Level "ERROR" -Message $Message
}

# ==============================================
# FUNCIONES PRINCIPALES
# ==============================================

# Mostrar ayuda
function Show-Help {
    @"
${Colors.BLUE}╔══════════════════════════════════════════════════════════╗
║                   NetAutoFlex - Help Menu                    ║
╚══════════════════════════════════════════════════════════════╝${Colors.NC}

${Colors.GREEN}DESCRIPCIÓN:${Colors.NC}
    Herramienta de automatización de tareas de red para Windows

${Colors.GREEN}USO:${Colors.NC}
    .\netautoflex.ps1 [OPCIÓN] [ARGUMENTOS]

${Colors.GREEN}OPCIONES:${Colors.NC}
    ${Colors.YELLOW}-PingScan${Colors.NC} <red>
        Escanea hosts activos en una subred
        Ejemplo: .\netautoflex.ps1 -PingScan "192.168.1.0/24"

    ${Colors.YELLOW}-PortScan${Colors.NC} <IP> -Ports <puertos>
        Escanea puertos TCP en un objetivo
        Ejemplo: .\netautoflex.ps1 -PortScan "192.168.1.1" -Ports "22,80,443"

    ${Colors.YELLOW}-TraceRoute${Colors.NC} <destino> [-Geo]
        Realiza traceroute al destino (con geolocalización opcional)
        Ejemplo: .\netautoflex.ps1 -TraceRoute "google.com"
        Ejemplo: .\netautoflex.ps1 -TraceRoute "google.com" -Geo

    ${Colors.YELLOW}-ArpScan${Colors.NC}
        Descubre dispositivos en la red local (requiere Administrador)

    ${Colors.YELLOW}-BandwidthTest${Colors.NC} [-BandwidthServer <host>] [-ServerMode]
        Prueba de ancho de banda con iperf3
        Modo cliente: .\netautoflex.ps1 -BandwidthTest -BandwidthServer "iperf.he.net"
        Modo servidor: .\netautoflex.ps1 -BandwidthTest -ServerMode

    ${Colors.YELLOW}-Help${Colors.NC}
        Muestra esta ayuda

${Colors.GREEN}EJEMPLOS COMPLETOS:${Colors.NC}
    .\netautoflex.ps1 -PingScan "192.168.1.0/24"
    .\netautoflex.ps1 -PortScan "8.8.8.8" -Ports "53,80,443"
    .\netautoflex.ps1 -TraceRoute "google.com" -Geo
    .\netautoflex.ps1 -ArpScan
    .\netautoflex.ps1 -BandwidthTest -BandwidthServer "iperf.he.net"

${Colors.YELLOW}NOTAS:${Colors.NC}
    - Los logs se guardan en el directorio .\logs\
    - Para -ArpScan se necesitan permisos de Administrador
    - Para -BandwidthTest se necesita iperf3 instalado
"@
}

# Ping sweep
function Invoke-PingSweep {
    param([string]$Network)
    
    Write-Info "Iniciando ping sweep a $Network"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    # Extraer prefijo de red
    $Prefix = $Network -replace '/24','' -replace '\.[0-9]+$',''
    
    1..254 | ForEach-Object {
        $IP = "$Prefix.$_"
        if (Test-Connection -ComputerName $IP -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            Write-Success "Host activo: $IP"
        }
        Start-Sleep -Milliseconds 50  # Evitar saturación
    }
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
}

# Port scan
function Invoke-PortScan {
    param(
        [string]$Target,
        [string]$Ports
    )
    
    Write-Info "Escaneando puertos en $Target"
    Write-Info "Puertos a escanear: $Ports"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    $PortsArray = $Ports -split ','
    foreach ($Port in $PortsArray) {
        try {
            $TcpClient = New-Object System.Net.Sockets.TcpClient
            $Connect = $TcpClient.BeginConnect($Target, $Port, $null, $null)
            $Wait = $Connect.AsyncWaitHandle.WaitOne(2000, $false)
            
            if ($Wait) {
                $TcpClient.EndConnect($Connect)
                Write-Success "Puerto $Port - ABIERTO"
            } else {
                Write-Info "Puerto $Port - CERRADO/FILTRADO"
            }
            $TcpClient.Close()
        } catch {
            Write-Info "Puerto $Port - CERRADO/FILTRADO"
        }
    }
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
}

# Traceroute normal
function Invoke-BasicTraceRoute {
    param([string]$Destination)
    
    Write-Info "Realizando traceroute normal a $Destination"
    tracert -d $Destination | ForEach-Object {
        Write-Info $_
        $_ | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
}

# Geo-traceroute
function Invoke-GeoTraceRoute {
    param([string]$Destination)
    
    Write-Info "Realizando geo-traceroute a $Destination"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    $TraceResult = tracert -d $Destination
    $HopNumber = 1
    
    $TraceResult | Select-String -Pattern '^\s*\d+' | ForEach-Object {
        $Line = $_ -split '\s+'
        $IP = $Line[2]
        
        if ($IP -match '^(\d{1,3}\.){3}\d{1,3}$') {
            try {
                $GeoData = Invoke-RestMethod -Uri "http://ip-api.com/json/$IP" -TimeoutSec 2 -ErrorAction SilentlyContinue
                if ($GeoData.status -eq 'success') {
                    $Message = "Hop $HopNumber`: $IP → $($GeoData.city), $($GeoData.country) ($($GeoData.lat), $($GeoData.lon))"
                    Write-Success $Message
                } else {
                    Write-Info "Hop $HopNumber`: $IP → Ubicación desconocida"
                }
            } catch {
                Write-Info "Hop $HopNumber`: $IP → Error de geolocalización"
            }
        }
        $HopNumber++
        Start-Sleep -Milliseconds 300
    }
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
}

# ARP scan
function Invoke-ArpScan {
    Write-Info "Iniciando escaneo ARP en la red local"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    $ArpTable = arp -a | Select-String -Pattern '(\d{1,3}\.){3}\d{1,3}' | ForEach-Object {
        $Line = $_ -split '\s+'
        if ($Line[0] -match '(\d{1,3}\.){3}\d{1,3}') {
            Write-Success "$($Line[0]) → $($Line[1])"
        }
    }
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
}

# Prueba de ancho de banda
function Invoke-BandwidthTest {
    param(
        [string]$Server,
        [switch]$ServerMode
    )
    
    # Verificar iperf3
    $IperfPath = Get-Command iperf3 -ErrorAction SilentlyContinue
    if (-not $IperfPath) {
        Write-Error "iperf3 no encontrado. Descárgalo de: https://iperf.fr/iperf-download.php#windows"
        Write-Error "Y asegúrate de que esté en el PATH o en el directorio actual"
        exit 1
    }
    
    if ($ServerMode) {
        Write-Info "Iniciando servidor iperf3 en puerto 5201..."
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        & iperf3 -s 2>&1 | ForEach-Object {
            Write-Info $_
        }
    } else {
        Write-Info "Probando ancho de banda contra $Server"
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        
        $Result = & iperf3 -c $Server -t 10 2>&1
        $Result | ForEach-Object {
            Write-Info $_
        }
        
        # Extraer velocidad
        if ($Result -match '([0-9.]+) Mbits/sec.*receiver') {
            Write-Success "Ancho de banda: $($Matches[1]) Mbps"
        }
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    }
}

# ==============================================
# PROGRAMA PRINCIPAL
# ==============================================

# Definir parámetros
param(
    [string]$PingScan,
    [string]$PortScan,
    [string]$Ports,
    [string]$TraceRoute,
    [switch]$Geo,
    [switch]$ArpScan,
    [switch]$BandwidthTest,
    [string]$BandwidthServer,
    [switch]$ServerMode,
    [switch]$Help
)

# Mostrar ayuda
if ($Help -or ($PSBoundParameters.Count -eq 0)) {
    Show-Help
    exit 0
}

Write-Info "Iniciando NetAutoFlex en Windows"

# Verificar permisos de administrador para ARP scan
if ($ArpScan) {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)
    $IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $IsAdmin) {
        Write-Error "Se requieren permisos de Administrador para ARP scan"
        Write-Error "Ejecuta PowerShell como Administrador y vuelve a intentar"
        exit 1
    }
}

# Ejecutar según parámetros
try {
    if ($PingScan) {
        Invoke-PingSweep -Network $PingScan
    }
    
    if ($PortScan -and $Ports) {
        Invoke-PortScan -Target $PortScan -Ports $Ports
    }
    
    if ($TraceRoute) {
        if ($Geo) {
            Invoke-GeoTraceRoute -Destination $TraceRoute
        } else {
            Invoke-BasicTraceRoute -Destination $TraceRoute
        }
    }
    
    if ($ArpScan) {
        Invoke-ArpScan
    }
    
    if ($BandwidthTest) {
        Invoke-BandwidthTest -Server $BandwidthServer -ServerMode:$ServerMode
    }
    
    Write-Success "Script finalizado. Log guardado en: $LogFile"
} catch {
    Write-Error "Error durante la ejecución: $($_.Exception.Message)"
    exit 1
}
