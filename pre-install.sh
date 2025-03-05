#!/bin/bash

set -e  # Exit on error

# Make sure script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Exiting."
  exit 1
fi


# Config
DISK="/dev/sda"         # Set the disk (/dev/sda, /dev/nvme0n1, /dev/vda)
HOSTNAME="FREMANux"     # Set hostname
USERNAME="Examiner"     # Change this to your desired username
PASSWORD="fremanux"     # Change this to your desired password
TIMEZONE="GMT"  	    # Set your timezone (modify as needed)
LOCALE="en_GB.UTF-8"    # Set locale


# Partition the disk
echo -e "\n[+] Partitioning disk: $DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 512MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart ROOT ext4 512MiB 100%


# Format disks
echo -e "\n[+] Formatting partitions..."
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"


# Mount partitions
echo -e "\n[+] Mounting partitions..."
mount "${DISK}2" /mnt
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot


# Install base system
echo -e "\n[+] Installing base system..."
pacstrap /mnt base linux linux-firmware nano vim grub efibootmgr networkmanager

# Gen fstab
echo -e "\n[+] Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab


# chroot into new installation
echo -e "\n[+] Configuring system..."
arch-chroot /mnt /bin/bash <<EOF

# Timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localization
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Hostname & Hosts
echo "$HOSTNAME" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOT

# Root password
echo "root:$PASSWORD" | chpasswd

# Create user
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# Allow sudo for wheel group
pacman -S --noconfirm sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager

EOF

### CLEANUP AND REBOOT ###
echo -e "\n[+] Installation complete. Rebooting..."
umount -R /mnt

reboot
