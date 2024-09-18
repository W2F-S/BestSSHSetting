#!/bin/bash

# Function to print messages in colors
print_yellow() { echo -e "\e[33m$1\e[0m"; }
print_green() { echo -e "\e[32m$1\e[0m"; }
print_red() { echo -e "\e[31m$1\e[0m"; }

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    print_red "Please run as root"
    exit 1
fi

# Define license keys (base64 encoded)
license_keys=(
    "YTJjci1lazVkLWFlZXctNTRjZA=="  # a2cr-ek5d-aeew-54cd
    "a2VpNy1jbHc4LWFreDItcTE3NA=="  # kei7-clw8-akx2-q174
    "c2tyZS0zazRtLW5ta24tNDdydA=="  # skre-3k4m-nmkn-47rt
)

# License verification
read -p "$(print_yellow 'Please enter your license key: ')" license_input
encoded_license=$(echo -n "$license_input" | base64)

if [[ ! " ${license_keys[@]} " =~ " ${encoded_license} " ]]; then
    print_red "Invalid license!"
    exit 1
else
    print_green "License verified successfully."
fi

# Main menu
main_menu() {
    clear
    print_green "------ W2F ------"
    print_green "1) Install Panel"
    print_green "2) Download Website"
    print_green "3) Run Linux Optimizer"
    print_green "4) Configure Firewall"
    print_green "5) Obtain SSL Certificates"
    print_green "6) Tunnel Menu"
    print_green "7) Abuse Defender"
    print_green "8) Exit"
    
    read -p "$(print_yellow 'Please select an option: ')" choice
    case $choice in
        1) install_panel ;;
        2) download_website ;;
        3) run_optimizer ;;
        4) configure_firewall ;;
        5) obtain_ssl ;;
        6) tunnel_menu ;;
        7) abuse_defender_menu ;;
        8) exit 0 ;;
        *) print_red "Invalid option!" && main_menu ;;
    esac
}

# Function to install panel
install_panel() {
    print_yellow "Please select a panel to install:"
    print_yellow "1) Sanaei X-UI"
    print_yellow "2) Alireza X-UI"
    print_yellow "3) Marzban"
    print_yellow "4) S-UI"
    print_yellow "5) WireGuard"
    print_yellow "6) OpenVPN"
    print_yellow "7) L2TP"
    print_yellow "8) PPTP"
    
    read -p "$(print_yellow 'Enter your choice: ')" panel_choice
    case $panel_choice in
        1) print_green "Installing Sanaei X-UI..." && bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) ;;
        2) print_green "Installing Alireza X-UI..." && bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) ;;
        3) print_green "Installing Marzban..." && bash <(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)@install ;;
        4) print_green "Installing S-UI..." && bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh) ;;
        5) print_green "Installing WireGuard..." && bash <(curl -Ls https://git.io/wireguard -O wireguard-install.sh && bash wireguard-install.sh) ;;
        6) print_green "Installing OpenVPN..." && bash <(curl -Ls https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh) ;;
        7) print_green "Installing L2TP..." && apt-get install -y strongswan xl2tpd ;;
        8) print_green "Installing PPTP..." && apt-get install -y pptpd ;;
        *) print_red "Invalid choice!" && install_panel ;;
    esac
    main_menu
}

# Function to download website
download_website() {
    read -p "$(print_yellow 'Please enter the website URL to download: ')" site_url
    wget --no-check-certificate -O /var/www/html/index.html "$site_url"
    print_green "Website downloaded."
    main_menu
}

# Function to run Linux optimizer
run_optimizer() {
    print_green "Running Linux optimizer..."
    wget "https://raw.githubusercontent.com/hawshemi/Linux-Optimizer/main/linux-optimizer.sh" -O linux-optimizer.sh
    chmod +x linux-optimizer.sh
    bash linux-optimizer.sh
    print_green "Linux optimizer completed."
    main_menu
}

# Function to configure firewall
configure_firewall() {
    ufw enable
    ufw allow OpenSSH
    ufw allow 22
    ufw allow 80
    ufw allow 443
    ufw allow 8443
    print_green "Firewall configured."
    main_menu
}

