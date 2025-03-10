{ 
    echo "[*] Detectando VLANs possíveis..." 
    sudo nmap --script=vlan-detect -sn -e eth0 2>/dev/null | awk '/VLAN/ {print $NF}' | sort -u 

    # Gera uma lista de VLANs comuns e outras baseadas em padrões matemáticos
    seq 1 10 4096  # Intervalos de VLANs comuns (1, 11, 21, ..., 4091)
    seq 100 100 1000  # VLANs padrão (100, 200, ..., 1000)
    echo "10 20 30 40 50 99 150 666 777 888 999 4094"  # VLANs críticas e padrões conhecidos
} | sort -nu | while read -r VLAN; do 
    echo "[+] Tentando acessar VLAN: $VLAN" 
    sudo nmap -sn --send-ip -e eth0 "192.168.$VLAN.0/24" | awk '/Nmap scan report/{print $5}' | while read -r IP; do 
        echo "[✔] Encontrado: $IP - Escaneando portas..." 
        sudo nmap -sS --top-ports 50 -T2 -e eth0 "$IP"
    done
done
