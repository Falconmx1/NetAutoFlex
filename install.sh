#!/bin/bash
# ==============================================
# NetAutoFlex - Linux Installer
# Version: 1.0
# Author: Falconmx1
# License: MIT
# ==============================================

set -e  # Salir si hay error

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para imprimir banners
print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   ╔═══╗╔╗   ╔╗     ╔═══╗╔╗╔╗╔══╗╔═══╗╔══╗╔╗ ╔╗╔═══╗     ║
║   ║╔═╗║║║   ║║     ║╔══╝║║║║╚╣╠╝║╔═╗║╚╣╠╝║║ ║║║╔══╝     ║
║   ║╚═╝║║║   ║║     ║╚══╗║╚╝║ ║║ ║╚═╝║ ║║ ║║ ║║║╚══╗     ║
║   ║╔╗╔╝║║   ║║     ║╔══╝║╔╗║ ║║ ║╔╗╔╝ ║║ ║║ ║║║╔══╝     ║
║   ║║║╚╗║╚══╗║╚══╗  ║╚══╗║║║║╔╣╠╗║║║╚╗╔╣╠╗║╚═╝║║╚══╗     ║
║   ╚╝╚═╝╚═══╝╚═══╝  ╚═══╝╚╝╚╝╚══╝╚╝╚═╝╚══╝╚═══╝╚═══╝     ║
║                                                          ║
║         Network Automation Tool - Installer              ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Función para detectar distribución
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    echo -e "${GREEN}✓ Detectado: $OS $VER${NC}"
}

# Función para instalar dependencias
install_dependencies() {
    echo -e "${YELLOW}▶ Instalando dependencias...${NC}"
    
    # Actualizar repositorios
    echo -e "${BLUE}→ Actualizando repositorios...${NC}"
    sudo apt update -qq || sudo yum update -q -y || sudo dnf update -q -y || echo -e "${YELLOW}No se pudo actualizar, continuando...${NC}"
    
    # Instalar según distribución
    if command -v apt &> /dev/null; then
        # Debian/Ubuntu
        echo -e "${BLUE}→ Usando apt (Debian/Ubuntu)...${NC}"
        sudo apt install -y -qq \
            nmap \
            traceroute \
            iperf3 \
            curl \
            bc \
            jq \
            arp-scan \
            net-tools \
            iputils-ping \
            dnsutils
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS 7
        echo -e "${BLUE}→ Usando yum (RHEL/CentOS)...${NC}"
        sudo yum install -y -q \
            nmap \
            traceroute \
            iperf3 \
            curl \
            bc \
            jq \
            net-tools \
            iputils
        # arp-scan no está en repositorios default de RHEL
        echo -e "${YELLOW}⚠ arp-scan no disponible, se usará 'ip neigh' en su lugar${NC}"
    elif command -v dnf &> /dev/null; then
        # Fedora
        echo -e "${BLUE}→ Usando dnf (Fedora)...${NC}"
        sudo dnf install -y -q \
            nmap \
            traceroute \
            iperf3 \
            curl \
            bc \
            jq \
            arp-scan \
            net-tools \
            iputils
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        echo -e "${BLUE}→ Usando pacman (Arch)...${NC}"
        sudo pacman -S --noconfirm --needed \
            nmap \
            traceroute \
            iperf3 \
            curl \
            bc \
            jq \
            arp-scan \
            net-tools \
            iputils
    else
        echo -e "${RED}✗ No se pudo detectar el gestor de paquetes${NC}"
        echo -e "${YELLOW}→ Instala manualmente: nmap, traceroute, iperf3, curl, bc, jq${NC}"
    fi
    
    echo -e "${GREEN}✓ Dependencias instaladas${NC}"
}

# Función para configurar script
setup_script() {
    echo -e "${YELLOW}▶ Configurando NetAutoFlex...${NC}"
    
    # Crear directorio de instalación
    INSTALL_DIR="/opt/netautoflex"
    echo -e "${BLUE}→ Instalando en $INSTALL_DIR...${NC}"
    
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp linux/netautoflex.sh "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/netautoflex.sh"
    
    # Crear enlace simbólico
    echo -e "${BLUE}→ Creando enlace global...${NC}"
    sudo ln -sf "$INSTALL_DIR/netautoflex.sh" /usr/local/bin/netautoflex
    
    # Crear directorio de logs
    sudo mkdir -p /var/log/netautoflex
    sudo chmod 755 /var/log/netautoflex
    
    echo -e "${GREEN}✓ Script configurado${NC}"
}

# Función para verificar instalación
verify_installation() {
    echo -e "${YELLOW}▶ Verificando instalación...${NC}"
    
    # Verificar comandos
    COMMANDS=("nmap" "traceroute" "iperf3" "curl" "bc" "jq")
    MISSING=()
    
    for cmd in "${COMMANDS[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            echo -e "${GREEN}  ✓ $cmd${NC}"
        else
            echo -e "${RED}  ✗ $cmd (no encontrado)${NC}"
            MISSING+=("$cmd")
        fi
    done
    
    # Verificar NetAutoFlex
    if command -v netautoflex &> /dev/null; then
        echo -e "${GREEN}  ✓ netautoflex (comando global)${NC}"
    else
        echo -e "${RED}  ✗ netautoflex (no instalado globalmente)${NC}"
    fi
    
    if [ ${#MISSING[@]} -ne 0 ]; then
        echo -e "${YELLOW}⚠ Algunos comandos no se instalaron: ${MISSING[*]}${NC}"
        echo -e "${YELLOW}→ Puedes instalarlos manualmente según sea necesario${NC}"
    fi
}

# Función para mostrar ejemplos
show_examples() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                    EJEMPLOS DE USO                        ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${GREEN}1. Ping sweep:${NC}"
    echo "   netautoflex --ping-scan 192.168.1.0/24"
    echo ""
    echo -e "${GREEN}2. Escaneo de puertos:${NC}"
    echo "   netautoflex --port-scan 192.168.1.1 -p 22,80,443"
    echo ""
    echo -e "${GREEN}3. Geo-traceroute:${NC}"
    echo "   netautoflex --trace google.com --geo"
    echo ""
    echo -e "${GREEN}4. ARP scan (requiere sudo):${NC}"
    echo "   sudo netautoflex --arp-scan"
    echo ""
    echo -e "${GREEN}5. Prueba de ancho de banda:${NC}"
    echo "   netautoflex --bandwidth-test --server iperf.he.net"
    echo ""
    
    echo -e "${YELLOW}📁 Logs guardados en: /var/log/netautoflex/ o ./logs/${NC}"
    echo -e "${YELLOW}📖 Para más ayuda: netautoflex --help${NC}"
}

# Función principal
main() {
    print_banner
    
    echo -e "${GREEN}Iniciando instalación de NetAutoFlex...${NC}\n"
    
    # Verificar si es root
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}✗ No ejecutes como root. Usa sudo cuando sea necesario.${NC}"
        exit 1
    fi
    
    # Detectar sistema
    detect_distro
    
    # Instalar dependencias
    install_dependencies
    
    # Configurar script
    setup_script
    
    # Verificar
    verify_installation
    
    # Mostrar ejemplos
    show_examples
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
    echo -e "║              ✓ INSTALACIÓN COMPLETA ✓                      ║"
    echo -e "╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}🎉 NetAutoFlex está listo para usar!${NC}\n"
}

# Ejecutar main
main
