#!/bin/bash

# ============================================
# CavrixCore RDP Installer
# Advanced RDP Setup Script
# Powered By: root@cavrix.core
# ============================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ASCII Art
clear
echo -e "${CYAN}"
cat << "EOF"
 ██████╗ █████╗ ██╗   ██╗██████╗ ██╗██╗  ██╗    ██████╗ ██████╗ ██████╗ 
██╔════╝██╔══██╗██║   ██║██╔══██╗██║╚██╗██╔╝    ██╔══██╗██╔══██╗██╔══██╗
██║     ███████║██║   ██║██████╔╝██║ ╚███╔╝     ██████╔╝██║  ██║██████╔╝
██║     ██╔══██║╚██╗ ██╔╝██╔══██╗██║ ██╔██╗     ██╔══██╗██║  ██║██╔═══╝ 
╚██████╗██║  ██║ ╚████╔╝ ██║  ██║██║██╔╝ ██╗    ██║  ██║██████╔╝██║     
 ╚═════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚═════╝ ╚═╝     
EOF
echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                  CavrixCore RDP Installer                     ║"
echo "║                Powered By: root@cavrix.core                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Configuration
DEBIAN_FRONTEND=noninteractive
LOG_FILE="/var/log/cavrixcore-rdp-install.log"
BACKUP_DIR="/root/cavrixcore-backup-$(date +%Y%m%d_%H%M%S)"
INSTALL_DIR="/opt/cavrixcore"

# Function: Log messages
log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function: Print status
print_status() {
    case $1 in
        "info") echo -e "${BLUE}[*]${NC} $2" ;;
        "success") echo -e "${GREEN}[✓]${NC} $2" ;;
        "warning") echo -e "${YELLOW}[!]${NC} $2" ;;
        "error") echo -e "${RED}[✗]${NC} $2" ;;
    esac
    log_message "$2"
}

# Function: Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_status "error" "This script must be run as root"
        exit 1
    fi
    print_status "success" "Running as root user"
}

# Function: Check internet (improved)
check_internet() {
    print_status "info" "Checking internet connectivity..."
    
    # Try multiple methods
    if wget -q --spider http://google.com 2>/dev/null || \
       curl -s --connect-timeout 3 http://google.com >/dev/null || \
       ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        print_status "success" "Internet connection OK"
        return 0
    else
        print_status "warning" "Internet check failed, but continuing anyway..."
        return 0
    fi
}

# Function: Detect OS
detect_os() {
    print_status "info" "Detecting operating system..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        OS_ID=$ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
        OS_ID=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    else
        OS=$(uname -s)
        VER=$(uname -r)
        OS_ID="unknown"
    fi
    
    print_status "success" "Detected: $OS $VER ($OS_ID)"
    
    if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
        print_status "warning" "This script is optimized for Ubuntu/Debian systems"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function: System update
system_update() {
    print_status "info" "Updating system packages..."
    
    if apt-get update -y >> "$LOG_FILE" 2>&1; then
        print_status "success" "Package lists updated"
    else
        print_status "warning" "Failed to update package lists, continuing..."
    fi
}

# Function: Install Desktop Environment
install_desktop() {
    print_status "info" "Select Desktop Environment:"
    echo "  1) XFCE (Lightweight - Recommended)"
    echo "  2) GNOME (Full-featured)"
    echo "  3) KDE Plasma (Modern)"
    echo "  4) MATE (Traditional)"
    echo "  5) Cinnamon (User-friendly)"
    echo "  6) Skip (Already have desktop)"
    read -p "Enter choice [1-6]: " de_choice
    
    case $de_choice in
        1)
            DESKTOP="xfce4 xfce4-goodies"
            DESKTOP_NAME="XFCE"
            ;;
        2)
            DESKTOP="ubuntu-gnome-desktop"
            DESKTOP_NAME="GNOME"
            ;;
        3)
            DESKTOP="kde-plasma-desktop"
            DESKTOP_NAME="KDE Plasma"
            ;;
        4)
            DESKTOP="ubuntu-mate-desktop"
            DESKTOP_NAME="MATE"
            ;;
        5)
            DESKTOP="cinnamon-desktop-environment"
            DESKTOP_NAME="Cinnamon"
            ;;
        6)
            print_status "info" "Skipping desktop installation"
            return
            ;;
        *)
            DESKTOP="xfce4 xfce4-goodies"
            DESKTOP_NAME="XFCE"
            print_status "info" "Defaulting to XFCE"
            ;;
    esac
    
    print_status "info" "Installing $DESKTOP_NAME..."
    
    # Install display manager
    apt-get install -y lightdm lightdm-gtk-greeter >> "$LOG_FILE" 2>&1
    
    # Install selected desktop
    if apt-get install -y $DESKTOP >> "$LOG_FILE" 2>&1; then
        print_status "success" "$DESKTOP_NAME installed successfully"
        
        # Set lightdm as default
        systemctl set-default graphical.target >> "$LOG_FILE" 2>&1
        systemctl enable lightdm >> "$LOG_FILE" 2>&1
    else
        print_status "warning" "Failed to install $DESKTOP_NAME, trying minimal xfce..."
        apt-get install -y xfce4 xfce4-terminal >> "$LOG_FILE" 2>&1
    fi
}

