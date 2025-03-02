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

# Prompt the user to install a panel
read -p "$(print_yellow 'Do you want to install a panel? (y/n): ')" install_panel
if [[ "$install_panel" == "y" ]]; then
    # Prompt user to select a panel
    print_yellow "Please select a panel to install:"
    print_yellow "1) Sanaei X-UI"
    print_yellow "2) Alireza X-UI"
    print_yellow "3) Marzban"
    print_yellow "4) S-UI"
    print_yellow "5) WireGuard"
    print_yellow "6) OpenVPN"

    read -p "$(print_yellow 'Enter the number of your choice: ')" panel_choice

    case $panel_choice in
        1)
            print_green "Installing Sanaei X-UI..."
            bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            ;;
        2)
            print_green "Installing Alireza X-UI..."
            bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
            ;;
        3)
            print_green "Installing Marzban..."
            sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)@install"

            print_green "Running 'marzban cli admin create --sudo' command..."
            marzban cli admin create --sudo

            # Open port 8000 for Marzban
            print_green "Opening port 8000 for Marzban..."
            apt install -y ufw
            ufw allow 8000

            # Prompt the user to run the IP2Limit script
            read -p "$(print_yellow 'Do you want to run the IP2Limit script? (y/n): ')" run_ip2limit
            if [[ "$run_ip2limit" == "y" ]]; then
                print_green "Running IP2Limit script..."
                bash <(curl -sSL https://houshmand-2005.github.io/v2iplimit.sh)
            else
                print_yellow "Skipping IP2Limit script."
            fi
            ;;
        4)
            print_green "Installing S-UI..."
            bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)
            ;;
        5)
            print_green "Installing WireGuard..."
            wget https://git.io/wireguard -O wireguard-install.sh && bash wireguard-install.sh
            ;;
        6)
            print_green "Installing OpenVPN..."
            wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh
            ;;
        *)
            print_red "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    print_yellow "Skipping panel installation."
fi
# Install Apache and enable TLS 1.3
print_green "Installing and configuring Apache..."
apt update && apt install -y apache2

# Enable required Apache modules
print_green "Enabling necessary Apache modules..."
a2enmod ssl headers http2
systemctl restart apache2

# Enable TLS 1.3 in Apache
print_green "Configuring Apache for TLS 1.3..."
echo "<IfModule mod_ssl.c>
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLHonorCipherOrder on
    SSLCipherSuite TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
</IfModule>" > /etc/apache2/conf-available/tls-params.conf

a2enconf tls-params
systemctl restart apache2

# Display installed SSL path
print_green "Apache SSL Directory: /etc/ssl/certs/"
# Install necessary packages
apt update
apt install -y wget nmap testssl.sh jq curl ufw

# Prompt user for website URL
read -p "$(print_yellow 'Please enter the website URL to download: ')" site_url

# Download website to web server directory
wget --no-check-certificate -O /var/www/html/index.html "$site_url"

# Prompt user for website directory name
read -p "$(print_yellow 'Please enter the website directory name: ')" site_dir

# Change ownership and permissions of the website directory
chown -R www-data:www-data /var/www/html/"$site_dir"
chmod -R 755 /var/www/html/"$site_dir"

# Prompt user if they want to run the Linux Optimizer script
read -p "$(print_yellow 'Do you want to run the Linux Optimizer script? (y/n): ')" run_optimizer
if [[ "$run_optimizer" == "y" ]]; then
    # Run Linux Optimizer script
    wget "https://raw.githubusercontent.com/hawshemi/Linux-Optimizer/main/linux-optimizer.sh" -O linux-optimizer.sh
    chmod +x linux-optimizer.sh
    bash linux-optimizer.sh
else
    print_yellow "Skipping Linux Optimizer script."
fi

# Enable UFW and open necessary ports
ufw enable
ufw allow OpenSSH
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 8443

print_green "All steps completed successfully!"

# Get the public IP of the server
public_ip=$(curl -s http://ipinfo.io/ip)

if [[ -z "$public_ip" ]]; then
    print_red "Could not retrieve the public IP address."
    exit 1
fi

print_yellow "Public IP address of the server: $public_ip"

# Prompt user if they want to find SNI domains using TLS 1.3
read -p "$(print_yellow 'Do you want to find SNI domains using TLS 1.3? (y/n): ')" find_sni

if [[ "$find_sni" == "y" ]]; then
    print_green "Finding SNI domains using TLS 1.3..."

    # Use crt.sh to get domains associated with the server's IP
    print_yellow "Retrieving domains associated with the server's IP..."

    # Query crt.sh for domains associated with the public IP
    domains=$(curl -s "https://crt.sh/?q=${public_ip}&output=json" | jq -r '.[].name_value' | sort -u)

    if [[ -z "$domains" ]]; then
        print_red "No domains found for the server's IP."
    else
        print_yellow "Found domains:"
        echo "$domains"

        # Check for TLS 1.3 support using testssl.sh
        print_yellow "Checking for TLS 1.3 support on found domains..."

        tls13_domains=()
        for domain in $domains; do
            tls_result=$(testssl.sh --quiet --jsonfile /dev/stdout --protocols "$domain" | grep '"TLS 1.3"' | wc -l)
            if [[ "$tls_result" -gt 0 ]]; then
                tls13_domains+=("$domain")
            fi
        done

        # Show the results
        if [ ${#tls13_domains[@]} -eq 0 ]; then
            print_red "No domains with TLS 1.3 support found."
        else
            print_green "Found the following SNI domains using TLS 1.3:"
            for i in "${!tls13_domains[@]}"; do
                echo "$((i + 1)). ${tls13_domains[$i]}"
                if [ "$i" -ge 4 ]; then
                    break
                fi
            done
        fi
    fi
fi

# Prompt user if they want to obtain SSL certificates
read -p "$(print_yellow 'Do you want to obtain SSL certificates for the found domains? (y/n): ')" get_ssl

if [[ "$get_ssl" == "y" ]]; then
    # Run the ESSL script
    print_green "Obtaining SSL certificates..."
    sudo bash -c "$(curl -sL https://github.com/erfjab/ESSL/raw/main/essl.sh)"
else
    print_yellow "Skipping SSL certificate retrieval."
fi

print_green "Script execution completed!"
