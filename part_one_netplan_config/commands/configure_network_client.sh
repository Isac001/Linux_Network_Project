#!/bin/bash

# ========================================================
# CONFIGURAÇÃO DE CLIENTE DESKTOP - Ubuntu
# ========================================================

# -------------------------------------------------------------------
# CONFIGURAÇÕES OBRIGATÓRIAS (AJUSTE ANTES DE EXECUTAR!)
# -------------------------------------------------------------------

# Interface de rede principal
INTERFACE="enp0s3"

# IP do gateway (servidor)
GATEWAY="192.168.100.1"

# Configuração IP do cliente
IP_CLIENTE="192.168.100.2/24"  # Altere o último número para cada cliente

# DNS 
DNS_PRIMARIO="8.8.8.8"
DNS_SECUNDARIO="8.8.4.4"

# -------------------------------------------------------------------
# FUNÇÃO PRINCIPAL
# -------------------------------------------------------------------

configurar_rede() {
    echo "[1/1] 🖧 Configurando interface de rede..."

    # Criar backup da configuração atual
    sudo cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bak 2>/dev/null || true

    # Gerar arquivo Netplan para cliente
    cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    ${INTERFACE}:
      addresses: [${IP_CLIENTE}]
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${DNS_PRIMARIO}, ${DNS_SECUNDARIO}]
EOF

    # Aplicar configurações
    sudo netplan apply
    echo "✔ Rede configurada:"
    echo "   - Interface: ${INTERFACE}"
    echo "   - IP: ${IP_CLIENTE}"
    echo "   - Gateway: ${GATEWAY}"
    echo "   - DNS: ${DNS_PRIMARIO}, ${DNS_SECUNDARIO}"
}

# -------------------------------------------------------------------
# EXECUÇÃO DO SCRIPT
# -------------------------------------------------------------------

clear
echo "========================================================"
echo "💻 CONFIGURADOR DE CLIENTE DESKTOP"
echo "========================================================"
echo "🖥️  Interface: ${INTERFACE}"
echo "📡 Gateway: ${GATEWAY}"
echo "🔢 IP Cliente: ${IP_CLIENTE}"
echo "🔍 DNS: ${DNS_PRIMARIO}, ${DNS_SECUNDARIO}"
echo "--------------------------------------------------------"

# Verificar root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERRO: Este script deve ser executado como root!" >&2
    echo "Use: sudo $0" >&2
    exit 1
fi

# Verificar interface
if ! ip link show ${INTERFACE} > /dev/null 2>&1; then
    echo "ERRO: Interface não encontrada!" >&2
    echo "Interfaces disponíveis:" >&2
    ip -brief link show
    exit 1
fi

# Executar configuração
configurar_rede

# Testar conexão
echo "--------------------------------------------------------"
echo "🧪 Testando conectividade..."
if ping -c 2 ${GATEWAY} &> /dev/null; then
    echo "✅ Conexão com gateway OK!"
else
    echo "⚠️  Não foi possível alcançar o gateway!" >&2
fi

if ping -c 2 ${DNS_PRIMARIO} &> /dev/null; then
    echo "✅ Conexão com internet OK!"
else
    echo "⚠️  Não foi possível alcançar a internet!" >&2
fi

echo "========================================================"
echo "✅ CONFIGURAÇÃO CONCLUÍDA!"
echo "   - Seu cliente está configurado para usar o gateway"
echo "   - IP atual: ${IP_CLIENTE%%/*}"
echo "========================================================"