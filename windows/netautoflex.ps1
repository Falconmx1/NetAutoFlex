<#
.SYNOPSIS
NetAutoFlex - Herramienta de automatización de red para Windows
.EXAMPLE
.\netautoflex.ps1 -PingScan 192.168.1.0/24
#>

param(
    [string]$PingScan,
    [string]$PortScan,
    [string]$TraceRoute,
    [switch]$ArpScan,
    [switch]$Help
)

$logDir = ".\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir }
$logFile = "$logDir\netautoflex_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $logFile -Append
}

if ($Help) {
    @"
Uso: netautoflex.ps1 [opciones]
  -PingScan <red>      Ej: 192.168.1.0/24
  -PortScan <IP>       (requiere -Ports)
  -TraceRoute <destino>
  -ArpScan
"@
    exit 0
}

if ($PingScan) {
    Write-Log "Iniciando ping sweep a $PingScan"
    $network = $PingScan -replace '/24','.1'
    $ping = Test-Connection -ComputerName $network -Count 1 -Quiet
    Write-Log "Resultado ping a $network : $ping"
}
# Aquí puedes expandir con más funciones (port scan, etc.)
