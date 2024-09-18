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

# Define the base64 encoded password
encoded_password="VzJGU2NyaXB0U1NI"

# Prompt user for password
read -sp "$(print_yellow 'Please enter the script password: ')" user_password
echo

# Encode the entered password
user_encoded_password=$(echo -n "$user_password" | base64)

# Check the password
if [[ "$user_encoded_password" != "$encoded_password" ]]; then
    print_red "Incorrect password!"
    exit 1
else
    print_green "Password is correct. Running the script..."
fi

# Function to install panel
install_panel() {
    read -p "$(print_yellow 'Do you want to install a panel? (y/n): ')" install_panel
    if [[ "$install_panel" == "y" ]]; then
        print_yellow "Please select a panel to install:"
        print_yellow "1) Sanaei X-UI"
        print_yellow "2) Alireza X-UI"
        print_yellow "3) Marzban"
        print_yellow "4) S-UI"
        print_yellow "5) WireGuard"
        print_yellow "6) OpenVPN"
        
        read -p "$(print_yellow 'Enter the number of your choice: ')" panel_choice
        
        case $panel_choice in
            1) print_green "Installing Sanaei X-UI..."
               bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) ;;
            2) print_green "Installing Alireza X-UI..."
               bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) ;;
            3) print_green "Installing Marzban..."
               sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)@install"
               marzban cli admin create --sudo
               apt install -y ufw
               ufw allow 8000
               read -p "$(print_yellow 'Do you want to run the IP2Limit script? (y/n): ')" run_ip2limit
               if [[ "$run_ip2limit" == "y" ]]; then
                   bash <(curl -sSL https://houshmand-2005.github.io/v2iplimit.sh)
               fi ;;
            4) print_green "Installing S-UI..."
               bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh) ;;
            5) print_green "Installing WireGuard..."
               wget https://git.io/wireguard -O wireguard-install.sh && bash wireguard-install.sh ;;
            6) print_green "Installing OpenVPN..."
               wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh ;;
            *) print_red "Invalid choice. Exiting." ;;
        esac
    fi
}

# Function to download website
download_website() {
    read -p "$(print_yellow 'Please enter the website URL to download: ')" site_url
    wget --no-check-certificate -O /var/www/html/index.html "$site_url"
    read -p "$(print_yellow 'Please enter the website directory name: ')" site_dir
    chown -R www-data:www-data /var/www/html/"$site_dir"
    chmod -R 755 /var/www/html/"$site_dir"
}

# Function to optimize Linux
run_optimizer() {
    read -p "$(print_yellow 'Do you want to run the Linux Optimizer script? (y/n): ')" run_optimizer
    if [[ "$run_optimizer" == "y" ]]; then
        wget "https://raw.githubusercontent.com/hawshemi/Linux-Optimizer/main/linux-optimizer.sh" -O linux-optimizer.sh
        chmod +x linux-optimizer.sh
        bash linux-optimizer.sh
    fi
}

# Function to configure firewall
configure_firewall() {
    ufw enable
    ufw allow OpenSSH
    ufw allow 22
    ufw allow 80
    ufw allow 443
    ufw allow 8443
}

# Function to obtain SSL
obtain_ssl() {
    read -p "$(print_yellow 'Do you want to obtain SSL certificates for the found domains? (y/n): ')" get_ssl
    if [[ "$get_ssl" == "y" ]]; then
        print_green "Disabling Apache before obtaining SSL..."
        systemctl stop apache2
        sudo bash -c "$(curl -sL https://github.com/erfjab/ESSL/raw/main/essl.sh)"
        print_green "Re-enabling Apache after obtaining SSL..."
        systemctl start apache2
    fi
}

# Main menu function
main_menu() {
    print_yellow "Main Menu:"
    print_yellow "1) Run all steps"
    print_yellow "2) Install panel"
    print_yellow "3) Download website"
    print_yellow "4) Run Linux optimizer"
    print_yellow "5) Configure firewall"
    print_yellow "6) Obtain SSL certificates"

    read -p "$(print_yellow 'Enter your choice: ')" choice

    case $choice in
        1) install_panel
           download_website
           run_optimizer
           configure_firewall
           obtain_ssl ;;
        2) install_panel ;;
        3) download_website ;;
        4) run_optimizer ;;
        5) configure_firewall ;;
        6) obtain_ssl ;;
        *) print_red "Invalid choice." ;;
    esac
}

# Start the script by showing the menu
main_menu

print_green "Script execution completed!"
