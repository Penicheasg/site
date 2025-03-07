{ ip -o link show | awk -F': ' '{print $2}'; echo "eth0"; } | while read IFACE; do
    echo "[*] Escaneando VLANs na interface: $IFACE"
    sudo tcpdump -nn -i "$IFACE" -c 20 vlan 2>/dev/null | awk -F'vlan ' '/vlan/ {print $2}' | awk '{print $1}' | sort -u |
    { while read VLAN; do
        echo "[+] VLAN detectada: $VLAN - Criando interface..."
        sudo ip link add link "$IFACE" name "$IFACE.$VLAN" type vlan id "$VLAN"
        sudo ip link set "$IFACE.$VLAN" up
        sudo dhclient "$IFACE.$VLAN" -v 2>/dev/null || echo "[!] DHCP falhou, tentando IP manual..."

        for NET in "192.168.$VLAN.0/24" "10.$VLAN.0.0/16" "172.16.$VLAN.0/24"; do
            echo "[*] Escaneando hosts ativos na rede $NET..."
            sleep 1  # Adiciona um tempo de espera
            { sudo nmap -sn -e "$IFACE.$VLAN" "$NET" 2>/dev/null || sudo nmap -sn -Pn -e "$IFACE.$VLAN" "$NET" 2>/dev/null; } |
            tee scan_hosts.txt | awk '/Nmap scan report/{print $5}'
        done |
        while read IP; do
            [ -z "$IP" ] && continue
            echo "[+] Host encontrado: $IP - Verificando portas abertas..."
            sleep 1  # Pausa antes de cada scan de portas
            { sudo nmap -sS --top-ports 50 -T2 -e "$IFACE.$VLAN" "$IP" 2>/dev/null || sudo nmap -sS -Pn --top-ports 50 -T2 -e "$IFACE.$VLAN" "$IP" 2>/dev/null; } |
            tee scan_ports.txt
        done

        echo "[!] Removendo VLAN $VLAN"
        sudo ip link delete "$IFACE.$VLAN"
    done; }
done
