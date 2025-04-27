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
cat $url/recon/sub_live.txt

# Gowitness
echo -e "${orange}[+] Screenshot live subdomains...${reset}"
gowitness scan file -f $url/recon/sub_final.txt --no-http --save-content --write-db
mv gowitness.sqlite3 $url/recon
mv screenshots/ $url/recon


# nmap service enumeration
echo "[+] Enumerating ports and services..."
nmap -sC -sV -iL $(pwd)/$url/recon/sub_live.txt -oA enumeration
cat enumeration.nmap

# nmap all ports, all scripts
echo "[+] Enumerating running scripts..."
nmap -T5 -p- -A -iL $(pwd)/$url/recon/sub_live.txt -oA enumeration
cat scripts.nmap

echo -e "${green}[+]All Finished.${reset}"

#TODO sacar vulnerability a otro script
