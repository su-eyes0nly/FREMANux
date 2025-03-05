#!/bin/bash

set -e  # Exit if any command fails

### CONFIGURATION ###
TERMINAL="xfce4-terminal"  # Change if using a different terminal
BROWSER="firefox"  # Change if you prefer a different browser
DE="xfce4"  # Change to lxqt or openbox if desired
AUDIO_PACKAGES=("pipewire" "pipewire-pulse" "pavucontrol")  # Lightweight audio system
ESSENTIAL_PACKAGES=("networkmanager" "xorg" "xorg-xinit" "sudo" "git" "curl" "wget" "unzip" "p7zip" "neofetch" "htop" "nano" "vim")
DESKTOP_ENVIRONMENTS=("xfce4 xfce4-goodies lightdm lightdm-gtk-greeter" "lxqt xdg-user-dirs lightdm lightdm-gtk-greeter" "openbox obconf obmenu nitrogen tint2 lightdm lightdm-gtk-greeter")
APPLICATIONS=("$BROWSER" "file-roller" "thunar" "mousepad" "$TERMINAL")

### FUNCTION: Install Packages ###
install_packages() {
    echo -e "\n[+] Installing: $*"
    sudo pacman -S --noconfirm --needed "$@"
}

### FUNCTION: Update System ###
update_system() {
    echo -e "\n[+] Updating system..."
    sudo pacman -Syu --noconfirm
}

### FUNCTION: Install Essential Tools ###
install_essentials() {
    echo -e "\n[+] Installing essential tools..."
    install_packages "${ESSENTIAL_PACKAGES[@]}"
}

### FUNCTION: Install Audio System ###
install_audio() {
    echo -e "\n[+] Installing audio system..."
    install_packages "${AUDIO_PACKAGES[@]}"
}

### FUNCTION: Install Desktop Environment ###
install_desktop_environment() {
    echo -e "\n[+] Installing desktop environment: $DE"
    
    case "$DE" in
        "xfce4") install_packages ${DESKTOP_ENVIRONMENTS[0]} ;;
        "lxqt") install_packages ${DESKTOP_ENVIRONMENTS[1]} ;;
        "openbox") install_packages ${DESKTOP_ENVIRONMENTS[2]} ;;
        *) echo "Invalid desktop environment! Exiting..."; exit 1 ;;
    esac
    
    sudo systemctl enable lightdm
}

### FUNCTION: Install Applications ###
install_applications() {
    echo -e "\n[+] Installing applications..."
    install_packages "${APPLICATIONS[@]}"
}

### FUNCTION: Enable NetworkManager ###
enable_network() {
    echo -e "\n[+] Enabling NetworkManager..."
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager
}

### FUNCTION: Configure Keyboard Shortcuts for XFCE ###
configure_xfce_shortcuts() {
    echo -e "\n[+] Configuring XFCE keyboard shortcuts..."
    install_packages xfconf  # Ensure xfconf is installed

    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>Return" -n -t string -s "$TERMINAL"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>space" -n -t string -s "xfce4-appfinder"

    echo "[✔] XFCE keyboard shortcuts configured!"
}

### FUNCTION: Configure Keyboard Shortcuts for LXQt ###
configure_lxqt_shortcuts() {
    echo -e "\n[+] Configuring LXQt keyboard shortcuts..."
    mkdir -p ~/.config/lxqt
    cp /etc/xdg/lxqt/globalkeyshortcuts.conf ~/.config/lxqt/globalkeyshortcuts.conf
    sed -i '/^\[General\]$/a \Super+Return=xfce4-terminal' ~/.config/lxqt/globalkeyshortcuts.conf
    echo "[✔] LXQt keyboard shortcuts configured!"
}

### FUNCTION: Configure Keyboard Shortcuts for Openbox ###
configure_openbox_shortcuts() {
    echo -e "\n[+] Configuring Openbox keyboard shortcuts..."
    mkdir -p ~/.config/openbox
    cp /etc/xdg/openbox/rc.xml ~/.config/openbox/rc.xml

    sed -i '/<keyboard>/a \
      <keybind key="W-Return">\
        <action name="Execute">\
          <command>'"$TERMINAL"'</command>\
        </action>\
      </keybind>' ~/.config/openbox/rc.xml

    openbox --reconfigure
    echo "[✔] Openbox keyboard shortcuts configured!"
}

### FUNCTION: Configure Keyboard Shortcuts Based on DE ###
configure_keyboard_shortcuts() {
    case "$DE" in
        "xfce4") configure_xfce_shortcuts ;;
        "lxqt") configure_lxqt_shortcuts ;;
        "openbox") configure_openbox_shortcuts ;;
    esac
}

### FUNCTION: Main Setup Process ###
main_setup() {
    update_system
    install_essentials
    install_audio
    install_desktop_environment
    install_applications
    enable_network
    configure_keyboard_shortcuts

    echo -e "\n[✔] Setup complete! Reboot your system."
}

### RUN THE SETUP ###
main_setup
