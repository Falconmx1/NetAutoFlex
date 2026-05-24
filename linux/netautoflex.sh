#!/bin/bash
# ==============================================
# NetAutoFlex - Linux Network Automation Tool
# Version: 1.0
# Author: Falconmx1
# License: MIT
# ==============================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Crear directorio de logs
mkdir -p logs
LOG_FILE="logs/netautoflex_$(date +%Y%m%d_%H%M%S).log"

# Función de logging
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "$timestamp [$level] - $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$1"
}

log_error() {
    log "ERROR" "$1"
}

log_success() {
    log "SUCCESS" "$1"
}

# Mostrar ayuda
show_help() {
    cat << EOF
${BLUE}╔══════════════════════════════════════════════════════════╗
║                   NetAutoFlex - Help Menu                    ║
╚══════════════════════════════════════════════════════════════╝${NC}

${GREEN}DESCRIPCIÓN:${NC}
    Herramienta de automatización de tareas de red

${GREEN}USO:${NC}
    $0 [OPCIÓN] [ARGUMENTOS]

${GREEN}OPCIONES:${NC}
    ${YELLOW}--ping-scan${NC} <red>
        Escanea hosts activos en una subred
        Ejemplo: $0 --ping-scan 192.168.1.0/24

    ${YELLOW}--port-scan${NC} <IP> -p <puertos>
        Escanea puertos TCP en un objetivo
        Ejemplo: $0 --port-scan 192.168.1.1 -p 22,80,443,3306

    ${YELLOW}--trace${NC} <destino> [--geo]
        Realiza traceroute al destino (con geolocalización opcional)
        Ejemplo: $0 --trace google.com
        Ejemplo: $0 --trace google.com --geo

    ${YELLOW}--arp-scan${NC}
        Descubre dispositivos en la red local (requiere sudo)
        Ejemplo: sudo $0 --arp-scan

    ${YELLOW}--bandwidth-test${NC}
        Prueba de ancho de banda con iperf3
        Modo cliente: $0 --bandwidth-test --server <host>
        Modo servidor: $0 --bandwidth-test --server-mode

    ${YELLOW}--help${NC}
        Muestra esta ayuda

${GREEN}EJEMPLOS COMPLETOS:${NC}
    $0 --ping-scan 192.168.1.0/24
    $0 --port-scan 8.8.8.8 -p 53,80,443
    $0 --trace google.com --geo
    sudo $0 --arp-scan
    $0 --bandwidth-test --server iperf.he.net

${YELLOW}NOTAS:${NC}
    - Los logs se guardan en el directorio ./logs/
    - Para --arp-scan se necesitan permisos de root
    - Para --bandwidth-test se necesita iperf3 instalado
EOF
}

# Ping sweep
ping_sweep() {
    local network=$1
    log_info "Iniciando ping sweep a $network"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    
    # Obtener el prefijo de red
    local prefix=$(echo "$network" | cut -d'/' -f1 | cut -d'.' -f1-3)
    
    for i in {1..254}; do
        local ip="$prefix.$i"
        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            log_success "Host activo: $ip"
        fi
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
}

# Port scan (TCP)
port_scan() {
    local target=$1
    local ports=$2
    
    log_info "Escaneando puertos en $target"
    log_info "Puertos a escanear: $ports"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    
    IFS=',' read -ra PORT_ARRAY <<< "$ports"
    for port in "${PORT_ARRAY[@]}"; do
        timeout 2 bash -c "echo >/dev/tcp/$target/$port" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "Puerto $port - ABIERTO"
        else
            log_info "Puerto $port - CERRADO/FILTRADO"
        fi
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
}

# Traceroute normal
basic_traceroute() {
    local destination=$1
    log_info "Realizando traceroute normal a $destination"
    traceroute "$destination" | tee -a "$LOG_FILE"
}

