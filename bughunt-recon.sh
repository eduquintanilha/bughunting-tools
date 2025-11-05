#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Uso: $0 <PROGRAM_PLATFORM>"
    echo "Exemplo: $0 Redcare/Intigriti"
    exit 1
fi

PROGRAM_PLATFORM="$1"

if [ ! -f "scope" ]; then
    echo "[!] Erro: arquivo 'scope' não encontrado no diretório atual"
    echo "[*] Crie um arquivo 'scope' com os domínios (um por linha)"
    exit 1
fi

if [ ! -s "scope" ]; then
    echo "[!] Erro: arquivo 'scope' está vazio"
    exit 1
fi

echo "## Init recon on $PROGRAM_PLATFORM ##"
echo "[*] $(wc -l < scope) domínios no scope"

echo "[+] Enumerando subdomínios com subfinder..."
cat scope | subfinder -silent -o subdomains -all

echo "[+] Coletando subdomínios via certificados..."
for domain in $(cat scope); do
    get-subdomains-cert.sh "$domain" >> subdomains
done

echo "[+] Deduplicando subdomínios..."
cat subdomains | anew subdomains.tmp && mv subdomains.tmp subdomains
echo "[*] Total: $(wc -l < subdomains) subdomínios únicos"

sudo service tor restart

echo "[+] Coletando URLs com waymore..."
cat scope | torsocks waymore -mode U -oU all-urls

echo "[+] Coletando URLs com gau..."
cat scope | torsocks gau --o gau-urls

echo "[+] Executando nuclei para takeover..."
cat subdomains | nuclei -silent -c 10 -rl 10 -o nuclei-takeover -t ~/nuclei-templates/http/takeovers/

if [ -s nuclei-takeover ]; then
    echo -e "\n## Takeovers encontrados em $PROGRAM_PLATFORM ##\n"
    cat nuclei-takeover | notify -silent
else
    echo "[!] Nenhum takeover encontrado"
fi

cat gau-urls >> all-urls
cat all-urls | anew >> all-urls-uniq
rm all-urls && mv all-urls-uniq all-urls

echo "[+] Buscando secrets em arquivos Javascript..."
cat all-urls | grep "\.js" >> all-js
cat all-js | anew | nuclei -c 10 -rl -30 -t ~/nuclei-templates/http/exposures -o nuclei-js-leaks

if [ -s nuclei-js-leaks ]; then
    echo -e "\n## Leaks encontrados em $PROGRAMA_PLATFORM ##\n"
    cat nuclei-js-leaks | notify -silent
else
    echo "[!] Nenhum JS Leak encontrado"
fi

echo "[✓] Recon completo para $PROGRAM_PLATFORM" | notify -silent

