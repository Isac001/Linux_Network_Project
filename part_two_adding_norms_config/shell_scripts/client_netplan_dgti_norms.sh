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

# (O corpo do script é idêntico ao "setup_internal_server_dgti.sh",
#  mas com uma configuração de portas diferente, mais típica para um cliente).

# --- Variáveis de Configuração ---
LOG_TAG="client-station-setup"
BLOCKLIST_CHAIN="DGTI_HOST_BLOCKLIST"
UPDATE_SCRIPT_PATH="/usr/local/sbin/update_host_blocklist.sh"
BLOCKLIST_URL="https://raw.githubusercontent.com/firehol/firehol_level1/master/firehol_level1.netset"

# --- Portas de Serviço a Liberar (Exemplo para um Servidor Web) ---
# Edite esta variável para os serviços do seu servidor.
# Ex: "80,443" para web, "3306" para MySQL, "22" para SSH.
ALLOWED_TCP_PORTS="22"
ALLOWED_UDP_PORTS=""