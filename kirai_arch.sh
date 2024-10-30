#!/bin/bash

# Intro
loading_intro() {
    echo -e "\n"
    local text=(
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣶⣶⠿⠿⠿⣶⣦⣀⠀⠀⠀"
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠛⠉⠀⠀⠀⠀⠀⠀⠉⠻⣧⡀⠀"
        "⢠⣄⣀⣀⣀⣀⣀⣀⣀⣴⠋⠀⠀⠀⠀⠀⣴⣆⠀⠀⠀⠀⠘⣿⡀"
        "⠀⠙⠻⣿⣟⠛⠛⠛⠋⠁⠀⠀⠀⠀⠀⠘⠿⠋⠀⠀⠀⠀⠀⣿⡇"
        "⠀⠀⠀⠀⠙⢷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⡇"
        "⠀⠀⠀⠀⠀⠀⠘⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣽⠃"
        "⠀⠀⠀⠀⠀⠀⢰⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀"
        "⠀⠀⠀⠀⠀⠀⣾⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡿⠀"
        "⠀⠀⠀⠀⠀⢸⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠃⠀"
        "⠀⠀⠀⠀⢀⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡟⠀⠀"
        "⠀⠀⠀⠀⣾⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠇⠀⠀"
	""
	""
	""
        "    Kirai's Arch Install!"     
        " My GitHub: https://github.com/KiraiF/"
    )

    # Loop through each line and print it with a delay
    for line in "${text[@]}"; do
        echo -e "$line"
        sleep 0.150  # Adjust the delay as needed
    done
}
# Call the loading function
loading_intro

#Connecting to Internet (wifi only for now)
 read -p "Do you wanna connect to wifi?", confirm0
 connecting_wifi(){
     read -p "Enter your SSID:" ssid
     read -s -p "Enter passphrase:" passphrase
     iwctl station wlan0 connect "$ssid" -P "$passphrase"
 }
 if [[ $confirm0 = "y" ]]; then
    echo "Connecting to your wifi"
    connecting_wifi
 fi
 
 sleep 5
 check_wifi_connection() {
     iwctl station wlan0 show | grep -q "Connected"  # Adjust wlan0 if your device name is different
 }
 if check_wifi_connection; then
     echo "Successfully connected to $ssid!"
 else
     echo "Failed to connect to $ssid. Try again"
     connecting_wifi
 fi

# Ask for the disk to use

echo "Available disks:"
lsblk -d -e 7,11 -n -o NAME,SIZE
choose_disk(){
    read -p "Enter the disk you want to install Arch on (e.g., sda): " diskc
}
choose_disk
# Confirm with the user
read -p "You chose /dev/$diskc. Are you sure? (y/n) " confirm
if [[ $confirm != "y" ]]; then
    echo "Cancelled..."
    choose_disk
fi

echo "Partition Disk according to your needs...."
echo "Press Enter to partition.."
read
sgdisk -o -n 1:0:+2G -t 1:ef00 -n 2:0:+15G -t 2:8200 -n 3:0:+80G -t 3:8300 -n 4:0:0 -t 4:8300 /dev/$diskc

read -p "Were you satisfied with Paritioning? (y/n) " confirm1
lsblk /dev/$diskc
echo "Formatting partitions..."
mkfs.fat -F32 /dev/${diskc}p1           # Format EFI partition
mkswap /dev/${diskc}p2                   # Set up SWAP partition
mkfs.ext4 /dev/${diskc}p3                # Format root partition
mkfs.ext4 /dev/${diskc}p4                # Format home partition
echo "Formatting completed"

echo "Mounting disks"
mount /dev/${diskc}p3 /mnt
mount --mkdir /dev/${diskc}p1 /mnt/boot
mount --mkdir /dev/${diskc}p4 /mnt/home
swapon /dev/${diskc}p2
echo "Mounting Complete"

echo "Installing essentials"
pacstrap -K /mnt base base-devel amd-ucode nano linux linux-firmware git
echo "Completed."

echo "Generating Fstab for mounted disks"
genfstab -U /mnt >> /mnt/etc/fstab 
echo "Completed."

echo "Chrooting into the system..."
arch-chroot /mnt /bin/bash -c '

echo "Setting time zone..."
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

echo "Setting locale..."
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "Creating an initial ramdisk environment (mkinitcpio)"
mkinitcpio -P

read -p "Enter the hostname for your system: " hostname

# Create user and home directory
useradd -G wheel $hostname
mkdir /home/$hostname
chown $hostname:$hostname /home/$hostname
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

echo "User created"
read -p "Do you wanna create a password for your user? (y/n) " confirm2
if [[ $confirm2 == "y" ]]; then
    passwd $hostname
fi

echo "Updating keyring..."
pacman-key --init
pacman-key --populate archlinux
pacman -Sy  # Update the package database


echo "Installing essentials for your system."
pacman -S --noconfirm networkmanager grub efibootmgr kitty bluez bluez-utils ntfs-3g
systemctl enable NetworkManager

# Ask if the user wants a desktop environment
echo -e "Choose a Desktop Environment:\n1) GNOME\n2) KDE Plasma\n3) Hyprland\n4) Skip DE installation"
read -n1 -p "Press 1, 2, or 3: " de_choice
echo ""

case $de_choice in
    1)
        echo "You selected GNOME."
        pacman -S --noconfirm gnome gnome-extra
        ;;
    2)
        echo "You selected KDE Plasma."
        pacman -S --noconfirm plasma kde-applications
        ;;
    3)
        echo "You selected Hyprland."
        pacman -S --noconfirm hyprland sddm
        ;;
    4)
        echo "Skipping desktop environment installation."
        ;;
    *)
        echo "Invalid choice. Skipping desktop environment installation."
        ;;
esac

# Install bootloader
echo "Installing bootloader..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable sddm
echo "Exiting chroot..."
exit
'
echo "Enter password for root (very necessary):"
passwd 
echo "Installation complete. Unmounting..."
umount -R /mnt
echo "Installation complete. Press any key to reboot or Ctrl+C to cancel."
read
reboot