# Function to obtain SSL certificates
obtain_ssl() {
    systemctl stop apache2
    print_green "Apache stopped for SSL installation."

    # Run the ESSL script to obtain SSL
    bash <(curl -sL https://github.com/erfjab/ESSL/raw/main/essl.sh)

    systemctl start apache2
    print_green "Apache restarted after SSL installation."
    main_menu
}

# Function to display tunnel menu
tunnel_menu() {
    print_yellow "------ Tunnel Menu ------"
    print_yellow "1) Rathole Version 1"
    print_yellow "2) Rathole Version 2"
    print_yellow "3) IPtables Tunnel"
    print_yellow "4) Reverse Tunnel"
    print_yellow "5) 6to4 + GRE Tunnel"
    print_yellow "6) ISATAP TUNNEL"
    print_yellow "7) Return to Main Menu"
    
    read -p "$(print_yellow 'Please select a tunnel option: ')" tunnel_choice
    case $tunnel_choice in
        1) bash <(curl -Ls https://raw.githubusercontent.com/Musixal/rathole-tunnel/main/rathole.sh) ;;
        2) bash <(curl -Ls https://raw.githubusercontent.com/Musixal/rathole-tunnel/main/rathole_v2.sh) ;;
        3) # IPtables Tunnel
           print_green "Configuring IPtables tunnel..."
           iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.100:8080 ;;
        4) bash <(curl -fsSL https://raw.githubusercontent.com/armanibash/RTT-ReverseTlsTunnel/main/install.sh) ;;
        5) print_green "Setting up 6to4 + GRE tunnel..." && ip tunnel add gre1 mode gre remote 192.168.1.1 local 192.168.1.2 ttl 255 && ip link set gre1 up ;;
        6) bash <(curl -fsSL https://raw.githubusercontent.com/W2F-Sa/tunnel-met/main/main.shh) ;;
        7) main_menu ;;
        *) print_red "Invalid choice!" && tunnel_menu ;;
    esac
    main_menu
}

# Abuse Defender menu
abuse_defender_menu() {
    print_yellow "----------- Abuse Defender -----------"
    print_yellow "1) Block Abuse IP-Ranges"
    print_yellow "2) Whitelist an IP/IP-Ranges manually"
    print_yellow "3) Block an IP/IP-Ranges manually"
    print_yellow "4) View Rules"
    print_yellow "5) Clear all rules"
    print_yellow "6) Return to Main Menu"
    
    read -p "$(print_yellow 'Enter your choice: ')" abuse_choice
    case $abuse_choice in
        1) block_ips ;;
        2) whitelist_ips ;;
        3) block_custom_ips ;;
        4) view_rules ;;
        5) clear_chain ;;
        6) main_menu ;;
        *) print_red "Invalid option!" && abuse_defender_menu ;;
    esac
}

# Abuse Defender functions
block_ips() {
    print_green "Blocking abuse IP ranges..."
    # Download and block abuse IPs
    IP_LIST=$(curl -s 'https://raw.githubusercontent.com/Kiya6955/Abuse-Defender/main/abuse-ips.ipv4')
    for IP in $IP_LIST; do
        iptables -A INPUT -s $IP -j DROP
    done
    iptables-save > /etc/iptables/rules.v4
    print_green "Abuse IPs blocked."
    abuse_defender_menu
}

whitelist_ips() {
    read -p "$(print_yellow 'Enter IP or Range to whitelist: ')" ip_range
    iptables -I INPUT -s $ip_range -j ACCEPT
    iptables-save > /etc/iptables/rules.v4
    print_green "$ip_range whitelisted."
    abuse_defender_menu
}

block_custom_ips() {
    read -p "$(print_yellow 'Enter IP or Range to block: ')" ip_range
    iptables -A INPUT -s $ip_range -j DROP
    iptables-save > /etc/iptables/rules.v4
    print_green "$ip_range blocked."
    abuse_defender_menu
}

view_rules() {
    iptables -L -n
    read -p "$(print_yellow 'Press enter to return to Menu...')" dummy
    abuse_defender_menu
}

clear_chain() {
    iptables -F INPUT
    iptables-save > /etc/iptables/rules.v4
    print_green "All rules cleared."
    abuse_defender_menu
}

# Start the script by showing the main menu
main_menu
