#!/bin/bash
# ============================================================
# OSINTWHOIS - Kali Linux OSINT Tool
# Created by : Surya – The Cyber Conqueror
# Purpose    : WHOIS, DNS, SSL, HTTP & IP Intelligence (Defensive OSINT)
# License    : MIT
# ============================================================

# ---------------- CONFIG ----------------
AUTHOR="Surya – The Cyber Conqueror"

# ---------------- COLORS ----------------
CYAN="\e[36m"
YELLOW="\e[33m"
GREEN="\e[32m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

# ---------------- BANNER ----------------
banner() {
echo -e "${CYAN}${BOLD}"
cat <<'EOF'
 ██████╗ ███████╗██╗███╗   ██╗████████╗
██╔═══██╗██╔════╝██║████╗  ██║╚══██╔══╝
██║   ██║███████╗██║██╔██╗ ██║   ██║
██║   ██║╚════██║██║██║╚██╗██║   ██║
╚██████╔╝███████║██║██║ ╚████║   ██║
 ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝
EOF
echo -e "${RESET}"
echo -e "${WHITE}OSINTWHOIS – Kali Linux OSINT Tool${RESET}"
echo -e "${YELLOW}Created by :${RESET} ${GREEN}${BOLD}$AUTHOR${RESET}"
echo -e "${YELLOW}Purpose    :${RESET} ${WHITE}Defensive OSINT & Research${RESET}"
}

# ---------------- HELP ----------------
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
banner
echo -e "
Usage:
  osintwhois <domain>

Description:
  Performs raw WHOIS first, followed by
  analyst-style OSINT interpretation.

Author:
  $AUTHOR
"
exit 0
fi

# ---------------- RAW WHOIS ----------------
whois_info() {
    echo -e "\n========== WHOIS INFORMATION =========="
    whois "$1"
}

