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
CONFIG_DIR="/etc/cavrixcore"

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
}

# Function: Check internet
check_internet() {
    print_status "info" "Checking internet connection..."
    if ! ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        print_status "error" "No internet connection"
        exit 1
    fi
    print_status "success" "Internet connection OK"
}

# Function: Backup system
backup_system() {
    print_status "info" "Creating system backup..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup important files
    cp /etc/ssh/sshd_config "$BACKUP_DIR/" 2>/dev/null
    cp /etc/xrdp/xrdp.ini "$BACKUP_DIR/" 2>/dev/null
    cp /etc/xrdp/sesman.ini "$BACKUP_DIR/" 2>/dev/null
    
    # Backup package list
    dpkg --get-selections > "$BACKUP_DIR/package-list.txt" 2>/dev/null
    
    print_status "success" "Backup created at: $BACKUP_DIR"
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
    
    apt-get update -y >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        apt-get upgrade -y >> "$LOG_FILE" 2>&1
        apt-get dist-upgrade -y >> "$LOG_FILE" 2>&1
        apt-get autoremove -y >> "$LOG_FILE" 2>&1
        apt-get autoclean -y >> "$LOG_FILE" 2>&1
        print_status "success" "System updated successfully"
    else
        print_status "error" "Failed to update system"
        exit 1
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
    read -p "Enter choice [1-5]: " de_choice
    
    case $de_choice in
        1)
            DESKTOP="xfce4"
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
        *)
            DESKTOP="xfce4"
            DESKTOP_NAME="XFCE"
            print_status "info" "Defaulting to XFCE"
            ;;
    esac
    
    print_status "info" "Installing $DESKTOP_NAME..."
    
    # Install basic display manager
    apt-get install -y lightdm lightdm-gtk-greeter >> "$LOG_FILE" 2>&1
    
    # Install selected desktop
    apt-get install -y "$DESKTOP" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        print_status "success" "$DESKTOP_NAME installed successfully"
    else
        print_status "error" "Failed to install $DESKTOP_NAME"
        exit 1
    fi
    
    # Set lightdm as default
    systemctl set-default graphical.target >> "$LOG_FILE" 2>&1
    systemctl enable lightdm >> "$LOG_FILE" 2>&1
}

# Function: Install xRDP
install_xrdp() {
    print_status "info" "Installing xRDP..."
    
    # Install xRDP and dependencies
    apt-get install -y xrdp xorgxrdp xorg dbus-x11 >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        print_status "success" "xRDP installed successfully"
    else
        print_status "error" "Failed to install xRDP"
        exit 1
    fi
    
    # Configure xRDP
    print_status "info" "Configuring xRDP..."
    
    # Backup original config
    cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.backup
    cp /etc/xrdp/sesman.ini /etc/xrdp/sesman.ini.backup
    
    # Optimize xRDP configuration
    cat > /etc/xrdp/xrdp.ini << EOF
[globals]
bitmap_cache=yes
bitmap_compression=yes
port=3389
crypt_level=high
channel_code=1
max_bpp=32
# CavrixCore Configuration
use_compression=yes
tcp_nodelay=yes
tcp_keepalive=yes
# Security
security_layer=negotiate
certificate=
key_file=

[xrdp1]
name=sesman-Xvnc
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=-1
EOF
    
    # Configure session manager
    sed -i 's/^MaxSession=.*/MaxSession=50/' /etc/xrdp/sesman.ini
    sed -i 's/^KillDisconnected=.*/KillDisconnected=1/' /etc/xrdp/sesman.ini
    sed -i 's/^DisconnectedTimeLimit=.*/DisconnectedTimeLimit=600/' /etc/xrdp/sesman.ini
    sed -i 's/^IdleTimeLimit=.*/IdleTimeLimit=1800/' /etc/xrdp/sesman.ini
    
    print_status "success" "xRDP configured"
}

# Function: Configure Firewall
configure_firewall() {
    print_status "info" "Configuring firewall..."
    
    # Check if ufw is available
    if command -v ufw &> /dev/null; then
        ufw allow 3389/tcp >> "$LOG_FILE" 2>&1
        ufw allow ssh >> "$LOG_FILE" 2>&1
        ufw --force enable >> "$LOG_FILE" 2>&1
        print_status "success" "Firewall configured (UFW)"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=3389/tcp >> "$LOG_FILE" 2>&1
        firewall-cmd --permanent --add-service=ssh >> "$LOG_FILE" 2>&1
        firewall-cmd --reload >> "$LOG_FILE" 2>&1
        print_status "success" "Firewall configured (firewalld)"
    else
        print_status "warning" "No supported firewall found"
    fi
}