# Geo-traceroute
geo_traceroute() {
    local destination=$1
    log_info "Realizando geo-traceroute a $destination"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    
    local hop=1
    traceroute -n "$destination" 2>/dev/null | tail -n +2 | while read -r line; do
        local ip=$(echo "$line" | awk '{print $2}')
        
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            # Consultar API de geolocalización
            local geo_data=$(curl -s "http://ip-api.com/line/$ip?fields=country,city,lat,lon" 2>/dev/null)
            
            if [ -n "$geo_data" ] && [ "$geo_data" != "fail" ]; then
                IFS=',' read -r country city lat lon <<< "$geo_data"
                echo -e "${GREEN}Hop $hop: $ip → $city, $country ($lat, $lon)${NC}" | tee -a "$LOG_FILE"
            else
                echo -e "${YELLOW}Hop $hop: $ip → Ubicación desconocida${NC}" | tee -a "$LOG_FILE"
            fi
        fi
        ((hop++))
        sleep 0.3
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
}

# ARP scan
arp_scan() {
    log_info "Iniciando escaneo ARP en la red local"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    
    if command -v arp-scan &> /dev/null; then
        sudo arp-scan --local | grep -E "^[0-9]" | tee -a "$LOG_FILE"
    else
        log_error "arp-scan no está instalado. Instálalo con: sudo apt install arp-scan"
        ip neigh show | tee -a "$LOG_FILE"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
}

# Prueba de ancho de banda
bandwidth_test() {
    local server=$1
    local mode=$2
    
    # Verificar iperf3
    if ! command -v iperf3 &> /dev/null; then
        log_error "iperf3 no está instalado. Instálalo con: sudo apt install iperf3"
        exit 1
    fi
    
    if [ "$mode" == "server" ]; then
        log_info "Iniciando servidor iperf3 en puerto 5201..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
        iperf3 -s | tee -a "$LOG_FILE"
    else
        log_info "Probando ancho de banda contra $server"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
        
        # Ejecutar prueba por 10 segundos
        local result=$(iperf3 -c "$server" -t 10 2>/dev/null | grep -E "sender|receiver")
        
        if [ -n "$result" ]; then
            echo "$result" | tee -a "$LOG_FILE"
            # Extraer velocidad
            local speed=$(echo "$result" | grep "receiver" | awk '{print $7" "$8}')
            log_success "Ancho de banda: $speed"
        else
            log_error "Error en la prueba de ancho de banda"
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    fi
}

# ==============================================
# PROGRAMA PRINCIPAL
# ==============================================

# Verificar argumentos
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Procesar argumentos
case "$1" in
    --ping-scan)
        if [ -z "$2" ]; then
            log_error "Falta la red objetivo"
            echo "Uso: $0 --ping-scan <red> (ej: 192.168.1.0/24)"
            exit 1
        fi
        ping_sweep "$2"
        ;;
    
    --port-scan)
        if [ -z "$2" ] || [ "$3" != "-p" ] || [ -z "$4" ]; then
            log_error "Uso incorrecto"
            echo "Uso: $0 --port-scan <IP> -p <puertos>"
            echo "Ejemplo: $0 --port-scan 192.168.1.1 -p 22,80,443"
            exit 1
        fi
        port_scan "$2" "$4"
        ;;
    
    --trace)
        if [ -z "$2" ]; then
            log_error "Falta el destino"
            echo "Uso: $0 --trace <destino> [--geo]"
            exit 1
        fi
        if [ "$3" == "--geo" ]; then
            geo_traceroute "$2"
        else
            basic_traceroute "$2"
        fi
        ;;
    
    --arp-scan)
        if [ "$EUID" -ne 0 ]; then
            log_error "Se requieren permisos de root para ARP scan"
            echo "Ejecuta: sudo $0 --arp-scan"
            exit 1
        fi
        arp_scan
        ;;
    
    --bandwidth-test)
        if [ "$2" == "--server" ] && [ -n "$3" ]; then
            bandwidth_test "$3" "client"
        elif [ "$2" == "--server-mode" ]; then
            bandwidth_test "" "server"
        else
            log_error "Uso incorrecto"
            echo "Uso:"
            echo "  Cliente: $0 --bandwidth-test --server <host>"
            echo "  Servidor: $0 --bandwidth-test --server-mode"
            exit 1
        fi
        ;;
    
    --help)
        show_help
        ;;
    
    *)
        log_error "Opción no válida: $1"
        echo "Usa --help para ver las opciones disponibles"
        exit 1
        ;;
esac

log_success "Script finalizado. Log guardado en: $LOG_FILE"
