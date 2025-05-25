# Tutorial Completo de Configuração de Rede no VirtualBox

## 📋 Pré-requisitos
- VirtualBox instalado (versão 6.1 ou superior)
- 2 Máquinas Virtuais Ubuntu (1 Server, 1 Desktop)
- Acesso sudo em ambas as VMs

## 🖥️ Configuração das Interfaces no VirtualBox

### Configuração do Servidor (Gateway/NAT):
1. Selecione sua VM Server no VirtualBox
2. Clique em "Configurações" > "Rede"
3. Adaptador 1:
   - Modo: **NAT**
   - Conectado: ✔
4. Adaptador 2:
   - Modo: **Rede Interna**
   - Nome: "rede-interna" (criar nova se necessário)

### Configuração do Cliente (Desktop):
1. Selecione sua VM Desktop no VirtualBox
2. Clique em "Configurações" > "Rede"
3. Adaptador 1:
   - Modo: **Rede Interna**
   - Nome: "rede-interna" (mesmo nome usado no servidor)

## 🛠️ Configuração do Servidor Gateway

### Script para Servidor (`config_network_server.sh`):
```bash
# Obs: Copie o arquivo config_network_server.sh para sua VM!

chmod +x config_network_server.sh
sudo ./config_network_server.sh
```

## 🛠️ Configuração do CLiente

### Script para Cliente em (`config_network_client.sh`):

```bash
# Obs: Copie o arquivo config_network_client.sh para sua VM!

chmod +x config_network_client.sh
sudo ./config_network_client.sh
```