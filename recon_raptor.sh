#!/bin/bash

# Variables
url=$1
red="\033[0;31m"
orange="\033[0;33m"
reset="\033[0m"
green="\033[0;32m"
archivo="sub_live.txt"
registros="TXT MX NS A SOA"
salida="dnsenum.txt"

# Función de pausa interactiva
pause_step() {
  read -p "¿Deseas continuar con el siguiente paso? (y/n): " choice
  if [[ "$choice" != "y" ]]; then
    echo -e "${red}Script interrumpido por el usuario.${reset}"
    exit 1
  fi
}

# Creacion de directoris
if [ ! -d "url" ]; then
    mkdir $url
fi

if [ ! -d "url/recon" ]; then
    mkdir $url/recon
fi

# Asset Finder
echo -e "${orange}[+] Getting subdomains...${reset}"
assetfinder $url >> $url/recon/sub_raw.txt
cat $url/recon/sub_raw.txt | grep $1 >> $url/recon/sub_final.txt

# httprobe
echo -e "${orange}[+] Verifiying live subdomains...${reset}"
cat $url/recon/sub_final.txt | sort -u | httprobe | sed 's/https\?:\/\///' | tr -d ':443' >> $url/recon/sub_live.txt
cat $url/recon/sub_live.txt

pause_step

# Gowitness
echo -e "${orange}[+] Screenshot live subdomains...${reset}"
gowitness scan file -f $url/recon/sub_final.txt --no-http --save-content --write-db
mv gowitness.sqlite3 $url/recon
mv screenshots/ $url/recon

pause_step

# DNS Enumeration

archivo="sub_final.txt"
salida="dnsenum.txt"
registros="TXT MX NS A SOA"

# Vaciar el archivo de salida antes de empezar
> "$salida"

while IFS= read -r dominio; do
  echo "===== $dominio =====" | tee -a "$salida"
  for tipo in $registros; do
    echo "--- [$tipo] ---" | tee -a "$salida"
    dig @8.8.8.8 "$dominio" "$tipo" +nocmd +noall +answer | tee -a "$salida"
  done
  echo "" | tee -a $(pwd)/$url/recon/$salida
done < "$(pwd)/$url/recon/$archivo"
cat $(pwd)/$url/recon/$salida

pause_step

# Fingerprinting
echo "[+] Fingerprint..."
webanalyze -hosts $(pwd)/$url/recon/sub_live.txt -crawl 2 > $url/recon/finger.txt
cat $url/recon/finger.txt

pause_step

# Take over scan
echo "[+] SubDomain Takeover scan ..."
subzy run --targets $(pwd)/$url/recon/sub_live.txt > $url/recon/takeover.txt
cat $url/recon/takeover.txt

pause_step

# nmap service enumeration
echo "[+] Nmap enumerating ports and services..."
nmap -sC -sV -iL $(pwd)/$url/recon/sub_live.txt -oA $url/recon/enumeration
cat $url/recon/enumeration.nmap


pause_step

# Vulnerability scan
echo "[+] Vulnerabilty scan ..."
nuclei -l $(pwd)/$url/recon/sub_live.txt -json-export $url/recon/output.json
cat $url/recon/output.json

echo -e "${green}[+]All Finished.${reset}"
