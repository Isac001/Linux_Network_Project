# Tutorial Completo de Configuração de Rede no VirtualBox: Gateway e Cliente

Este tutorial guia você na configuração de um ambiente de rede virtual seguro no VirtualBox. Você irá configurar uma VM Ubuntu Server para atuar como um gateway seguro (com firewall e NAT) e uma VM Ubuntu Desktop como um cliente que acessa a internet através desse gateway.

O processo utiliza dois scripts shell para automatizar a configuração dentro das máquinas virtuais.

## 📋 Pré-requisitos

- VirtualBox (versão 6.1 ou superior) instalado.
- 2 Máquinas Virtuais Ubuntu prontas (1 Server e 1 Desktop é o recomendado).
- Acesso `sudo` em ambas as VMs.
- Os dois arquivos de script a seguir:
  - `setup-gateway-server.sh`
  - `setup-client.sh`

## 🖥️ Passo 1: Configuração de Rede no VirtualBox

Antes de executar os scripts, você deve configurar os adaptadores de rede virtual para cada VM no Gerenciador do VirtualBox.

### Configuração da VM do Servidor (Gateway):
1.  Selecione sua **VM Servidor** na lista do VirtualBox.
2.  Clique em **Configurações** > **Rede**.
3.  **Adaptador 1:** Esta será nossa interface WAN, conectada à internet.
    -   **Habilitar Placa de Rede**: ✔
    -   **Conectado a**: `NAT`
4.  **Adaptador 2:** Esta será nossa LAN segura, para a rede interna.
    -   **Habilitar Placa de Rede**: ✔
    -   **Conectado a**: `Rede Interna`
    -   **Nome**: `rede-interna` (você pode escolher qualquer nome, mas deve ser consistente).

![Configurações de Rede do Servidor](https://i.imgur.com/k6lP09a.png)

### Configuração da VM do Cliente (Desktop):
1.  Selecione sua **VM Cliente** na lista do VirtualBox.
2.  Clique em **Configurações** > **Rede**.
3.  **Adaptador 1:** Esta máquina se conecta apenas à rede interna segura.
    -   **Habilitar Placa de Rede**: ✔
    -   **Conectado a**: `Rede Interna`
    -   **Nome**: `rede-interna` (use exatamente o mesmo nome do Adaptador 2 do servidor).

![Configurações de Rede do Cliente](https://i.imgur.com/8f9s1w7.png)

## 🛠️ Passo 2: Configuração do Servidor Gateway

Este script irá configurar as interfaces de rede do servidor, habilitar o encaminhamento de IP e configurar um firewall seguro com UFW.

1.  Inicie sua **VM Servidor**.
2.  Copie o arquivo `server_netplan_dgti_norms.sh` para a VM.
3.  **Importante:** O script assume que sua interface WAN é `enp0s3` e sua interface LAN é `enp0s8`. Verifique isso executando `ip a`. Se os nomes forem diferentes, edite as variáveis no topo do script.
4.  Abra um terminal na VM Servidor e execute os seguintes comandos:

    ```bash
    # Torna o script executável
    chmod +x setup-gateway-server.sh

    # Executa o script com privilégios sudo
    sudo ./setup-gateway-server.sh
    ```
O script irá agora configurar tudo automaticamente.

## 🛠️ Passo 3: Configuração da Máquina Cliente

Este script configura a rede do cliente para usar o servidor gateway para todo o tráfego de internet.

1.  Inicie sua **VM Cliente**.
2.  Copie o arquivo `server_netplan_dgti_norms.sh` para a VM.
3.  **Importante:** O script assume que sua interface de rede é `enp0s3`. Verifique isso com `ip a` e edite o script se necessário.
4.  Abra um terminal na VM Cliente e execute os seguintes comandos:
    ```bash
    # Torna o script executável
    chmod +x setup-client.sh

    # Executa o script com privilégios sudo
    sudo ./setup-client.sh
    ```
O cliente está agora configurado para usar o servidor como seu gateway.

## ✅ Passo 4: Verificação

Para confirmar que tudo está funcionando corretamente:

1.  **Na VM Cliente:** Abra um terminal e teste a conexão com a internet. Isso prova que toda a cadeia (Cliente -> Gateway -> NAT -> Internet) está funcionando.
    ```bash
    ping 8.8.8.8
    ```
    Você deve ver respostas de sucesso.

2.  **Na VM do Servidor:** Verifique o status do firewall para ver as regras ativas.
    ```bash
    sudo ufw status verbose
    ```
    Isso mostrará que o firewall está ativo com as políticas que você configurou.

## 🧠 Como Funciona

-   A **VM Servidor** atua como um roteador. Seu `Adaptador 1` (NAT) obtém um endereço IP da sua rede doméstica, permitindo o acesso à internet. Seu `Adaptador 2` (`Rede Interna`) cria uma rede privada e isolada na qual apenas outras VMs podem entrar. O firewall (`UFW`) no servidor protege tanto a si mesmo quanto o cliente de conexões externas indesejadas.
-   A **VM Cliente** tem apenas uma conexão com a `Rede Interna`. Ela está completamente isolada do mundo exterior. O script a configura para enviar todas as suas requisições de rede para o IP interno do servidor (`192.168.100.1`), que então encaminha o tráfego para a internet.