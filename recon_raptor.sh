#!/bin/bash

# Variables
url=$1
red="\033[0;31m"
orange="\033[0;33m"
reset="\033[0m"
green="\033[0;32m"

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
#cat $url/recon/sub_live.txt

# Gowitness
echo -e "${orange}[+] Screenshot live subdomains...${reset}"
gowitness scan file -f $url/recon/sub_final.txt --no-http --save-content --write-db
mv gowitness.sqlite3 $url/recon
mv screenshots/ $url/recon

# Fingerprinting
echo "[+] Fingerprint..."
webanalyze -hosts $(pwd)/$url/recon/sub_live.txt -crawl 2 > $url/recon/finger.txt

# Take over scan
echo "[+] SubDomain Takeover scan ..."
subzy run --targets $(pwd)/$url/recon/sub_live.txt > $url/recon/takeover.txt


# nmap service enumeration
echo "[+] Nmap enumerating ports and services..."
nmap -T5 -p- -A -iL $(pwd)/$url/recon/sub_live.txt -oA $url/recon/enumeration
#cat $url/recon/enumeration.nmap

# Vulnerability scan
echo "[+] Vulnerabilty scan ..."
nuclei -l $(pwd)/$url/recon/sub_live.txt -json-export $url/recon/output.json

echo -e "${green}[+]All Finished.${reset}"
