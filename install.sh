#!/bin/bash

# OSINT WHOIS Tool Installer
# Created by Surya – The Cyber Conqueror

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please run as root: sudo ./install.sh"
    exit 1
fi

echo "[+] Installing OSINT WHOIS Tool..."

chmod +x osintwhois.sh

mv osintwhois.sh /usr/bin/osintwhois

echo "[✓] Installation completed successfully!"
echo "[✓] You can now run the tool globally using: osintwhois"
