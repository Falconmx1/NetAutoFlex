#!/bin/bash
# Prueba rápida de NetAutoFlex

echo "🚀 Probando NetAutoFlex..."

# Verificar instalación
if ! command -v netautoflex &> /dev/null; then
    echo "❌ NetAutoFlex no instalado. Ejecuta: sudo ./install.sh"
    exit 1
fi

# Probar ping sweep rápido
echo "✓ Test 1: Ping sweep a localhost"
netautoflex --ping-scan 127.0.0.1/32 > /dev/null 2>&1 && echo "  ✅ OK" || echo "  ❌ FAIL"

# Probar ayuda
echo "✓ Test 2: Mostrar ayuda"
netautoflex --help > /dev/null 2>&1 && echo "  ✅ OK" || echo "  ❌ FAIL"

echo "✅ Prueba rápida completada"
