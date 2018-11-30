# Kickstart files for creating CentOS machines in the cloud or in virtual environment

This script will setup your machine for rebooting into a kickstart automated install with VNC support.

Use the bash script below to Kickstart install CentOS.

## To Use

Deploy a CentOS 7 linux machine via cloud image or VM template and copy script below making changes to `inst.ks=` and any other boot options as needed.

See this site for additional boot options and their descriptions <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-anaconda-boot-options>

Note that using vnc will cause the system to wait for a connection before continuing to load and run installer.
Simply remove `inst.vnc` and `inst.headless` parts if you have access to the console or wish to have it fully automated.
It may take a long time for installation and before your system reboots into a usable state.

If DHCP is not available change `ip=dhcp` to something like `ip=<ip>::<gateway>:<netmask>::<interface>:none`

### Bash Script

```bash
# Make sure wget is installed
yum install wget

# Download linux installer ram images for booting into installer kernel
cd /boot
wget http://mirror.centos.org/centos/7/os/x86_64/isolinux/vmlinuz -O vmlinuz-7
wget http://mirror.centos.org/centos/7/os/x86_64/isolinux/initrd.img -O initrd-7.img

# Create grub menu entry
echo "menuentry 'NetInstall' {\n" \
  "insmod gzio\n" \
  "insmod part_msdos\n" \
  "insmod ext2\n" \
  "set root='hd0,msdos1'\n" \
  "linux16 /vmlinuz-7 inst.vnc inst.vncpassword=Root1234! inst.headless inst.ks=https://raw.githubusercontent.com/Stromweld/kickstart/master/vmware_centos.ks ip=dhcp\n" \
  "initrd16 /initrd-7.img" >> /etc/grub.d/40_custom

# Make sure we only boot into our custom menu entry once
sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/g' /etc/default/grub

# Rebuild the grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg

# List available menu entry
awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg

# verify the default menu entry.
# you can use grub2-set-default 'MenuEntry' 
# to change the default boot
grub2-editenv list

# boot our new menu entry for the next reboot. 
# We just need to use the menu entry title.
grub2-reboot NetInstall

# Reboot machine
#reboot
```

## Disclaimer

I built this script based off of information gathered from <http://www.danpros.com/2016/02/how-to-install-centos-7-remotely-using-vnc> and <https://www.andrewklau.com/roll-your-own-centos-6-5-hvm-ami-in-less-than-15-minutes/> 

For additional kickstart file options reference <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-syntax#sect-kickstart-commands>
