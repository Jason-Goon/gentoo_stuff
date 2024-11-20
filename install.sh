#!/bin/bash

source gentoo-config.conf


parted --script $DISK \
    mklabel gpt \
    mkpart primary fat32 1MiB 100MiB \
    set 1 esp on \
    mkpart primary linux-swap 100MiB 8GiB \
    mkpart primary ext4 8GiB 100%

mkfs.fat -F 32 $EFI_PART
mkfs.ext4 $ROOT_PART
mkswap $SWAP_PART
mount $ROOT_PART /mnt/gentoo
mkdir -p /mnt/gentoo/boot/efi
mount $EFI_PART /mnt/gentoo/boot/efi
swapon $SWAP_PART

cd /mnt/gentoo
wget $STAGE3_URL
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
nano -w /mnt/gentoo/etc/portage/make.conf

cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

chroot /mnt/gentoo /bin/bash 
source /etc/profile
export PS1="(chroot) \$PS1"

emerge-webrsync
emerge --sync
eselect profile list
eselect profile set $PROFILE
emerge -avuDN @world
nano -w /etc/portage/make.conf
echo "USE=\"*\"" >> /etc/portage/make.conf
echo "ACCEPT_LICENSE=\"*\"" >> /etc/portage/make.conf
echo "$TIMEZONE" > /etc/timezone
emerge --config sys-libs/timezone-data
echo "$LOCALE" >> /etc/locale.gen
locale-gen
eselect locale list
eselect locale set 1
env-update && source /etc/profile && export PS1="(chroot) \$PS1"
emerge --ask sys-kernel/linux-firmware
emerge sys-kernel/installkernel-gentoo
emerge sys-kernel/gentoo-kernel-bin

chmod +x genfstab
./genfstab -U /mnt/gentoo >> /mnt/gentoo/etc/fstab

echo "$HOSTNAME" > /etc/conf.d/hostname
cat > /etc/hosts << EOL
127.0.0.1 $HOSTNAME
127.0.0.1 localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOL

echo "root:$PASSWORD" | chpasswd

echo "keymap=\"$KEYMAP\"" > /etc/conf.d/keymaps
emerge dhcpcd sudo neofetch grub efibootmgr 
grub-install $DISK
grub-mkconfig -o /boot/grub/grub.cfg
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel
sed -i '/^%wheel ALL=(ALL) ALL/d' /etc/sudoers
useradd -m -G wheel,users,audio,video,usb -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD2" | chpasswd

exit
umount -a
echo "Gentoo installation is complete!"

