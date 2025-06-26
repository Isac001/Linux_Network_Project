#!/bin/bash

# ==============================================================================
# SCRIPT DE CONFIGURAÇÃO DE ESTAÇÃO DE TRABALHO (DEFENSE IN DEPTH) - v4.0
# ==============================================================================
# AUTOR:      Isac & João Victor
# DATA:       2025-06-24
# REFERÊNCIA: Normas DGTI/IFCE em um ambiente com pfSense
# DESCRIÇÃO:  Este script configura uma estação de trabalho que opera ATRÁS de
#             um firewall pfSense, focando na segurança do host.
# ==============================================================================

# --- Variáveis de Configuração ---
# Edite esta linha com o endereço da rede que terá acesso administrativo (SSH)
# O formato /24 significa que todos os IPs de 192.168.1.1 a 192.168.1.254 serão permitidos.
MINHA_REDE_LOCAL="192.168.1.0/24"

# --- Comandos do Firewall ---

echo "Iniciando configuração do Firewall IPTables..."

# 1. Limpa todas as regras existentes para começar do zero.
echo "[PASSO 1/5] Limpando regras antigas..."
iptables -F # Limpa (Flush) todas as regras
iptables -X # Apaga (Delete) todas as chains que não são padrão
iptables -Z # Zera contadores de pacotes e bytes

# 2. Define políticas padrão (Default Policies). Esta é a parte mais importante!
# Bloqueia tudo que entra e que é encaminhado. Permite tudo que sai.
echo "[PASSO 2/5] Definindo políticas padrão (Default: DROP)..."
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT

# 3. Permite tráfego da própria máquina (localhost) e conexões já estabelecidas.
# Isso é fundamental para que o sistema funcione corretamente.
echo "[PASSO 3/5] Liberando localhost e conexões estabelecidas..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# 4. Adiciona as regras específicas baseadas no tutorial.
echo "[PASSO 4/5] Adicionando regras específicas (SSH, WEB)..."
# Permite SSH (porta 22) apenas da sua rede local.
iptables -A INPUT -p tcp -s $MINHA_REDE_LOCAL --dport 22 -j ACCEPT

# Permite HTTP (porta 80) e HTTPS (porta 443) de qualquer origem.
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Opcional: Bloqueia PING (ICMP echo-request) de origens externas. Descomente a linha abaixo se desejar.
# iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# 5. Adiciona uma regra de LOG para o tráfego bloqueado (ótimo para depuração).
# Tudo que chegar até aqui na chain INPUT e não corresponder a uma regra será logado antes de ser bloqueado pela política padrão.
echo "[PASSO 5/5] Configurando LOG para pacotes bloqueados..."
iptables -A INPUT -j LOG --log-prefix "IPTables-Dropped: "

echo ""
echo "Configuração do Firewall concluída!"
echo "Para tornar as regras permanentes, siga as instruções de persistência."
echo ""

# Exibe as regras aplicadas
echo "--- REGRAS ATUAIS DO IPTABLES (INPUT) ---"
iptables -L INPUT -n -v