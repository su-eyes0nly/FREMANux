#!/bin/bash

# Exit on error
set -e

echo "Updating system..."
sudo pacman -Syu --noconfirm

# Installing forensic tools
echo "Installing general tools..."
sudo pacman -Sy --noconfirm fish vim htop 

# Create default folders
mkdir Documents Downloads Pictures

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

# Essential utilities
echo "Installing additional utilities..."
sudo pacman -Sy --noconfirm network-manager-applet pavucontrol alsa-utils xfce4-terminal ttf-nerd-fonts-symbols lm_sensors mesa-utils

# Enable Network Manager
echo "Enabling NetworkManager..."
sudo systemctl enable NetworkManager.service

# Set Fish as the default shell
echo "Setting Fish as the default shell..."
chsh -s /usr/bin/fish $(whoami)

# Add user to Wireshark group for packet capturing
echo "Adding $(whoami) to Wireshark group..."
sudo usermod -aG wireshark $(whoami)

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
