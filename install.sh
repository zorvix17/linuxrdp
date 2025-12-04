#!/bin/bash
# ============================================================================
# LINUX RDP PRO v10.0
# Ultimate Linux RDP Hosting Platform
# Advanced • Professional • Feature-Rich
# ============================================================================

set -euo pipefail
trap 'cleanup_on_exit' EXIT

# ============================================================================
# CONFIGURATION
# ============================================================================
readonly VERSION="10.0.0"
readonly SCRIPT_NAME="Linux RDP Pro"
readonly BASE_DIR="${BASE_DIR:-$HOME/linux-rdp-pro}"
readonly LOG_DIR="$BASE_DIR/logs"
readonly CONFIG_DIR="$BASE_DIR/config"
readonly BACKUP_DIR="$BASE_DIR/backups"
readonly THEME_DIR="$BASE_DIR/themes"
readonly APPS_DIR="$BASE_DIR/apps"
readonly WALLPAPER_DIR="$BASE_DIR/wallpapers"

# Directories
mkdir -p "$BASE_DIR" "$LOG_DIR" "$CONFIG_DIR" "$BACKUP_DIR" \
         "$THEME_DIR" "$APPS_DIR" "$WALLPAPER_DIR"

# ============================================================================
# ADVANCED COLOR SYSTEM
# ============================================================================
readonly COLOR_RESET="\033[0m"
readonly COLOR_BLACK="\033[30m"
readonly COLOR_RED="\033[31m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_BLUE="\033[34m"
readonly COLOR_MAGENTA="\033[35m"
readonly COLOR_CYAN="\033[36m"
readonly COLOR_WHITE="\033[37m"
readonly COLOR_ORANGE="\033[38;5;208m"
readonly COLOR_PURPLE="\033[38;5;93m"
readonly COLOR_NEON="\033[38;5;46m"
readonly COLOR_GOLD="\033[38;5;220m"

# Icons
readonly IC_SUCCESS="✅"
readonly IC_ERROR="❌"
readonly IC_WARN="⚠️"
readonly IC_INFO="ℹ️"
readonly IC_LOAD="🔄"
readonly IC_DONE="✨"
readonly IC_RDP="🖥️"
readonly IC_CHROME="🌐"
readonly IC_APPS="📦"
readonly IC_SECURITY="🔐"
readonly IC_NETWORK="🌐"
readonly IC_SETTINGS="⚙️"

# ============================================================================
# LOGGING SYSTEM
# ============================================================================
LOG_FILE="$LOG_DIR/linux-rdp-$(date +%Y%m%d).log"

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "SUCCESS") echo -e "${COLOR_GREEN}$IC_SUCCESS $message${COLOR_RESET}" ;;
        "ERROR") echo -e "${COLOR_RED}$IC_ERROR $message${COLOR_RESET}" ;;
        "WARN") echo -e "${COLOR_YELLOW}$IC_WARN $message${COLOR_RESET}" ;;
        "INFO") echo -e "${COLOR_CYAN}$IC_INFO $message${COLOR_RESET}" ;;
        "DEBUG") echo -e "${COLOR_BLUE}$message${COLOR_RESET}" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# ============================================================================
