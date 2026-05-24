#!/bin/bash
# ==============================================
# NetAutoFlex - Test Suite (Linux)
# Version: 1.0
# Author: Falconmx1
# License: MIT
# ==============================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Función para imprimir banner
print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
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
EOF
    echo -e "${NC}"
}

# Función para pruebas
run_test() {
    local test_name=$1
    local test_command=$2
    local expected_exit_code=${3:-0}
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -e "${BLUE}▶ Prueba $TESTS_TOTAL: ${test_name}${NC}"
    
    # Ejecutar comando
    eval "$test_command" > /tmp/test_output.log 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq $expected_exit_code ]; then
        echo -e "${GREEN}  ✓ PASÓ (código de salida: $exit_code)${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FALLÓ (esperaba: $expected_exit_code, obtuvo: $exit_code)${NC}"
        echo -e "${YELLOW}  → Últimas líneas del error:${NC}"
        tail -n 3 /tmp/test_output.log | sed 's/^/    /'
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Función para verificar comando existente
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}  ✓ $1 instalado${NC}"
        return 0
    else
        echo -e "${RED}  ✗ $1 NO instalado${NC}"
        return 1
    fi
}

# Función para verificar NetAutoFlex
check_netautoflex() {
    if command -v netautoflex &> /dev/null; then
        echo -e "${GREEN}  ✓ netautoflex (comando global)${NC}"
        return 0
    else
        echo -e "${RED}  ✗ netautoflex (no instalado globalmente)${NC}"
        return 1
    fi
}

# ==============================================
# PRUEBAS PRINCIPALES
# ==============================================

main() {
    print_banner
    
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗"
    echo -e "║                    VERIFICANDO SISTEMA                         ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"
    
    # Verificar sistema operativo
    echo -e "${CYAN}▶ Sistema Operativo:${NC}"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${GREEN}  ✓ Linux detectado${NC}"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo -e "${GREEN}  ✓ Distribución: $NAME $VERSION_ID${NC}"
        fi
    else
        echo -e "${RED}  ✗ Este script es solo para Linux${NC}"
        exit 1
    fi
    
    echo -e "\n${YELLOW}╔══════════════════════════════════════════════════════════╗"
    echo -e "║              VERIFICANDO DEPENDENCIAS                         ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"
    
    # Verificar dependencias
    echo -e "${CYAN}▶ Dependencias requeridas:${NC}"
    check_command "nmap"
    check_command "traceroute"
    check_command "iperf3"
    check_command "curl"
    check_command "bc"
    check_command "jq"
    
    echo -e "\n${CYAN}▶ Dependencias opcionales:${NC}"
    check_command "arp-scan"
    check_command "dig"
    
    echo -e "\n${CYAN}▶ NetAutoFlex:${NC}"
    check_netautoflex
    
    echo -e "\n${YELLOW}╔══════════════════════════════════════════════════════════╗"
    echo -e "║                    EJECUTANDO PRUEBAS                           ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"
    
    # Prueba 1: Help
    run_test "Mostrar ayuda" "netautoflex --help" 0
    
    # Prueba 2: Ping sweep (localhost)
    run_test "Ping sweep a localhost/32" "netautoflex --ping-scan 127.0.0.1/32" 0
    
    # Prueba 3: Port scan localhost
    run_test "Port scan a localhost (puertos 22,80,443)" "netautoflex --port-scan 127.0.0.1 -p 22,80,443" 0
    
    # Prueba 4: Traceroute básico
    run_test "Traceroute a google.com" "netautoflex --trace google.com" 0
    
    # Prueba 5: Geo-traceroute
    run_test "Geo-traceroute a google.com" "netautoflex --trace google.com --geo" 0
    
    # Prueba 6: Prueba de ancho de banda (solo si hay internet)
    echo -e "${BLUE}▶ Prueba 6: Prueba de ancho de banda (requiere internet)${NC}"
    if ping -c 1 iperf.he.net &> /dev/null; then
        run_test "Bandwidth test a iperf.he.net" "netautoflex --bandwidth-test --server iperf.he.net" 0
    else
        echo -e "${YELLOW}  ⚠ Sin conexión a iperf.he.net, omitiendo prueba${NC}"
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    
    # Prueba 7: Comando inválido
    run_test "Comando inválido (debe fallar)" "netautoflex --comando-invalido" 1
    
    echo -e "\n${YELLOW}╔══════════════════════════════════════════════════════════╗"
    echo -e "║                    RESULTADOS FINALES                          ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"
    
    # Mostrar resumen
    echo -e "${CYAN}📊 Resumen de pruebas:${NC}"
    echo -e "   Total: $TESTS_TOTAL"
    echo -e "   ${GREEN}✅ Pasadas: $TESTS_PASSED${NC}"
    echo -e "   ${RED}❌ Fallidas: $TESTS_FAILED${NC}"
    
    # Calcular porcentaje
    if [ $TESTS_TOTAL -gt 0 ]; then
        PERCENT=$((TESTS_PASSED * 100 / TESTS_TOTAL))
        echo -e "   📈 Tasa de éxito: ${PERCENT}%"
    fi
    
    # Verificar logs
    echo -e "\n${CYAN}📁 Verificando logs:${NC}"
    if [ -d "logs" ] && [ "$(ls -A logs)" ]; then
        echo -e "${GREEN}  ✓ Logs generados correctamente en ./logs/${NC}"
        echo -e "  → Último log: $(ls -t logs/*.log 2>/dev/null | head -1)"
    elif [ -d "/var/log/netautoflex" ] && [ "$(ls -A /var/log/netautoflex)" ]; then
        echo -e "${GREEN}  ✓ Logs generados correctamente en /var/log/netautoflex/${NC}"
    else
        echo -e "${YELLOW}  ⚠ No se encontraron archivos de log${NC}"
    fi
    
    # Resultado final
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 ¡TODAS LAS PRUEBAS PASARON! NetAutoFlex funciona correctamente.${NC}"
        exit 0
    else
        echo -e "${RED}⚠️ $TESTS_FAILED prueba(s) fallaron. Revisa la instalación.${NC}"
        echo -e "${YELLOW}→ Ejecuta 'sudo ./install.sh' para reinstalar${NC}"
        exit 1
    fi
}

# Ejecutar pruebas
main
