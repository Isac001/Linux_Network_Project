# Guia de Configuração de Rede com Gateway no VirtualBox

Este guia descreve o passo a passo para configurar um ambiente de rede com um servidor gateway e uma máquina cliente usando scripts de automação no VirtualBox.

## Pré-requisitos

-   VirtualBox instalado.
-   Duas máquinas virtuais Ubuntu (1 Server, 1 Desktop).
-   Os scripts `server_netplan_dgti_norms.sh` e `client_netplan_dgti_norms.sh`.

---

## Passo 1: Configurar a Rede no VirtualBox

Antes de ligar as máquinas, ajuste as configurações de rede de cada uma.

#### 1. VM Servidor (Gateway)

-   **Adaptador 1:** Conectado a `NAT`.
-   **Adaptador 2:** Conectado a `Rede Interna` com o nome `rede-interna`.

#### 2. VM Cliente (Desktop)

-   **Adaptador 1:** Conectado a `Rede Interna` com o nome `rede-interna`.

---

## Passo 2: Executar o Script no Servidor Gateway

1.  Inicie a **VM Servidor**.

2.  Copie o script `server_netplan_dgti_norms.sh` para dentro da VM.

3.  Verifique os nomes das interfaces de rede com o comando `ip a`. O script assume `enp0s3` para a WAN (NAT) e `enp0s8` para a LAN (Rede Interna). Se os nomes forem diferentes, edite as variáveis no topo do script.

4.  Execute os seguintes comandos no terminal do servidor:

    ```bash
    # Dar permissão de execução ao script
    chmod +x server_netplan_dgti_norms.sh

    # Executar o script como administrador
    sudo ./server_netplan_dgti_norms.sh
    ```

---

## Passo 3: Executar o Script na Máquina Cliente

1.  Inicie a **VM Cliente**.

2.  Copie o script `client_netplan_dgti_norms.sh` para dentro da VM.

3.  Verifique o nome da interface de rede com `ip a`. O script assume `enp0s3`. Edite o script se o nome for diferente.

4.  Execute os seguintes comandos no terminal do cliente:

    ```bash
    # Dar permissão de execução ao script
    chmod +x client_netplan_dgti_norms.sh

    # Executar o script como administrador
    sudo ./client_netplan_dgti_norms.sh
    ```

---