# Function: Install xRDP
install_xrdp() {
    print_status "info" "Installing xRDP..."
    
    # Install xRDP and dependencies
    if apt-get install -y xrdp xorgxrdp >> "$LOG_FILE" 2>&1; then
        print_status "success" "xRDP installed successfully"
    else
        print_status "error" "Failed to install xRDP"
        exit 1
    fi
    
    # Configure xRDP
    print_status "info" "Configuring xRDP..."
    
    # Set XFCE as default session
    echo "xfce4-session" > /home/*/.xsession 2>/dev/null
    echo "xfce4-session" > /root/.xsession 2>/dev/null
    
    # Configure xrdp.ini
    cat > /etc/xrdp/xrdp.ini << 'EOF'
[globals]
bitmap_cache=yes
bitmap_compression=yes
port=3389
crypt_level=high
channel_code=1
max_bpp=32
use_compression=yes

[xrdp1]
name=sesman-Xvnc
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=-1
EOF
    
    print_status "success" "xRDP configured"
}

# Function: Configure Firewall
configure_firewall() {
    print_status "info" "Configuring firewall..."
    
    # Check if ufw is available
    if command -v ufw &> /dev/null; then
        ufw allow 3389/tcp >> "$LOG_FILE" 2>&1
        ufw allow ssh >> "$LOG_FILE" 2>&1
        echo "y" | ufw enable >> "$LOG_FILE" 2>&1
        print_status "success" "Firewall configured (UFW)"
    elif command -v iptables &> /dev/null; then
        iptables -A INPUT -p tcp --dport 3389 -j ACCEPT
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT
        print_status "success" "Firewall configured (iptables)"
    else
        print_status "warning" "No firewall manager found, skipping"
    fi
}

# Function: Create User
create_user() {
    print_status "info" "Create new RDP user? (y/N): "
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter username: " username
        if id "$username" &>/dev/null; then
            print_status "warning" "User $username already exists"
        else
            adduser "$username"
            usermod -aG sudo "$username" 2>/dev/null
            print_status "success" "User $username created"
            
            # Set X session
            echo "xfce4-session" > /home/$username/.xsession
            chown $username:$username /home/$username/.xsession
        fi
    fi
}

# Function: Display Connection Info
display_info() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
 ██████╗ █████╗ ██╗   ██╗██████╗ ██╗██╗  ██╗    ██████╗ ██████╗ ██████╗ 
██╔════╝██╔══██╗██║   ██║██╔══██╗██║╚██╗██╔╝    ██╔══██╗██╔══██╗██╔══██╗
██║     ███████║██║   ██║██████╔╝██║ ╚███╔╝     ██████╔╝██║  ██║██████╔╝
██║     ██╔══██║╚██╗ ██╔╝██╔══██╗██║ ██╔██╗     ██╔══██╗██║  ██║██╔═══╝ 
╚██████╗██║  ██║ ╚████╔╝ ██║  ██║██║██╔╝ ██╗    ██║  ██║██████╔╝██║     
 ╚═════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚═════╝ ╚═╝     
EOF
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║              CavrixCore RDP Installation Complete            ║"
    echo "║                Powered By: root@cavrix.core                  ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${GREEN}✅ Installation Completed Successfully!${NC}"
    echo ""
    echo "======================== CONNECTION INFO ========================"
    echo ""
    echo -e "${YELLOW}🔗 RDP Connection:${NC}"
    IP_ADDRESS=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")
    echo -e "   Host: $IP_ADDRESS or $(curl -s ifconfig.me 2>/dev/null || echo "Your Server IP")"
    echo -e "   Port: 3389"
    echo -e "   Username: Your system username"
    echo ""
    echo -e "${YELLOW}🖥️  Desktop Environment:${NC} $DESKTOP_NAME"
    echo ""
    echo -e "${YELLOW}🔧 Services Status:${NC}"
    systemctl is-active xrdp 2>/dev/null | awk '{print "   xRDP: " $0}'
    systemctl is-active lightdm 2>/dev/null | awk '{print "   LightDM: " $0}'
    echo ""
    echo "======================== QUICK COMMANDS ========================="
    echo ""
    echo "   Check RDP status: sudo systemctl status xrdp"
    echo "   Restart RDP: sudo systemctl restart xrdp"
    echo "   View logs: sudo tail -f /var/log/xrdp.log"
    echo ""
    echo "================================================================="
    echo ""
    echo -e "${BLUE}Thank you for using CavrixCore RDP Installer!${NC}"
    echo ""
}

# Main installation process
main() {
    echo -e "${BOLD}Starting CavrixCore RDP Installation...${NC}"
    echo ""
    
    # Run all functions
    check_root
    check_internet
    detect_os
    system_update
    install_desktop
    install_xrdp
    configure_firewall
    create_user
    
    # Start services
    print_status "info" "Starting services..."
    systemctl restart xrdp >> "$LOG_FILE" 2>&1
    systemctl enable xrdp >> "$LOG_FILE" 2>&1
    
    # Display completion
    display_info
}

# Execute main function
main

# Exit
exit 0
