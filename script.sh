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

# Install necessary packages
print_yellow "Installing necessary packages..."
apt update
apt install -y apache2 wget nmap testssl.sh jq curl ufw

# Prompt user for website URL
read -p "$(print_yellow 'Please enter the website URL to download: ')" site_url

# Download website to web server directory
print_yellow "Downloading website content..."
wget --no-check-certificate -O /var/www/html/index.html "$site_url"

# Prompt user for website directory name
read -p "$(print_yellow 'Please enter the website directory name: ')" site_dir

# Change ownership and permissions of the website directory
print_yellow "Setting file permissions..."
chown -R www-data:www-data /var/www/html/"$site_dir"
chmod -R 755 /var/www/html/"$site_dir"

# Run Linux Optimizer script
print_yellow "Downloading and running the Linux optimizer script..."
wget "https://raw.githubusercontent.com/hawshemi/Linux-Optimizer/main/linux-optimizer.sh" -O linux-optimizer.sh
chmod +x linux-optimizer.sh
bash linux-optimizer.sh

# Enable UFW and open necessary ports
print_yellow "Enabling UFW and opening necessary ports..."
ufw enable
ufw allow 22/tcp
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

# Find ASN from IP
asn=$(whois "$public_ip" | grep "origin:" | awk '{print $2}')

if [[ -z "$asn" ]]; then
    print_red "Could not retrieve ASN from IP address."
    exit 1
fi

print_yellow "Public IP address of the server: $public_ip"
print_yellow "ASN: $asn"

# Find domains based on ASN
print_yellow "Finding domains associated with ASN $asn..."

# Fetch the domains from the ASN using bgp.he.net
domains=$(curl -s "https://bgp.he.net/AS${asn}" | grep -oP '(?<=<a href="/ips/)[^"]*' | sort -u)

if [[ -z "$domains" ]]; then
    print_red "No domains found for ASN $asn."
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

# Ask user if they want to obtain SSL certificates
read -p "$(print_yellow 'Do you want to obtain SSL certificates for the found domains? (y/n): ')" get_ssl

if [[ "$get_ssl" == "y" ]]; then
    # Run the ESSL script
    print_green "Obtaining SSL certificates..."
    sudo bash -c "$(curl -sL https://github.com/erfjab/ESSL/raw/main/essl.sh)"
else
    print_yellow "Skipping SSL certificate retrieval."
fi

print_green "Script execution completed!"
