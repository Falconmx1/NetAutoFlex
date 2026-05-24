#!/bin/bash
# NetAutoFlex - Linux automation script

show_help() {
    echo "Uso: $0 [OPCIÓN] [ARGUMENTOS]"
    echo "Opciones:"
    echo "  --ping-scan <red>     Ej: 192.168.1.0/24"
    echo "  --port-scan <ip> -p <puertos>"
    echo "  --trace <destino>     Ej: google.com"
    echo "  --arp-scan            Escaneo ARP local (sudo)"
    echo "  --bandwidth-test --server <host>"
    exit 0
}

# Crear directorio de logs
mkdir -p logs
LOG_FILE="logs/netautoflex_$(date +%Y%m%d_%H%M%S).log"

# Casos básicos (amplía después)
case "$1" in
    --ping-scan)
        echo "Ejecutando ping sweep a $2..." | tee -a "$LOG_FILE"
        nmap -sn "$2" | tee -a "$LOG_FILE"
        ;;
    --help)
        show_help
        ;;
    *)
        echo "Opción no válida. Usa --help"
        exit 1
        ;;
esac