# BANNER WITH CUSTOM ART
# ============================================================================
show_banner() {
    clear
    echo -e "${COLOR_NEON}"
    cat << "EOF"
   ______                 _         ______              
  / ____/___ __   _______(_)  __   / ____/___  ________ 
 / /   / __ `/ | / / ___/ / |/_/  / /   / __ \/ ___/ _ \
/ /___/ /_/ /| |/ / /  / />  <   / /___/ /_/ / /  /  __/
\____/\__,_/ |___/_/  /_/_/|_|   \____/\____/_/   \___/
EOF
    echo -e "${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_CYAN}                    Linux RDP Professional v${VERSION}                  ${COLOR_RESET}"
    echo -e "${COLOR_CYAN}               Ultimate Remote Desktop Solution                       ${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo ""
}

# ============================================================================
# DETECT LINUX DISTRIBUTION
# ============================================================================
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "centos"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# ============================================================================
# PACKAGE MANAGER FUNCTIONS
# ============================================================================
install_package() {
    local pkg="$1"
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            sudo apt install -y "$pkg" 2>/dev/null || log "WARN" "Failed to install $pkg"
            ;;
        centos|rhel|fedora)
            sudo yum install -y "$pkg" 2>/dev/null || sudo dnf install -y "$pkg" 2>/dev/null
            ;;
        arch)
            sudo pacman -S --noconfirm "$pkg" 2>/dev/null
            ;;
        *)
            log "ERROR" "Unsupported distribution: $distro"
            return 1
            ;;
    esac
}

update_system() {
    local distro=$(detect_distro)
    
    log "INFO" "Updating system packages..."
    case "$distro" in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            ;;
        centos|rhel)
            sudo yum update -y
            ;;
        fedora)
            sudo dnf update -y
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            ;;
    esac
}

# ============================================================================
# MAIN INSTALLATION FUNCTION
# ============================================================================
install_linux_rdp() {
    show_banner
    
    log "INFO" "Starting Linux RDP Professional Installation..."
    echo ""
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log "WARN" "Running as root. Creating non-root user..."
        read -p "Enter username for RDP access: " username
        if id "$username" &>/dev/null; then
            log "INFO" "User $username already exists"
        else
            sudo useradd -m -s /bin/bash "$username"
            sudo passwd "$username"
            log "SUCCESS" "User $username created"
        fi
        USERNAME="$username"
    else
        USERNAME=$(whoami)
    fi
    
    # Update system
    update_system
    
    # Step 1: Install Desktop Environment
    log "INFO" "Step 1: Installing Desktop Environment..."
    install_desktop_environment
    
    # Step 2: Install xRDP
    log "INFO" "Step 2: Installing xRDP..."
    install_xrdp
    
    # Step 3: Install Google Chrome
    log "INFO" "Step 3: Installing Google Chrome..."
    install_google_chrome
    
    # Step 4: Install Recommended Applications
    log "INFO" "Step 4: Installing Recommended Applications..."
    install_recommended_apps
    
    # Step 5: Configure System
    log "INFO" "Step 5: Configuring System..."
    configure_system
    
    # Step 6: Security Setup
    log "INFO" "Step 6: Setting up Security..."
    setup_security
    
    # Step 7: Performance Optimization
    log "INFO" "Step 7: Optimizing Performance..."
    optimize_performance
    
    # Display connection information
    show_connection_info
    
    log "SUCCESS" "Installation complete!"
}

# ============================================================================
# DESKTOP ENVIRONMENT INSTALLATION
# ============================================================================
install_desktop_environment() {
    local distro=$(detect_distro)
    
    log "INFO" "Available Desktop Environments:"
    echo "  1) XFCE (Lightweight, Recommended)"
    echo "  2) GNOME (Modern, Feature-rich)"
    echo "  3) KDE Plasma (Beautiful, Customizable)"
    echo "  4) MATE (Traditional, Stable)"
    echo "  5) Cinnamon (User-friendly)"
    echo "  6) LXQt (Ultra Lightweight)"
    
    read -p "Select desktop environment (1-6): " de_choice
    
    case $de_choice in
        1) de_packages="xfce4 xfce4-goodies" ;;
        2) de_packages="gnome gnome-extra" ;;
        3) de_packages="kde-plasma-desktop" ;;
        4) de_packages="mate-desktop-environment" ;;
        5) de_packages="cinnamon-desktop-environment" ;;
        6) de_packages="lxqt" ;;
        *) de_packages="xfce4 xfce4-goodies" ;;
    esac
    
    log "INFO" "Installing $de_packages..."
    install_package "$de_packages"
    
    # Set default session
    case $de_choice in
        1) echo "xfce4-session" > ~/.xsession ;;
        2) echo "gnome-session" > ~/.xsession ;;
        3) echo "startplasma-x11" > ~/.xsession ;;
        4) echo "mate-session" > ~/.xsession ;;
        5) echo "cinnamon-session" > ~/.xsession ;;
        6) echo "startlxqt" > ~/.xsession ;;
    esac
    
    chown $USERNAME:$USERNAME ~/.xsession
    log "SUCCESS" "Desktop environment installed"
}

# ============================================================================
# XRDP INSTALLATION
# ============================================================================
install_xrdp() {
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            sudo apt install -y xrdp xorgxrdp xrdp-pulseaudio-installer
            ;;
        centos|rhel)
            sudo yum install -y epel-release
            sudo yum install -y xrdp tigervnc-server
            ;;
        fedora)
            sudo dnf install -y xrdp tigervnc-server
            ;;
        arch)
            sudo pacman -S --noconfirm xrdp xorgxrdp
            ;;
    esac
    
    # Configure xRDP
    sudo systemctl enable xrdp
    sudo systemctl enable xrdp-sesman
    
    # Configure xRDP to use different port (3390)
    sudo sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini
    
    # Optimize xRDP settings
    sudo cat >> /etc/xrdp/xrdp.ini << 'EOF'
max_bpp=24
use_compression=yes
compression_level=2
tcp_nodelay=true
tcp_keepalive=true
EOF
    
    log "SUCCESS" "xRDP installed and configured"
}

# ============================================================================
# GOOGLE CHROME INSTALLATION
# ============================================================================
install_google_chrome() {
    local distro=$(detect_distro)
    
    log "INFO" "Installing Google Chrome..."
    
    case "$distro" in
        ubuntu|debian)
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
            echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
            sudo apt update
            sudo apt install -y google-chrome-stable
            ;;
        centos|rhel|fedora)
            sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
            ;;
        arch)
            # Chrome is not officially available on Arch, install Chromium instead
            sudo pacman -S --noconfirm chromium
            ;;
    esac
    
    # Create Chrome desktop shortcut
    cat > ~/Desktop/google-chrome.desktop << 'EOF'
[Desktop Entry]
Name=Google Chrome
Comment=Access the Internet
Exec=google-chrome-stable --no-sandbox
Icon=google-chrome
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF
    
    chmod +x ~/Desktop/google-chrome.desktop
    log "SUCCESS" "Google Chrome installed"
}

# ============================================================================
# RECOMMENDED APPLICATIONS
# ============================================================================
install_recommended_apps() {
    log "INFO" "Installing recommended applications..."
    
    # Categories of applications
    local office_apps="libreoffice libreoffice-gtk3"
    local media_apps="vlc gimp audacity"
    local dev_apps="code git python3 nodejs npm"
    local utils_apps="filezilla remmina thunderbird flameshot"
    local terminal_apps="tilix terminator"
    
    # Install by category
    log "INFO" "Installing Office Suite..."
    install_package "$office_apps"
    
    log "INFO" "Installing Media Applications..."
    install_package "$media_apps"
    
    log "INFO" "Installing Development Tools..."
    install_package "$dev_apps"
    
    log "INFO" "Installing Utilities..."
    install_package "$utils_apps"
    
    log "INFO" "Installing Terminal Emulators..."
    install_package "$terminal_apps"
    
    # Install VS Code if not installed
    if ! command -v code &>/dev/null; then
        log "INFO" "Installing Visual Studio Code..."
        case $(detect_distro) in
            ubuntu|debian)
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
                echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
                sudo apt update
                sudo apt install -y code
                ;;
            fedora|centos|rhel)
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                echo '[code]' | sudo tee /etc/yum.repos.d/vscode.repo
                echo 'name=Visual Studio Code' | sudo tee -a /etc/yum.repos.d/vscode.repo
                echo 'baseurl=https://packages.microsoft.com/yumrepos/vscode' | sudo tee -a /etc/yum.repos.d/vscode.repo
                echo 'enabled=1' | sudo tee -a /etc/yum.repos.d/vscode.repo
                echo 'gpgcheck=1' | sudo tee -a /etc/yum.repos.d/vscode.repo
                echo 'gpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee -a /etc/yum.repos.d/vscode.repo
                sudo dnf install -y code
                ;;
        esac
    fi
    
    # Create desktop shortcuts
    create_desktop_shortcuts
    
    log "SUCCESS" "Recommended applications installed"
}

create_desktop_shortcuts() {
    # LibreOffice
    cat > ~/Desktop/libreoffice.desktop << 'EOF'
[Desktop Entry]
Name=LibreOffice
Comment=Office Suite
Exec=libreoffice
Icon=libreoffice-main
Terminal=false
Type=Application
Categories=Office;
EOF
    
    # VLC Media Player
    cat > ~/Desktop/vlc.desktop << 'EOF'
[Desktop Entry]
Name=VLC Media Player
Comment=Play media files
Exec=vlc
Icon=vlc
Terminal=false
Type=Application
Categories=AudioVideo;Player;
EOF
    
    # Visual Studio Code
    cat > ~/Desktop/vscode.desktop << 'EOF'
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing
Exec=code
Icon=code
Terminal=false
Type=Application
Categories=Development;IDE;
EOF
    
    # FileZilla
    cat > ~/Desktop/filezilla.desktop << 'EOF'
[Desktop Entry]
Name=FileZilla
Comment=FTP Client
Exec=filezilla
Icon=filezilla
Terminal=false
Type=Application
Categories=Network;FileTransfer;
EOF
    
    chmod +x ~/Desktop/*.desktop
}

# ============================================================================
# SYSTEM CONFIGURATION
# ============================================================================
configure_system() {
    log "INFO" "Configuring system settings..."
    
    # Configure display manager
    configure_display_manager
    
    # Configure audio
    configure_audio
    
    # Configure printing
    configure_printing
    
    # Configure network
    configure_network
    
    # Configure firewall
    configure_firewall
    
    log "SUCCESS" "System configured"
}

configure_display_manager() {
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            sudo DEBIAN_FRONTEND=noninteractive apt install -y lightdm
            sudo systemctl enable lightdm
            ;;
        centos|rhel|fedora)
            sudo systemctl enable gdm
            ;;
    esac
}

configure_audio() {
    install_package "pulseaudio pulseaudio-utils pavucontrol"
    sudo systemctl --user enable pulseaudio
}

configure_printing() {
    install_package "cups cups-client"
    sudo systemctl enable cups
}

configure_network() {
    install_package "network-manager network-manager-gnome"
    sudo systemctl enable NetworkManager
}

configure_firewall() {
    if command -v ufw &>/dev/null; then
        sudo ufw allow 3390/tcp
        sudo ufw reload
    elif command -v firewall-cmd &>/dev/null; then
        sudo firewall-cmd --permanent --add-port=3390/tcp
        sudo firewall-cmd --reload
    fi
}

# ============================================================================
# SECURITY SETUP
# ============================================================================
setup_security() {
    log "INFO" "Setting up security features..."
    
    # Change RDP port for security
    read -p "Change RDP port from 3390? (y/N): " change_port
    if [[ "$change_port" =~ ^[Yy]$ ]]; then
        read -p "Enter new RDP port (1024-65535): " new_port
        sudo sed -i "s/port=3390/port=$new_port/g" /etc/xrdp/xrdp.ini
        RDP_PORT="$new_port"
    else
        RDP_PORT="3390"
    fi
    
    # Setup SSL for xRDP
    setup_ssl
    
    # Install and configure fail2ban
    setup_fail2ban
    
    # Configure SSH (if installed)
    setup_ssh
    
    log "SUCCESS" "Security features configured"
}

setup_ssl() {
    log "INFO" "Setting up SSL encryption..."
    
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/xrdp.key \
        -out /etc/ssl/certs/xrdp.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$(hostname)"
    
    sudo chmod 600 /etc/ssl/private/xrdp.key
    
    # Configure xRDP to use SSL
    sudo cat >> /etc/xrdp/xrdp.ini << 'EOF'
tls_ciphers=HIGH
certificate=/etc/ssl/certs/xrdp.crt
key_file=/etc/ssl/private/xrdp.key
EOF
}

setup_fail2ban() {
    if install_package "fail2ban"; then
        sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
        
        # Add xRDP jail
        sudo cat > /etc/fail2ban/jail.d/xrdp.local << EOF
[xrdp]
enabled = true
port = $RDP_PORT
filter = xrdp
logpath = /var/log/xrdp-sesman.log
maxretry = 3
bantime = 3600
EOF
        
        sudo systemctl enable fail2ban
        sudo systemctl start fail2ban
    fi
}

setup_ssh() {
    if command -v sshd &>/dev/null; then
        log "INFO" "Hardening SSH configuration..."
        
        # Backup original config
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        
        # Apply security settings
        sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
        sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
        sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
        
        sudo systemctl restart sshd
    fi
}

# ============================================================================
# PERFORMANCE OPTIMIZATION
# ============================================================================
optimize_performance() {
    log "INFO" "Optimizing system performance..."
    
    # Configure swap
    configure_swap
    
    # Configure sysctl
    configure_sysctl
    
    # Configure services
    optimize_services
    
    # Install performance tools
    install_performance_tools
    
    log "SUCCESS" "Performance optimization complete"
}

configure_swap() {
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    local swap_size=$((total_ram * 2))
    
    if [[ ! -f /swapfile ]]; then
        log "INFO" "Creating swap file..."
        sudo fallocate -l ${swap_size}M /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
}

configure_sysctl() {
    sudo cat >> /etc/sysctl.conf << 'EOF'
# Performance tuning
vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 134217728
net.ipv4.tcp_wmem=4096 65536 134217728
net.ipv4.tcp_congestion_control=bbr
EOF
    
    sudo sysctl -p
}

optimize_services() {
    # Disable unnecessary services
    local services=("bluetooth" "cups-browsed" "ModemManager" "avahi-daemon")
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service"; then
            sudo systemctl disable "$service" 2>/dev/null
        fi
    done
}

install_performance_tools() {
    local tools="htop iotop iftop nmon sysstat"
    install_package "$tools"
}

# ============================================================================
# CONNECTION INFORMATION
# ============================================================================
show_connection_info() {
    local ip_address=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    local username=$USERNAME
    
    clear
    show_banner
    
    echo -e "${COLOR_GREEN}══════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_GREEN}                    INSTALLATION COMPLETE!                           ${COLOR_RESET}"
    echo -e "${COLOR_GREEN}══════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo ""
    
    echo -e "${COLOR_CYAN}📡 REMOTE DESKTOP CONNECTION INFORMATION:${COLOR_RESET}"
    echo -e "  ${COLOR_YELLOW}IP Address:${COLOR_RESET}   $ip_address"
    echo -e "  ${COLOR_YELLOW}RDP Port:${COLOR_RESET}     $RDP_PORT"
    echo -e "  ${COLOR_YELLOW}Username:${COLOR_RESET}     $username"
    echo -e "  ${COLOR_YELLOW}Password:${COLOR_RESET}     Your system password"
    echo ""
    
    echo -e "${COLOR_CYAN}🖥️  CONNECTION METHODS:${COLOR_RESET}"
    echo -e "  ${COLOR_YELLOW}Windows:${COLOR_RESET}      Remote Desktop → mstsc /v:$ip_address:$RDP_PORT"
    echo -e "  ${COLOR_YELLOW}Linux:${COLOR_RESET}        xfreerdp /v:$ip_address:$RDP_PORT /u:$username"
    echo -e "  ${COLOR_YELLOW}Mac:${COLOR_RESET}          Microsoft Remote Desktop → $ip_address:$RDP_PORT"
    echo -e "  ${COLOR_YELLOW}Android:${COLOR_RESET}      RD Client → $ip_address:$RDP_PORT"
    echo ""
    
    echo -e "${COLOR_CYAN}📦 INSTALLED APPLICATIONS:${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}•${COLOR_RESET} Google Chrome"
    echo -e "  ${COLOR_GREEN}•${COLOR_RESET} LibreOffice Suite"
    echo -e "  ${COLOR_GREEN}•${COLOR_RESET} VLC Media Player"
    echo -e "  ${COLOR_GREEN}•${COLOR_RESET} Visual Studio Code"
    echo -e "  ${COLOR_GREEN}•${COLOR_RESET} FileZilla FTP Client"
    echo -e "  ${COLOR_GREEN}•${COLOR_RESET} GIMP Image Editor"
    echo -e "  ${COLOR_GREEN}•${COLOR_RESET} Audacity Audio Editor"
    echo -e "  ${COLOR_GREEN}•${COLOR_RESET} Terminal Emulators"
    echo ""
    
    echo -e "${COLOR_CYAN}🔧 MANAGEMENT COMMANDS:${COLOR_RESET}"
    echo -e "  ${COLOR_YELLOW}Start RDP:${COLOR_RESET}    sudo systemctl start xrdp"
    echo -e "  ${COLOR_YELLOW}Stop RDP:${COLOR_RESET}     sudo systemctl stop xrdp"
    echo -e "  ${COLOR_YELLOW}Status:${COLOR_RESET}       sudo systemctl status xrdp"
    echo -e "  ${COLOR_YELLOW}Restart:${COLOR_RESET}      sudo systemctl restart xrdp"
    echo ""
    
    echo -e "${COLOR_CYAN}⚠️  SECURITY NOTES:${COLOR_RESET}"
    echo "  1. Change your password regularly"
    echo "  2. Keep system updated"
    echo "  3. Use firewall rules"
    echo "  4. Monitor login attempts"
    echo "  5. Consider using VPN"
    echo ""
    
    echo -e "${COLOR_GREEN}══════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_GREEN}             Your Linux RDP is ready for use!                        ${COLOR_RESET}"
    echo -e "${COLOR_GREEN}══════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    
    # Start RDP service
    sudo systemctl start xrdp
    echo ""
    echo -e "${COLOR_GREEN}✅ RDP service started on port $RDP_PORT${COLOR_RESET}"
}

# ============================================================================
# CLEANUP FUNCTION
# ============================================================================
cleanup_on_exit() {
    echo ""
    log "INFO" "Cleaning up temporary files..."
    rm -rf /tmp/linux-rdp-*
    log "SUCCESS" "Cleanup complete"
}

# ============================================================================
# MAIN MENU
# ============================================================================
show_menu() {
    while true; do
        show_banner
        
        echo -e "${COLOR_CYAN}Main Menu:${COLOR_RESET}"
        echo -e "${COLOR_BLUE}══════════════════════════════════════════════════════════════════════${COLOR_RESET}"
        echo ""
        echo -e "  ${COLOR_GREEN}1)${COLOR_RESET} ${IC_RDP} Install Linux RDP Professional"
        echo -e "  ${COLOR_GREEN}2)${COLOR_RESET} ${IC_CHROME} Install Additional Applications"
        echo -e "  ${COLOR_GREEN}3)${COLOR_RESET} ${IC_SECURITY} Security Configuration"
        echo -e "  ${COLOR_GREEN}4)${COLOR_RESET} ${IC_SETTINGS} System Settings"
        echo -e "  ${COLOR_GREEN}5)${COLOR_RESET} ${IC_NETWORK} Network Configuration"
        echo -e "  ${COLOR_GREEN}6)${COLOR_RESET} 📊 Performance Monitor"
        echo -e "  ${COLOR_GREEN}7)${COLOR_RESET} 🛠️  Troubleshooting"
        echo -e "  ${COLOR_GREEN}8)${COLOR_RESET} 📋 System Information"
        echo -e "  ${COLOR_RED}0)${COLOR_RESET} 🚪 Exit"
        echo ""
        echo -e "${COLOR_BLUE}══════════════════════════════════════════════════════════════════════${COLOR_RESET}"
        
        read -p "$(echo -e "${COLOR_CYAN}Select option: ${COLOR_RESET}")" choice
        
        case $choice in
            1) install_linux_rdp ;;
            2) install_additional_apps ;;
            3) security_menu ;;
            4) system_settings_menu ;;
            5) network_config_menu ;;
            6) performance_monitor ;;
            7) troubleshooting_menu ;;
            8) system_info ;;
            0)
                echo ""
                log "SUCCESS" "Thank you for using Linux RDP Professional!"
                exit 0
                ;;
            *)
                log "ERROR" "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "$(echo -e "${COLOR_CYAN}Press Enter to continue...${COLOR_RESET}")"
    done
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================
main() {
    # Check if running with sudo
    if [[ $EUID -eq 0 ]]; then
        log "WARN" "Please run this script as a regular user (not root)"
        exit 1
    fi
    
    # Check internet connection
    if ! ping -c 1 google.com &>/dev/null; then
        log "ERROR" "No internet connection. Please check your network."
        exit 1
    fi
    
    # Start main menu
    show_menu
}

# ============================================================================
# RUN SCRIPT
# ============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
