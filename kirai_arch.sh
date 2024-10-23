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

# echo "Connecting to Internet"
# connecting_wifi(){
#     read -p "Enter your SSID:" ssid
#     read -s -p "Enter passphrase:" passphrase
#     iwctl station wlan0 connect "$ssid" -P "$passphrase"
# }
# connecting_wifi

# sleep 5
# check_wifi_connection() {
#     iwctl station wlan0 show | grep -q "Connected"  # Adjust wlan0 if your device name is different
# }
# if check_wifi_connection; then
#     echo "Successfully connected to $SSID!"
# else
#     echo "Failed to connect to $SSID. Try again"
#     connecting_wifi
# fi

# Ask for the disk to use

echo "Available disks:"
lsblk -d -e 7,11 -n -o NAME,SIZE
choose_disk(){
    read -p "Enter the disk you want to install Arch on (e.g., sda): " disk
}
choose_disk
# Confirm with the user
read -p "You chose /dev/$disk. Are you sure? (y/n) " confirm
if [[ $confirm != "y" ]]; then
    echo "Cancelled..."
    choose_disk
fi

echo "Partition Disk according to your needs...."
echo "Recommened Partition Table:
    EFI 2GiB
	SWAP 15GiB
	/ (root) 80GiB
	/home Remainder Space"

echo "Press Enter to continue, Exit the GUI when done."
cfdisk $disk
read "Were you satisfied with Paritioning? (y/n) " confirm1
if [[ $confirm1 != "y" ]]; then
    echo "Cancelled..."
    cfdisk $disk
fi
echo "Formatting partitions..."
mkfs.fat -F32 "${DISK}1"           # Format EFI partition
mkswap "${DISK}2"                   # Set up SWAP partition
mkfs.ext4 "${DISK}3"                # Format root partition
mkfs.ext4 "${DISK}4"                # Format home partition
echo "Formatting completed"

echo "Mounting disks"
mount /dev/parition-3 /mnt
mount --mkdir /dev/partition-1 /mnt/boot
mount --mkdir /dev/partition-4 /mnt/home
swapon /dev/partition-2
echo "Mounting Complete"

echo "Installing essentials"
pacstrap -K /mnt base base-devel amd-ucode nano linux linux-firmware git
echo "Completed."

echo "Generating Fstab for mounted disks"
genfstab -U /mnt >> /mnt/etc/fstab 
echo "Completed."

echo "Chrooting into the system..."
arch-chroot /mnt <<EOF

echo "Setting time zone..."
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

echo "Setting locale..."
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo "Creating an initial ramdisk environment (mkinicpio)"
mkinitcpio -P 		

read -p "Enter the hostname for your system: " hostname

useradd -G wheel $hostname
mkdir /home/$hostname
chown $hostname:$hostname /home/$hostname
echo '%wheel ALL=(ALL)  ALL' > /etc/sudoers
echo "User created"
read "Do you wanna create password for your user? (y/n)" confirm2
if [[ $confirm2 = "y" ]]; then
    passwd $hostname
fi
if [[ $confirm2 != "y" ]]; then
    echo "\n"
fi

echo "Installing essentials for your system."
pacman -S networkmanager grub efibootmgr kitty bluez bluez-utils ntfs-3g --noconfirm
systemctl enable NetworkManager

# Ask if the user wants a desktop environment (no need to press enter after selecting)
echo -e "Choose a Desktop Environment:\n1) GNOME\n2) KDE Plasma\n3)Hyprland\n4) Skip DE installation"
read -n1 -p "Press 1, 2, or 3: " de_choice
echo ""

case $de_choice in
    1)
        echo "You selected GNOME."
        pacman -S gnome gnome-extra --noconfirm
        ;;
    2)
        echo "You selected KDE Plasma."
        pacman -S plasma kde-applications --noconfirm
        ;;
    3)  echo "You selected Hyprland."
        pacman -S hyprland sddm --noconfirm
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
echo "Exitng Chroot.."
EOF
echo "Installation complete. Unmounting..."
umount -R /mnt
echo "Press any key to reboot..."
read
reboot