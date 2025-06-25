#!/bin/bash

# ==============================================================================
# SCRIPT DE CONFIGURAÇÃO DE SERVIDOR INTERNO (DEFENSE IN DEPTH) - v4.0
# ==============================================================================
# AUTOR:      Isac & João Victor
# DATA:       2025-06-24
# REFERÊNCIA: Normas DGTI/IFCE em um ambiente com pfSense
# DESCRIÇÃO:  Este script configura um servidor que opera ATRÁS de um firewall
#             pfSense. O objetivo é a segurança em camadas (Defense in Depth).
#             1. Instala dependências (iptables-persistent).
#             2. Configura um firewall de host focado em INPUT.
#             3. [OPCIONAL] Bloqueia IPs maliciosos conhecidos via cron,
#                adicionando uma camada extra de proteção.
# ==============================================================================

# --- Variáveis de Configuração ---
LOG_TAG="internal-server-setup"
BLOCKLIST_CHAIN="DGTI_HOST_BLOCKLIST"
UPDATE_SCRIPT_PATH="/usr/local/sbin/update_host_blocklist.sh"
BLOCKLIST_URL="https://raw.githubusercontent.com/firehol/firehol_level1/master/firehol_level1.netset"

# --- Portas de Serviço a Liberar (Exemplo para um Servidor Web) ---
# Edite esta variável para os serviços do seu servidor.
# Ex: "80,443" para web, "3306" para MySQL, "22" para SSH.
ALLOWED_TCP_PORTS="22,80,443"
ALLOWED_UDP_PORTS="" # Ex: "53" para DNS

# --- Funções 

log_msg() { echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"; logger -t "${LOG_TAG}" "$1"; }
check_root() { if [ "$(id -u)" -ne 0 ]; then log_msg "ERRO: Root necessário." >&2; exit 1; fi; }
install_dependencies() { log_msg "[1/5] Instalando dependências..."; if ! apt-get update && apt-get install -y iptables-persistent curl; then log_msg "❌ ERRO: Falha ao instalar." >&2; exit 1; fi; log_msg "✅ Dependências instaladas."; }

configure_host_firewall() {
    log_msg "[2/5] Configurando firewall de host (iptables)..."
    iptables -F; iptables -X;

    # Cria a chain de blocklist
    iptables -N ${BLOCKLIST_CHAIN}
    iptables -I INPUT 1 -j ${BLOCKLIST_CHAIN}

    # Política Padrão: Foco em bloquear o que entra.
    iptables -P INPUT   DROP
    iptables -P FORWARD DROP   # Este servidor não roteia nada.
    iptables -P OUTPUT  ACCEPT
    log_msg "   - Política padrão: INPUT/FORWARD=DROP, OUTPUT=ACCEPT."

    # Regras de INPUT (essenciais)
    iptables -A INPUT -i lo -j ACCEPT # Loopback
    iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT # Conexões existentes

    # Regras de INPUT (serviços)
    log_msg "   - Liberando portas de serviço TCP: ${ALLOWED_TCP_PORTS}"
    if [ -n "$ALLOWED_TCP_PORTS" ]; then
        iptables -A INPUT -p tcp -m multiport --dports ${ALLOWED_TCP_PORTS} -j ACCEPT
    fi
    
    log_msg "   - Liberando portas de serviço UDP: ${ALLOWED_UDP_PORTS}"
    if [ -n "$ALLOWED_UDP_PORTS" ]; then
        iptables -A INPUT -p udp -m multiport --dports ${ALLOWED_UDP_PORTS} -j ACCEPT
    fi

    # Regra para permitir Ping
    iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT

    log_msg "✅ Firewall de host configurado."
}

# As funções create_update_script, setup_cron_job, e persist_rules são idênticas
create_update_script() { log_msg "[3/5] Criando script de atualização da blocklist..."; cat > "${UPDATE_SCRIPT_PATH}" << EOL
#!/bin/bash
LOG_TAG="host-blocklist-updater"
BLOCKLIST_CHAIN="${BLOCKLIST_CHAIN}"
BLOCKLIST_URL="${BLOCKLIST_URL}"
TEMP_LIST=\$(mktemp)
logger -t \${LOG_TAG} "Iniciando atualização da blocklist do host..."
if ! curl -s -o "\${TEMP_LIST}" "\${BLOCKLIST_URL}"; then logger -t \${LOG_TAG} "ERRO: Falha ao baixar blocklist."; rm -f "\${TEMP_LIST}"; exit 1; fi
grep -v -E '^#|^$' "\${TEMP_LIST}" > "\${TEMP_LIST}.tmp" && mv "\${TEMP_LIST}.tmp" "\${TEMP_LIST}"
iptables -F \${BLOCKLIST_CHAIN}; while read -r ip; do iptables -A \${BLOCKLIST_CHAIN} -s "\$ip" -j DROP; done < "\${TEMP_LIST}"
COUNT=\$(wc -l < "\${TEMP_LIST}"); logger -t \${LOG_TAG} "Sucesso: Blocklist do host atualizada com \${COUNT} IPs."
rm -f "\${TEMP_LIST}"; exit 0
EOL
chmod 755 "${UPDATE_SCRIPT_PATH}"; log_msg "Script criado."; }

setup_cron_job() { log_msg "[4/5] Configurando tarefa no cron..."; (crontab -l 2>/dev/null | grep -v "${UPDATE_SCRIPT_PATH}") | crontab -; (crontab -l 2>/dev/null; echo "30 */6 * * * ${UPDATE_SCRIPT_PATH}") | crontab -; log_msg "✅ Tarefa do cron configurada."; }
persist_rules() { log_msg "[5/5] Salvando regras..."; if netfilter-persistent save; then log_msg "✅ Regras salvas."; else log_msg "❌ ERRO: Falha ao salvar."; fi; }


# --- Execução Principal ---
main() {
    check_root
    log_msg "====== INICIANDO SETUP DE SERVIDOR INTERNO (DEFENSE IN DEPTH) ======"
    install_dependencies
    configure_host_firewall
    create_update_script
    setup_cron_job
    persist_rules
    log_msg "====== SETUP CONCLUÍDO COM SUCESSO ======"
    log_msg "O servidor agora está protegido por um firewall de host."
    log_msg "Executando a primeira atualização da blocklist agora..."
    ${UPDATE_SCRIPT_PATH}
}

main