# ---------------- OSINT FUNCTIONS ----------------
domain_overview() {
    DOMAIN="$1"
    LEN=${#DOMAIN}
    TLD="${DOMAIN##*.}"

    echo -e "\n${CYAN}${BOLD}========== DOMAIN OVERVIEW ==========${RESET}"
    echo -e "${YELLOW}Domain Name          :${RESET} ${WHITE}$DOMAIN${RESET}"
    echo -e "${YELLOW}Domain Length        :${RESET} ${WHITE}$LEN characters${RESET}"
    echo -e "${YELLOW}Top-Level Domain     :${RESET} ${WHITE}.$TLD${RESET}"
    echo -e "${YELLOW}Likely Domain Type   :${RESET} ${WHITE}Commercial / Brand${RESET}"
}

domain_age() {
    CREATION_DATE=$(whois "$1" | grep -Ei "Creation Date|Created On|Registered On" | head -n 1 | awk '{print $NF}')

    echo -e "\n${CYAN}${BOLD}========== DOMAIN AGE INSIGHT ==========${RESET}"

    if [[ -z "$CREATION_DATE" ]]; then
        DOMAIN_AGE=0
        echo -e "${YELLOW}Domain Age           :${RESET} ${WHITE}Unavailable${RESET}"
        return
    fi

    CREATED_YEAR=$(echo "$CREATION_DATE" | cut -d'-' -f1)
    CURRENT_YEAR=$(date +"%Y")
    DOMAIN_AGE=$((CURRENT_YEAR - CREATED_YEAR))

    echo -e "${YELLOW}Creation Date        :${RESET} ${WHITE}$CREATION_DATE${RESET}"
    echo -e "${YELLOW}Domain Age           :${RESET} ${WHITE}$DOMAIN_AGE years${RESET}"
}

ssl_https_check() {
    echo -e "\n${CYAN}${BOLD}========== SSL / HTTPS STATUS ==========${RESET}"

    if echo | timeout 5 openssl s_client -connect "$1:443" 2>/dev/null | grep -q "BEGIN CERTIFICATE"; then
        HTTPS_ENABLED=true
        echo -e "${YELLOW}HTTPS Support        :${RESET} ${GREEN}Enabled${RESET}"
    else
        HTTPS_ENABLED=false
        echo -e "${YELLOW}HTTPS Support        :${RESET} ${WHITE}Not detected${RESET}"
    fi
}

http_headers() {
    echo -e "\n${CYAN}${BOLD}========== HTTP RESPONSE HEADERS ==========${RESET}"
    curl -I --max-time 8 "http://$1" 2>/dev/null || echo "No HTTP response"
}

infrastructure_summary() {
    IP=$(dig +short "$1" | head -n 1)
    NS_COUNT=$(dig "$1" NS +short | wc -l)
    MX_COUNT=$(dig "$1" MX +short | wc -l)

    [[ "$MX_COUNT" -gt 0 ]] && EMAIL_ENABLED=true || EMAIL_ENABLED=false

    echo -e "\n${CYAN}${BOLD}========== INFRASTRUCTURE SUMMARY ==========${RESET}"
    echo -e "${YELLOW}Resolved IP          :${RESET} ${WHITE}$IP${RESET}"
    echo -e "${YELLOW}Hosting Type         :${RESET} ${WHITE}Likely Cloud / CDN${RESET}"

    [[ "$NS_COUNT" -ge 2 ]] \
        && echo -e "${YELLOW}DNS Setup            :${RESET} ${WHITE}Multiple Name Servers (Resilient)${RESET}" \
        || echo -e "${YELLOW}DNS Setup            :${RESET} ${WHITE}Single Name Server${RESET}"
}

registration_insights() {
    echo -e "\n${CYAN}${BOLD}========== REGISTRATION INSIGHTS ==========${RESET}"

    if whois "$1" | grep -Ei "privacy|redacted" >/dev/null; then
        WHOIS_PRIVACY=true
        echo -e "${YELLOW}WHOIS Privacy        :${RESET} ${WHITE}Enabled${RESET}"
        echo -e "${YELLOW}Interpretation       :${RESET} ${WHITE}Common for enterprises & brands${RESET}"
    else
        WHOIS_PRIVACY=false
        echo -e "${YELLOW}WHOIS Privacy        :${RESET} ${WHITE}Disabled${RESET}"
        echo -e "${YELLOW}Interpretation       :${RESET} ${WHITE}Personal or small organization${RESET}"
    fi
}

# 🔥 UPDATED USE CASE LOGIC
possible_use_case() {
    DOMAIN="$1"
    TLD="${DOMAIN##*.}"

    echo -e "\n${CYAN}${BOLD}========== POSSIBLE USE CASE ==========${RESET}"

    if [[ "$TLD" == "gov" || "$TLD" == "edu" ]]; then
        echo -e "${WHITE}• Government or educational institution${RESET}"
        return
    fi

    if [[ "$DOMAIN_AGE" -ge 5 && "$HTTPS_ENABLED" == true && "$WHOIS_PRIVACY" == true ]]; then
        echo -e "${WHITE}• Legitimate business website${RESET}"
        echo -e "${WHITE}• Brand-owned domain${RESET}"
        [[ "$EMAIL_ENABLED" == true ]] && echo -e "${WHITE}• Email-enabled organization${RESET}"
        return
    fi

    if [[ "$HTTPS_ENABLED" == true && "$EMAIL_ENABLED" == true ]]; then
        echo -e "${WHITE}• E-commerce / SaaS platform${RESET}"
        echo -e "${WHITE}• Customer-facing web application${RESET}"
        return
    fi

    echo -e "${WHITE}• Personal project or small website${RESET}"
    echo -e "${WHITE}• Newly registered or low-footprint domain${RESET}"
}

# 🔥 UPDATED SUMMARY
osint_summary() {
    echo -e "\n${CYAN}${BOLD}========== OSINT ANALYST SUMMARY ==========${RESET}"
    echo -e "${WHITE}The observed characteristics suggest the domain’s usage${RESET}"
    echo -e "${WHITE}is consistent with its infrastructure maturity, security${RESET}"
    echo -e "${WHITE}posture, and registration behavior. Findings should be${RESET}"
    echo -e "${WHITE}interpreted as indicative, not conclusive.${RESET}"
}

# ---------------- DNS / RISK / IP ----------------
dns_info() {
    echo -e "\n========== DNS RECORDS =========="
    dig "$DOMAIN" A +short
    dig "$DOMAIN" MX +short
    dig "$DOMAIN" NS +short
}

risk_analysis() {
    echo -e "\n========== RISK ANALYSIS =========="
    whois "$DOMAIN" | grep -Ei "privacy|redacted" >/dev/null \
        && echo "⚠ WHOIS Privacy Enabled → Medium Risk" \
        || echo "✅ WHOIS Public → Low Risk"
}

ip_info() {
    IP=$(dig +short "$DOMAIN" | head -n 1)
    echo -e "\n========== IP INTELLIGENCE =========="
    echo "IP Address: $IP"
    curl -s "http://ip-api.com/json/$IP"
}

# ---------------- MAIN ----------------
banner

if [[ -z "$1" ]]; then
    echo "Usage: osintwhois <domain>"
    exit 1
fi

DOMAIN="$1"

echo -e "\n${GREEN}🔍 Analyzing Domain:${RESET} ${WHITE}$DOMAIN${RESET}"

whois_info "$DOMAIN"

domain_overview "$DOMAIN"
domain_age "$DOMAIN"
ssl_https_check "$DOMAIN"
http_headers "$DOMAIN"
infrastructure_summary "$DOMAIN"
registration_insights "$DOMAIN"
possible_use_case "$DOMAIN"
osint_summary

dns_info
risk_analysis
ip_info

echo -e "\n${GREEN}✅ Scan completed successfully${RESET}"
echo -e "${WHITE}Tool developed by ${GREEN}${BOLD}$AUTHOR${RESET} | OSINT Research\n"