# Function: Optimize Performance
optimize_performance() {
    print_status "info" "Applying performance optimizations..."
    
    # Create optimization script
    mkdir -p "$INSTALL_DIR"
    cat > "$INSTALL_DIR/optimize.sh" << 'EOF'
#!/bin/bash
# CavrixCore Performance Optimizations

# Disable unnecessary services
systemctl disable bluetooth.service 2>/dev/null
systemctl disable cups.service 2>/dev/null
systemctl disable avahi-daemon.service 2>/dev/null

# Optimize swappiness
echo "vm.swappiness=10" >> /etc/sysctl.conf

# Optimize network
echo "net.core.rmem_max = 134217728" >> /etc/sysctl.conf
echo "net.core.wmem_max = 134217728" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 134217728" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 134217728" >> /etc/sysctl.conf

# Apply changes
sysctl -p
EOF
    
    chmod +x "$INSTALL_DIR/optimize.sh"
    "$INSTALL_DIR/optimize.sh" >> "$LOG_FILE" 2>&1
    
    print_status "success" "Performance optimizations applied"
}

# Function: Enable Audio Redirection (experimental)
enable_audio() {
    print_status "info" "Enable audio redirection? (y/N): "
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "info" "Installing audio support..."
        apt-get install -y pulseaudio pulseaudio-module-xrdp >> "$LOG_FILE" 2>&1
        
        # Configure PulseAudio for xRDP
        cat > /etc/pulse/default.pa << 'EOF'
#!/usr/bin/pulseaudio -nF
.nofail
.fail
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;192.168.0.0/16;10.0.0.0/8;172.16.0.0/12
load-module module-zeroconf-publish
load-module module-suspend-on-idle
load-module module-position-event-sounds
load-module module-role-cork
load-module module-always-sink
load-module module-switch-on-connect
EOF
        
        systemctl --user enable pulseaudio >> "$LOG_FILE" 2>&1
        print_status "success" "Audio redirection enabled"
    fi
}

# Function: Install Additional Tools
install_tools() {
    print_status "info" "Installing additional tools..."
    
    # Basic utilities
    apt-get install -y \
        htop \
        net-tools \
        curl \
        wget \
        git \
        nano \
        vim \
        screen \
        tmux \
        zip \
        unzip \
        software-properties-common \
        gnupg \
        ca-certificates >> "$LOG_FILE" 2>&1
    
    # Web browser
    apt-get install -y firefox-esr >> "$LOG_FILE" 2>&1
    
    # File manager
    apt-get install -y thunar nautilus >> "$LOG_FILE" 2>&1
    
    # Terminal
    apt-get install -y xfce4-terminal gnome-terminal >> "$LOG_FILE" 2>&1
    
    print_status "success" "Additional tools installed"
}

# Function: Create User Management
create_user_management() {
    print_status "info" "Setting up user management..."
    
    cat > "$INSTALL_DIR/user-manager.sh" << 'EOF'
#!/bin/bash
# CavrixCore User Manager

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "CavrixCore User Management"
echo "=========================="
echo "1) Create new RDP user"
echo "2) Change user password"
echo "3) List all users"
echo "4) Add user to sudo group"
echo "5) Exit"
echo

read -p "Select option: " choice

case $choice in
    1)
        read -p "Enter username: " username
        adduser $username
        usermod -aG sudo $username 2>/dev/null
        echo -e "${GREEN}User $username created${NC}"
        ;;
    2)
        read -p "Enter username: " username
        passwd $username
        ;;
    3)
        echo "System users:"
        echo "-------------"
        awk -F: '{ if ($3 >= 1000 && $3 <= 60000) print $1 }' /etc/passwd
        ;;
    4)
        read -p "Enter username: " username
        usermod -aG sudo $username
        echo -e "${GREEN}User $username added to sudo group${NC}"
        ;;
    5)
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
esac
EOF
    
    chmod +x "$INSTALL_DIR/user-manager.sh"
    
    # Create admin user if not exists
    if ! id "cavrixadmin" &>/dev/null; then
        useradd -m -s /bin/bash cavrixadmin
        echo "cavrixadmin:$(openssl rand -base64 12)" | chpasswd
        usermod -aG sudo cavrixadmin
        print_status "success" "Default admin user created: cavrixadmin"
        print_status "warning" "Please change cavrixadmin password immediately!"
    fi
    
    print_status "success" "User management setup complete"
}

