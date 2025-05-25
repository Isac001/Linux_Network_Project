#!/bin/bash

# ========================================================
# CONFIGURAÇÃO DE SERVIDOR GATEWAY (NAT) - Ubuntu
# ========================================================

# -------------------------------------------------------------------
# CONFIGURAÇÕES OBRIGATÓRIAS (AJUSTE ANTES DE EXECUTAR!)
# -------------------------------------------------------------------

# Interface conectada à internet (WAN)
INTERNET="enp0s3"    # Normalmente DHCP (pega IP automaticamente)

# Interface de rede interna (LAN)
REDE_INTERNA="enp0s8"
IP_SERVIDOR="192.168.100.1/24"  # IP fixo do servidor na rede interna

# DNS que será repassado aos clientes
DNS_PRIMARIO="8.8.8.8"
DNS_SECUNDARIO="8.8.4.4"

# -------------------------------------------------------------------
# FUNÇÕES PRINCIPAIS
# -------------------------------------------------------------------

configurar_interfaces() {
    echo "[1/3] 🖧 Configurando interfaces de rede..."

    # Criar backup da configuração atual
    sudo cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bak 2>/dev/null || true

    # Gerar arquivo Netplan para servidor gateway
    cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    ${INTERNET}:
      dhcp4: true
      optional: true
      nameservers:
        addresses: [${DNS_PRIMARIO}, ${DNS_SECUNDARIO}]
    ${REDE_INTERNA}:
      addresses: [${IP_SERVIDOR}]
      dhcp4: no
EOF

    # Aplicar configurações
    sudo netplan apply
    echo "✔ Interfaces configuradas:"
    echo "   - ${INTERNET} (WAN): DHCP"
    echo "   - ${REDE_INTERNA} (LAN): ${IP_SERVIDOR}"
}

ativar_roteamento() {
    echo "[2/3] 🔄 Ativando roteamento e NAT..."

    # Habilitar forward de pacotes no kernel
    sudo sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p > /dev/null

    # Configurar regras de NAT
    sudo iptables -t nat -F
    sudo iptables -t nat -A POSTROUTING -o ${INTERNET} -j MASQUERADE
    sudo iptables -A FORWARD -i ${REDE_INTERNA} -o ${INTERNET} -j ACCEPT
    sudo iptables -A FORWARD -i ${INTERNET} -o ${REDE_INTERNA} -m state --state RELATED,ESTABLISHED -j ACCEPT

    # Tornar regras persistentes
    if ! command -v netfilter-persistent &> /dev/null; then
        sudo apt-get install -y iptables-persistent
    fi
    sudo netfilter-persistent save > /dev/null

    echo "✔ Roteamento habilitado com:"
    echo "   - NAT ativo na interface ${INTERNET}"
    echo "   - Forwarding entre ${REDE_INTERNA} ↔ ${INTERNET}"
}

configurar_firewall_basico() {
    echo "[3/3] 🔥 Configurando firewall básico..."

    # Politica padrão DROP para entrada
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP

    # Permitir tráfego estabelecido
    sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

    # Permitir loopback e ping
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

    # Permitir SSH (opcional - descomente se necessário)
    # sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

    # Salvar regras
    sudo netfilter-persistent save > /dev/null

    echo "✔ Firewall configurado:"
    echo "   - Politica padrão: DROP"
    echo "   - Ping e conexões estabelecidas permitidas"
}

# -------------------------------------------------------------------
# EXECUÇÃO DO SCRIPT
# -------------------------------------------------------------------

clear
echo "========================================================"
echo "🛡️  CONFIGURADOR DE SERVIDOR GATEWAY (NAT)"
echo "========================================================"
echo "📡 Interface Internet: ${INTERNET}"
echo "🏠 Interface Interna: ${REDE_INTERNA} (${IP_SERVIDOR})"
echo "🔍 DNS: ${DNS_PRIMARIO}, ${DNS_SECUNDARIO}"
echo "--------------------------------------------------------"

# Verificar root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERRO: Este script deve ser executado como root!" >&2
    echo "Use: sudo $0" >&2
    exit 1
fi

# Verificar interfaces
if ! ip link show ${INTERNET} > /dev/null 2>&1 || ! ip link show ${REDE_INTERNA} > /dev/null 2>&1; then
    echo "ERRO: Interfaces não encontradas!" >&2
    echo "Lista de interfaces disponíveis:" >&2
    ip -brief link show
    exit 1
fi

# Executar configuração
configurar_interfaces
ativar_roteamento
configurar_firewall_basico

echo "--------------------------------------------------------"
echo "✅ CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"
echo "   - Seu servidor agora está funcionando como gateway"
echo "   - Configure os clientes com gateway: ${IP_SERVIDOR%%/*}"
echo "========================================================"