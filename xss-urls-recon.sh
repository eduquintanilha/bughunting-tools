#!/bin/zsh

# Script para scanner de XSS usando Tor
# Uso: ./xss-scanner.sh <arquivo-subdomains>

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para exibir uso
usage() {
    echo "Uso: $0 <arquivo-subdomains>"
    echo ""
    echo "Exemplo:"
    echo "  $0 subdomains.txt"
    exit 1
}

# Verifica se o arquivo foi passado como argumento
if [ $# -eq 0 ]; then
    echo -e "${RED}[ERRO]${NC} Nenhum arquivo de subdomínios fornecido!"
    usage
fi

SUBDOMAINS_FILE="$1"

# Verifica se o arquivo existe
if [ ! -f "$SUBDOMAINS_FILE" ]; then
    echo -e "${RED}[ERRO]${NC} Arquivo '$SUBDOMAINS_FILE' não encontrado!"
    exit 1
fi

# Verifica dependências
check_dependencies() {
    local deps=("anew" "torsocks" "waymore" "urldedupe" "httpx" "kxss")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[ERRO]${NC} Dependências faltando: ${missing[*]}"
        echo "Instale as ferramentas necessárias antes de continuar."
        exit 1
    fi
}

echo -e "${GREEN}[+]${NC} Verificando dependências..."
check_dependencies

echo -e "${GREEN}[+]${NC} Iniciando scanner XSS"
echo -e "${GREEN}[+]${NC} Arquivo de entrada: $SUBDOMAINS_FILE"
echo ""

# Processa subdomínios com anew e salva em arquivo temporário
temp_file=$(mktemp)
cat "$SUBDOMAINS_FILE" | anew > "$temp_file"

# Contador
total=$(wc -l < "$temp_file")
current=0

# Processa cada subdomínio
while IFS= read -r sub; do
    current=$((current + 1))

    echo -e "${YELLOW}[${current}/${total}]${NC} Processando: ${GREEN}${sub}${NC}"

    # Verifica se já existe arquivo de URLs com conteúdo
    if [ -f "all-urls-$sub" ] && [ -s "all-urls-$sub" ]; then
        echo -e "  ${GREEN}✓${NC} Arquivo all-urls-$sub já existe, pulando coleta..."
    else
        # Reinicia Tor para novo circuito
        echo -e "  ${YELLOW}↻${NC} Reiniciando Tor..."
        sudo service tor restart
        sleep 2

        # Coleta URLs com waymore através do Tor
        echo -e "  ${YELLOW}→${NC} Coletando URLs..."
        echo "$sub" | torsocks waymore -mode U -oU "all-urls-$sub"

        # Verifica se o arquivo de URLs foi criado
        if [ ! -f "all-urls-$sub" ] || [ ! -s "all-urls-$sub" ]; then
            echo -e "  ${RED}✗${NC} Nenhuma URL encontrada para $sub"
            echo ""
            continue
        fi
    fi
    # Verifica se já existe arquivo de dedup com conteúdo
    if [ -f "all-xss-unfiltered-$sub" ]; then
        echo -e "  ${GREEN}✓${NC} Arquivo all-xss-unfiltered-$sub já existe, pulando [DEDUP]..."
    else
        # Deduplica URLs, testa com httpx e filtra XSS
        echo -e "  ${YELLOW}→${NC} Deduplicando e testando URLs..."
        cat "all-urls-$sub" | \
            urldedupe -s | \
            /home/ubuntu/go/bin/httpx -silent -retries 0 -timeout 5 | \
            kxss | \
            grep -v "\[\]" >> "all-xss-unfiltered-$sub"

        # Limpa e deduplica resultados XSS
        echo -e "  ${YELLOW}→${NC} Limpando resultados XSS..."
        if [ -f "all-xss-unfiltered-$sub" ] && [ -s "all-xss-unfiltered-$sub" ]; then
            cat "all-xss-unfiltered-$sub" | \
                cut -d " " -f2 | \
                anew >> "all-xss-unfiltered-clean-$sub"
        fi

        # Verifica se há URLs limpas
        if [ ! -f "all-xss-unfiltered-clean-$sub" ] || [ ! -s "all-xss-unfiltered-clean-$sub" ]; then
            echo -e "  ${YELLOW}⚠${NC} Nenhuma URL limpa para testar"
            echo ""
            continue
        fi

        url_count=$(wc -l < "all-xss-unfiltered-clean-$sub")
        echo -e "  ${GREEN}✓${NC} $url_count URL(s) para testar com Nuclei"
    fi

    echo ""
done < "$temp_file"

# Remove arquivo temporário
rm -f "$temp_file"

echo -e "${GREEN}[✓]${NC} Scan completo!"
echo -e "${GREEN}[+]${NC} Resultados salvos em: all-xss-unfiltered-clean-*"
