#skipx
#text
install
url --url=http://mirror.centos.org/centos/7/os/x86_64/
# Firewall configuration
firewall --disabled --ssh --service=ssh
eula --agreed
vnc --host=10.12.34.158 --port=5500

repo --name=centos-base --baseurl=http://mirror.centos.org/centos/7/os/x86_64/
repo --name=centos-updates --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/
repo --name=centos-extras --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/
#repo --name=centos-centosplus --baseurl=http://mirror.centos.org/centos/7/centosplus/x86_64/
repo --name=centos-fasttrack --baseurl=http://mirror.centos.org/centos/7/fasttrack/x86_64/
repo --name=centos-sclo --baseurl=http://mirror.centos.org/centos/7/sclo/x86_64/sclo/
repo --name=centos-sclo-rh --baseurl=http://mirror.centos.org/centos/7/sclo/x86_64/rh/
repo --name=centos-epel --baseurl=http://download.fedoraproject.org/pub/epel/7/x86_64/
#repo --name=centos-spacewalk-client --baseurl=http://yum.spacewalkproject.org/2.6-client/RHEL/7/x86_64/

rootpw  --iscrypted $6$o3ryIQwy$A8YWp768PAClU2zNuXe.Ji6KgTCbTJYqw7pq3SVSosIapP2vB7Pod56qKz0GA25uXOWjR7WMjo1F4UgVrGOmL/
auth --enableshadow --passalgo=sha512
# System keyboard
keyboard us
# System language
lang en_US.UTF-8
# SELinux configuration
selinux --permissive
# Installation logging level
logging --level=info
firstboot --disable

# System services
services --disabled="avahi-daemon,iscsi,iscsid,firstboot,kdump" --enabled="network,sshd,rsyslog,tuned,acpid,chronyd"
# System timezone
timezone America/Chicago --isUtc --ntpservers=10.12.34.11,10.12.34.12
# Network information
network  --bootproto=dhcp --activate
network  --hostname=localhost.localdomain

ignoredisk --only-use=xvda
zerombr
# System bootloader configuration
bootloader --append="console=tty0" --location=mbr --timeout=1 --boot-drive=xvda
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part pv.1015 --fstype="lvmpv" --ondisk=xvda --size=30219
part /boot --fstype="xfs" --ondisk=xvda --size=500 --label=boot
volgroup vg_root --pesize=4096 pv.1015
logvol /var/log  --fstype="xfs" --size=2048 --name=lv_varlog --vgname=vg_root
logvol /tmp  --fstype="xfs" --size=4096 --name=lv_tmp --vgname=vg_root
logvol swap  --fstype="swap" --size=4096 --name=lv_swap --vgname=vg_root
logvol /  --fstype="xfs" --size=19976 --name=lv_root --vgname=vg_root
reboot

%packages --ignoremissing --nobase
@^minimal
#@core
#@base
#chrony
#dracut-config-generic
#dracut-norescue
#firewalld
#grub2
#nfs-utils
#rsync
#tar
#yum-utils
#rhn-client-tools
#rhn-check
#rhn-setup
#rhnsd
#m2crypto
#yum-rhn-plugin
#perl
#wget
epel-release
#nano
centos-release-scl
centos-release-scl-rh
#rhnsd
#m2crypto
dstat
bash-completion
bash-completion-extras
htop
oddjob-mkhomedir
realmd
oddjob
sssd
samba-common-tools
cloud-init
cloud-utils
cloud-utils-growpart
dkms
gcc
gcc-c++
#binutils
microsoft-hyper-v
make
kernel
kernel-headers
kernel-devel
tuned-utils
tuned
numad
tuna
#spacewalk-abrt
#openscap-utils
#spacewalk-openscap
#rhncfg-client
#openscap-extra-probes
#rhnlib
#rhncfg
#osad
#rhncfg-management
#openscap-content
#openscap
#rpmconf
mlocate
#krb5-workstation
#autoconf
#bison
#flex
#gettext
#m4
#ncurses-devel
#patch
#ntp
#tzdata
#vim-minimal
#vim-enhanced
#iptables-services
xfsprogs-devel
#net-snmp
#net-snmp-utils

-NetworkManager
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-biosdevname
-iprutils
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware
-plymouth
-b43-openfwwf
-biosdevname
-fprintd
-fprintd-pam
-gtk2
-libfprint
-mcelog
-plymouth
-redhat-support-tool
-wireless-tools
-orca
-gdm-plugin-fingerprint
-ypbind
-totem-mozplugin
-rhn-virtualization-host
-gnome-media
-gnome-screensaver
-pulseaudio-module-gconf
-pulseaudio-module-x11
-vino
-ledmon
-pcmciautils
-printing
-cups
-alsa-plugins-pulseaudio
%end

%addon com_redhat_kdump --disable --reserve-mb='auto'
%end

# post stuff, here's where we do all the customisation
%post

#rpm -Uvh http://yum.spacewalkproject.org/2.6-client/RHEL/7/x86_64/spacewalk-client-repo-2.6-0.el7.noarch.rpm

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tuned/active-profile

# setup systemd to boot to the right runlevel
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

yum -C -y remove linux-firmware

# Remove firewalld; it is required to be present for install/image building.
# but we dont ship it in cloud
yum -C -y remove firewalld --setopt="clean_requirements_on_remove=1"
yum -C -y remove avahi\* Network\*
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
PERSISTENT_DHCLIENT="1"
EOF

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

#systemctl mask tmp.mount

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# XXX instance type markers - MUST match CentOS Infra expectation
echo 'genclo' > /etc/yum/vars/infra

# chance dhcp client retry/timeouts to resolve #6866
cat  >> /etc/dhcp/dhclient.conf << EOF

timeout 300;
retry 60;
EOF

# Fix some first boot issues
rpm --rebuilddb
touch /.autorelabel

# Fix hostname on boot

sed -i -e 's/\(preserve_hostname:\).*/\1 False/' /etc/cloud/cloud.cfg
sed -i '/HOSTNAME/d' /etc/sysconfig/network
rm /etc/hostname

# Use label for fstab, not UUID
#e2label /dev/xvda2 "/boot"
#sed -i -e 's?^UUID=.* / .*?LABEL=/boot     /boot           xfs    defaults,relatime  0   0?' /etc/fstab

# reorder console entries
sed -i 's/console=tty0/console=tty0 console=ttyS0,115200n8/' /boot/grub2/grub.cfg

# Clean up
yum clean all
rm -f /root/install.log
rm -f /root/install.log.syslog
find /var/log -type f -delete

%end
