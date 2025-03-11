#!/bin/bash

# Exit on error
set -e

# Display ASCII Logo
echo "====================================================================="
echo "███████╗██████╗░███████╗███╗░░░███╗░█████╗░███╗░░██╗██╗░░░██╗██╗░░██╗"
echo "██╔════╝██╔══██╗██╔════╝████╗░████║██╔══██╗████╗░██║██║░░░██║╚██╗██╔╝"
echo "█████╗░░██████╔╝█████╗░░██╔████╔██║███████║██╔██╗██║██║░░░██║░╚███╔╝░"
echo "██╔══╝░░██╔══██╗██╔══╝░░██║╚██╔╝██║██╔══██║██║╚████║██║░░░██║░██╔██╗░"
echo "██║░░░░░██║░░██║███████╗██║░╚═╝░██║██║░░██║██║░╚███║╚██████╔╝██╔╝╚██╗"
echo "╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝░╚═════╝░╚═╝░░╚═╝"
echo "====================================================================="
echo "🚀 Welcome to FREMANux 🚀"
echo "This is a post install script for Arch Linux, "
echo "designed to set up tooling for malware analyis, reverse engineering and forensic investigation."
echo
read -rp "Press Enter to continue..."


echo "Updating system..."
if ! sudo pacman -Syu --noconfirm; then
    echo "System update failed!" | tee -a install_errors.log
    exit 1
fi

# Enable multilib repository (if not already enabled)
echo "Checking if multilib is enabled..."
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy --noconfirm
else
    echo "Multilib is already enabled. Skipping..."
fi

# Installing base development tools
echo "Installing base-devel and git..."
if ! sudo pacman -Sy --noconfirm base-devel git; then
    echo "Failed to install base-devel and git!" | tee -a install_errors.log
    exit 1
fi

# Installing yay (AUR helper)
if ! command -v yay &>/dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    if ! makepkg -si --noconfirm; then
        echo "Failed to install yay!" | tee -a install_errors.log
        exit 1
    fi
    cd ~
    rm -rf /tmp/yay-bin
else
    echo "yay is already installed. Skipping..."
fi

# Install required tooling
echo "Installing tools..."
sudo pacman -Sy --noconfirm fish vim python rust 

# Installing i3 window manager and necessary tools
echo "Installing i3 Window Manager and dependencies..."
sudo pacman -Sy --noconfirm i3 dmenu rofi picom feh lxappearance

# Installing LightDM (Display Manager)
echo "Installing LightDM and enabling it..."
sudo pacman -Sy --noconfirm lightdm lightdm-gtk-greeter
sudo systemctl enable lightdm.service

# Installing Polybar
echo "Installing Polybar..."
sudo pacman -Sy --noconfirm polybar

# Installing Conky for i3 keybindings display
echo "Installing Conky..."
if ! sudo pacman -Sy --noconfirm conky; then
    echo "Failed to install Conky!" | tee -a install_errors.log
    exit 1
fi

# Essential utilities
echo "Installing additional utilities..."
sudo pacman -Sy --noconfirm network-manager-applet pavucontrol alsa-utils xfce4-terminal ttf-nerd-fonts-symbols lm_sensors mesa-utils

# Enable Network Manager
echo "Enabling NetworkManager..."
sudo systemctl enable NetworkManager.service

# Set Fish as the default shell
echo "Setting Fish as the default shell..."
chsh -s /usr/bin/fish $(whoami)

# Setting up Polybar for i3
echo "Configuring Polybar..."
mkdir -p ~/.config/polybar
cat <<EOL > ~/.config/polybar/config.ini
[bar/mybar]
width = 100%
height = 30
background = #282C34
foreground = #ABB2BF
modules-left = workspaces
modules-center = cpu ram gpu
modules-right = network volume date

[module/workspaces]
type = internal/i3
format = <label-state> <label-mode>

[module/cpu]
type = internal/cpu
format = CPU: <percentage>%

[module/ram]
type = internal/memory
format = RAM: <used> / <total> MB

[module/gpu]
type = custom/script
exec = glxinfo | grep "OpenGL renderer string" | awk -F': ' '{print "GPU: " \$2}'
interval = 10

[module/network]
type = internal/network
interface = auto
format-connected = "Net: {essid} {signalStrength}%"
format-disconnected = "Offline"

[module/volume]
type = internal/pulseaudio
format-volume = "Vol: {volume}%"
format-muted = "Muted"

[module/date]
type = internal/date
interval = 1
date = "%Y-%m-%d %H:%M:%S"
format = "{date}"
EOL

# Launch Polybar on i3 startup
echo "Configuring i3 to start Polybar..."
mkdir -p ~/.config/i3
echo 'exec_always --no-startup-id polybar mybar &' >> ~/.config/i3/config


echo "Post-install setup complete! Please reboot the system."
