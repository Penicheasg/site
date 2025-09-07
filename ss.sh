#!/bin/bash


# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variáveis
ALVO=""
TIPO_ALVO=""

# Função para verificar dependências
verificar_dependencias() {
    echo -e "${BLUE}[+] Verificando dependências...${NC}"

    local ferramentas=("nmap" "./nuclei")
    local faltando=()

    for tool in "${ferramentas[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            faltando+=("$tool")
        fi
    done

    if [ ${#faltando[@]} -eq 0 ]; then
        echo -e "${GREEN}[✓] Todas as ferramentas estão instaladas${NC}"
    else
        echo -e "${RED}[✗] Ferramentas faltando: ${faltando[*]}${NC}"
        echo -e "${YELLOW}[!] Instale as ferramentas manualmente:${NC}"
        for tool in "${faltando[@]}"; do
            case $tool in
                "nmap") echo "  sudo apt install nmap" ;;
                "nuclei") echo "  go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest" ;;
            esac
        done
        exit 1
    fi
}

# Função para obter entrada do usuário
obter_entrada() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║                   TIPO DE ALVO                   ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║ 1. Domínio (exemplo.com)                         ║"
    echo "║ 2. IP (192.168.1.1)                             ║"
    echo "║ 3. Rede (192.168.1.0/24)                        ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"

    read -p "Selecione o tipo de alvo [1-3]: " tipo

    case $tipo in
        1)
            TIPO_ALVO="DOMINIO"
            read -p "Digite o domínio (ex: exemplo.com): " ALVO
            ;;
        2)
            TIPO_ALVO="IP"
            read -p "Digite o IP (ex: 192.168.1.1): " ALVO
            ;;
        3)
            TIPO_ALVO="REDE"
            read -p "Digite a rede (ex: 192.168.1.0/24): " ALVO
            ;;
        *)
            echo -e "${RED}[✗] Opção inválida!${NC}"
            exit 1
            ;;
    esac

    if [ -z "$ALVO" ]; then
        echo -e "${RED}[✗] Nenhum alvo especificado!${NC}"
        exit 1
    fi

    echo -e "${GREEN}[✓] Alvo definido: $ALVO (Tipo: $TIPO_ALVO)${NC}"
}

# Função para executar nmap e mostrar resultados na tela
executar_nmap() {
    echo -e "${BLUE}[+] Executando Nmap avançado...${NC}"

    case $TIPO_ALVO in
        "DOMINIO"|"IP")
            echo -e "${YELLOW}[+] Scan de portas e serviços em $ALVO${NC}"
            nmap -d -A   --script vuln "$ALVO"
            ;;
        "REDE")
            echo -e "${YELLOW}[+] Scan de descubra de hosts na rede $ALVO${NC}"
            nmap -sn  "$ALVO"

            echo -e "${YELLOW}[+] Scan de portas nos hosts encontrados${NC}"
            # Extrair hosts ativos manualmente
            hosts_ativos=$(nmap -sn  "$ALVO" | grep "Nmap scan report" | awk '{print $5}')
            for host in $hosts_ativos; do
                echo -e "${YELLOW}[+] Scan no host: $host${NC}"
                nmap   "$host"
            done
            ;;
    esac

    echo -e "${GREEN}[✓] Scan Nmap concluído${NC}"
}

# Função para executar nuclei e mostrar resultados na tela
executar_nuclei() {
    echo -e "${BLUE}[+] Executando Nuclei para encontrar vulnerabilidades...${NC}"

    # Para domínios, usar subdomínios ativos se encontrados
    if [ "$TIPO_ALVO" = "DOMINIO" ] && [ -n "$subdominios_ativos" ]; then
        echo -e "${YELLOW}[+] Testando vulnerabilidades nos subdomínios ativos...${NC}"
        echo "$subdominios_ativos" |  ./nuclei  -tags exposures,pii,files,logs,xss,sqli -silent
    else
        # Para IPs e redes, testar o alvo diretamente
        echo -e "${YELLOW}[+] Testando vulnerabilidades no alvo...${NC}"
        echo "$ALVO" | ./nuclei  -tags exposures,pii,files,logs,xss,sqli -silent
    fi

    echo -e "${GREEN}[✓] Nuclei concluído${NC}"
}

# Função para gerar relatório resumido na tela
gerar_relatorio() {
    echo -e "${BLUE}[+] RELATÓRIO DE PENTEST${NC}"
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${YELLOW}ALVO:${NC} $ALVO"
    echo -e "${YELLOW}TIPO:${NC} $TIPO_ALVO"
    echo -e "${YELLOW}DATA:${NC} $(date)"
    echo -e "${CYAN}==============================================${NC}"

    echo -e "${GREEN}[✓] Scan concluído com sucesso!${NC}"
    echo -e "${YELLOW}[!] Revise os resultados acima para verificar vulnerabilidades${NC}"
}

# Função principal
main() {
    verificar_dependencias
    obter_entrada
    executar_nmap
    executar_nuclei
    gerar_relatorio
}

# Executar
main "$@"
