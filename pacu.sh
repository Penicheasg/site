#!/bin/bash

INTERFACE="eth0"

echo "[*] Buscando VLANs isoladas..."
tcpdump -nn -i "$INTERFACE" -c 50 vlan 2>/dev/null | awk -F'vlan ' '/vlan/ {print $2}' | awk '{print $1}' | sort -u |
(
    while read -r VLAN; do
        echo "[+] VLAN detectada: $VLAN"

        echo "[*] Tentando spoofing para acessar VLAN $VLAN..."
        sudo ip link add link "$INTERFACE" name "$INTERFACE.$VLAN" type vlan id "$VLAN" && sudo ip link set "$INTERFACE.$VLAN" up &&
        sudo dhclient "$INTERFACE.$VLAN" -v &&

        { sudo nmap -sn -e "$INTERFACE.$VLAN" "192.168.$VLAN.0/24" || sudo nmap -sn -Pn -e "$INTERFACE.$VLAN" "192.168.$VLAN.0/24"; } |
        awk '/Nmap scan report/{print $5}' |
        while read -r IP; do
            echo "[+] Host encontrado: $IP"
            sudo nmap -sS --top-ports 100 -T2 -e "$INTERFACE.$VLAN" "$IP"
        done

        sudo ip link delete "$INTERFACE.$VLAN"
    done
)

echo "[✔] Scan de VLANs isoladas concluído!"