# Function: Create Monitoring Script
create_monitoring() {
    print_status "info" "Setting up monitoring..."
    
    cat > "$INSTALL_DIR/monitor.sh" << 'EOF'
#!/bin/bash
# CavrixCore System Monitor

echo "======================================"
echo "     CavrixCore System Monitor"
echo "======================================"
echo "Last updated: $(date)"
echo

# System Info
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "Kernel: $(uname -r)"
echo

# CPU Usage
echo "=== CPU Usage ==="
echo "$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
echo

# Memory Usage
echo "=== Memory Usage ==="
free -h | awk '/^Mem:/ {print "Total: " $2 " | Used: " $3 " | Free: " $4 " | Usage: " $3/$2*100 "%"}'
echo

# Disk Usage
echo "=== Disk Usage ==="
df -h / | awk 'NR==2 {print "Total: " $2 " | Used: " $3 " | Free: " $4 " | Usage: " $5}'
echo

# Active RDP Sessions
echo "=== Active RDP Sessions ==="
netstat -tn | grep :3389 | wc -l | awk '{print "Active RDP connections: " $1}'
echo

# System Load
echo "=== System Load ==="
cat /proc/loadavg | awk '{print "1min: " $1 " | 5min: " $2 " | 15min: " $3}'
echo

# Services Status
echo "=== Services Status ==="
systemctl is-active xrdp | awk '{print "xRDP: " $0}'
systemctl is-active lightdm | awk '{print "LightDM: " $0}'
systemctl is-active ssh | awk '{print "SSH: " $0}'
echo
EOF
    
    chmod +x "$INSTALL_DIR/monitor.sh"
    
    # Create cron job for monitoring
    cat > /etc/cron.d/cavrixcore-monitor << EOF
# CavrixCore System Monitoring
*/5 * * * * root $INSTALL_DIR/monitor.sh >> /var/log/cavrixcore-status.log
EOF
    
    print_status "success" "Monitoring system setup complete"
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
    echo -e "   Host: $(curl -s ifconfig.me || hostname -I | awk '{print $1}')"
    echo -e "   Port: 3389"
    echo -e "   Username: Your system username"
    echo ""
    echo -e "${YELLOW}🖥️  Desktop Environment:${NC} $DESKTOP_NAME"
    echo ""
    echo -e "${YELLOW}🔧 Management Tools:${NC}"
    echo -e "   User Manager: ${INSTALL_DIR}/user-manager.sh"
    echo -e "   System Monitor: ${INSTALL_DIR}/monitor.sh"
    echo -e "   Performance Optimizer: ${INSTALL_DIR}/optimize.sh"
    echo ""
    echo -e "${YELLOW}📊 Services Status:${NC}"
    systemctl is-active xrdp | awk '{print "   xRDP: " $0}'
    systemctl is-active lightdm | awk '{print "   LightDM: " $0}'
    echo ""
    echo -e "${YELLOW}📝 Installation Log:${NC} $LOG_FILE"
    echo -e "${YELLOW}💾 Backup Location:${NC} $BACKUP_DIR"
    echo ""
    echo "======================== SECURITY NOTES ========================="
    echo ""
    echo -e "${RED}⚠️  IMPORTANT SECURITY ACTIONS REQUIRED:${NC}"
    echo "   1. Change default passwords immediately!"
    echo "   2. Configure firewall rules as needed"
    echo "   3. Enable automatic security updates"
    echo "   4. Regularly check system logs"
    echo ""
    echo "======================== QUICK COMMANDS ========================="
    echo ""
    echo "   Check RDP status: sudo systemctl status xrdp"
    echo "   Restart RDP: sudo systemctl restart xrdp"
    echo "   View active sessions: netstat -tn | grep :3389"
    echo "   Monitor system: $INSTALL_DIR/monitor.sh"
    echo ""
    echo "================================================================="
    echo ""
    echo -e "${BLUE}Thank you for using CavrixCore RDP Installer!${NC}"
    echo ""
}

# Function: Enable Auto Updates
enable_auto_updates() {
    print_status "info" "Enabling automatic security updates..."
    
    apt-get install -y unattended-upgrades >> "$LOG_FILE" 2>&1
    
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESM:${distro_codename}";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
    
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
    
    print_status "success" "Automatic updates enabled"
}

# Main installation process
main() {
    echo -e "${BOLD}Starting CavrixCore RDP Installation...${NC}"
    echo ""
    
    # Run all functions
    check_root
    check_internet
    detect_os
    backup_system
    system_update
    install_desktop
    install_xrdp
    configure_firewall
    optimize_performance
    enable_audio
    install_tools
    create_user_management
    create_monitoring
    enable_auto_updates
    
    # Start services
    print_status "info" "Starting services..."
    systemctl restart xrdp >> "$LOG_FILE" 2>&1
    systemctl enable xrdp >> "$LOG_FILE" 2>&1
    systemctl restart lightdm >> "$LOG_FILE" 2>&1
    
    # Display completion
    display_info
}

# Execute main function
main

# Exit
exit 0
