#!/bin/bash

# Disk preparation
cfdisk /dev/sda
mkdir /mnt/gentoo
mkfs.ext4 /dev/sda3
mount /dev/sda3 /mnt/gentoo
mkdir -p /mnt/gentoo/boot/efi
mkfs.fat -F 32 /dev/sda1
mount /dev/sda1 /mnt/gentoo/boot/efi
mkswap /dev/sda2
swapon /dev/sda2

# Stage tarball and basic compile options ALWAYS EDIT FITH CURRENT
cd /mnt/gentoo
wget https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20230705T183202Z/stage3-amd64-openrc-20230705T183202Z.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
nano -w /mnt/gentoo/etc/portage/make.conf

# Chroot preparation
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run


# Chroot into the new environment
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

# Configure Portage and system profile
emerge-webrsync
emerge --sync
eselect profile list
eselect profile set 1
emerge -avuDN @world
nano -w /etc/portage/make.conf
echo "USE=\"*\"" >> /etc/portage/make.conf
echo "ACCEPT_LICENSE=\"*\"" >> /etc/portage/make.conf
echo "Europe/Helsinki" > /etc/timezone
emerge --config sys-libs/timezone-data
nano -W /etc/locale.gen
locale-gen
eselect locale list
eselect profile set 4
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
emerge --ask sys-kernel/linux-firmware
emerge sys-kernel/installkernel-gentoo
emerge sys-kernel/gentoo-kernel-bin

# Generate fstab using genfstab script
sudo su
cd
chmod +x genfstab
./genfstab -U /mnt/gentoo >> /mnt/gentoo/etc/fstab

#!/bin/bash

# Set host and system information
echo "gentoobox" > /etc/conf.d/hostname
cat > /etc/hosts << EOF
127.0.0.1 localhost
127.0.1.1 gentoobox.localdomain gentoobox
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF

# Set the root password
echo "root:password" | chpasswd

# Set keymap preferences
echo "keymap=\"us colemak\"" > /etc/conf.d/keymaps

emerge dhcpcd sudo neofetch grub efibootmgr 

grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel
Ensure no duplicate sudoers entries
sed -i '/^%wheel ALL=(ALL) ALL/d' /etc/sudoers


useradd -m -G wheel,users,audio,video,usb -s /bin/bash vandros
passwd vandros

# Exit chroot and cleanup
exit
exit
sudo umount -a

