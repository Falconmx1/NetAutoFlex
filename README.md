# NetAutoFlex 🚀

**Automation tool for network tasks (ping, traceroute, port scan, ARP scan, bandwidth test) on Windows & Linux.**

NetAutoFlex es una herramienta CLI diseñada para **administradores de red, entusiastas de cybersecurity y devops** que necesitan ejecutar tareas de red recurrentes de forma rápida y automatizada, tanto en entornos Windows como Linux.

![GitHub](https://img.shields.io/badge/OS-Linux%20%7C%20Windows-blue)
![License](https://img.shields.io/github/license/Falconmx1/NetAutoFlex)
![Bash](https://img.shields.io/badge/script-Bash-green)
![PowerShell](https://img.shields.io/badge/script-PowerShell-blue)

---

## ✨ Características principales

| Función | Descripción | Linux | Windows |
|---------|-------------|:-----:|:-------:|
| **Ping sweep** | Escanea una subred completa para detectar hosts activos | ✅ | ✅ |
| **Traceroute** | Muestra la ruta de paquetes a un destino | ✅ | ✅ |
| **Port scan** | Escanea puertos TCP/UDP en un objetivo | ✅ | ✅ |
| **ARP scan** | Descubre dispositivos en la red local (nivel 2) | ✅ | ⚠️* |
| **Bandwidth test** | Prueba de ancho de banda con iperf3 | ✅ | ✅ |
| **Logging** | Guarda todos los resultados en archivos con timestamp | ✅ | ✅ |

> *⚠️ En Windows requiere PowerShell como Administrador o WSL.

---

## 📦 Requisitos previos

### Linux (Debian/Ubuntu)
```bash
sudo apt update && sudo apt install -y iputils-ping traceroute net-tools nmap iperf3

Windows (PowerShell 5.1+)

    Ejecutar como Administrador para ARP scan y ping sweep completo.

    Opcional: Nmap para Windows (para port scanning avanzado).

    Opcional: iperf3 para Windows.

🔧 Instalación
Clonar repositorio

git clone https://github.com/Falconmx1/NetAutoFlex.git
cd NetAutoFlex

Linux - hacer ejecutable
chmod +x linux/netautoflex.sh
sudo ln -s $(pwd)/linux/netautoflex.sh /usr/local/bin/netautoflex  # opcional: comando global

Windows - ejecución
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\windows\netautoflex.ps1 -Help

🚀 Ejemplos de uso

Linux (Bash)
# Ping sweep a la red local
./linux/netautoflex.sh --ping-scan 192.168.1.0/24

# Escaneo de puertos comunes
./linux/netautoflex.sh --port-scan 192.168.1.10 -p 22,80,443,3306

# Traceroute con geolocalización
./linux/netautoflex.sh --trace google.com --geo

# Escaneo ARP completo
sudo ./linux/netautoflex.sh --arp-scan

# Prueba de ancho de banda (cliente)
./linux/netautoflex.sh --bandwidth-test --server iperf.he.net

Windows (PowerShell)
# Ping sweep
.\windows\netautoflex.ps1 -PingScan 192.168.1.0/24

# Port scan básico
.\windows\netautoflex.ps1 -PortScan 192.168.1.1 -Ports 80,443,3389

# Escaneo ARP (requiere Admin)
.\windows\netautoflex.ps1 -ArpScan

# Guardar resultado en archivo personalizado
.\windows\netautoflex.ps1 -TraceRoute google.com -LogPath C:\logs\mired.txt
