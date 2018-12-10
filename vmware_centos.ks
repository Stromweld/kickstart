skipx
text
install
url --url=http://mirror.centos.org/centos/7/os/x86_64/
# Firewall configuration
firewall --disabled --ssh --service=ssh
eula --agreed
#vnc --password=Root1234! --port=5500

repo --name=centos-base --baseurl=http://mirror.centos.org/centos/7/os/x86_64/
repo --name=centos-updates --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/
repo --name=centos-extras --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/
#repo --name=centos-centosplus --baseurl=http://mirror.centos.org/centos/7/centosplus/x86_64/
repo --name=centos-fasttrack --baseurl=http://mirror.centos.org/centos/7/fasttrack/x86_64/
repo --name=centos-sclo --baseurl=http://mirror.centos.org/centos/7/sclo/x86_64/sclo/
repo --name=centos-sclo-rh --baseurl=http://mirror.centos.org/centos/7/sclo/x86_64/rh/
repo --name=centos-epel --baseurl=http://download.fedoraproject.org/pub/epel/7/x86_64/
#repo --name=centos-spacewalk-client --baseurl=http://yum.spacewalkproject.org/2.6-client/RHEL/7/x86_64/
#repo --name="openlogic" --baseurl=http://olcentgbl.trafficmanager.net/openlogic/7/openlogic/x86_64/

rootpw  Root1234!
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
timezone America/Chicago --isUtc
# Network information
network  --bootproto=dhcp --activate
network  --hostname=localhost.localdomain

ignoredisk --only-use=sda
zerombr
# System bootloader configuration
bootloader --append="console=tty0" --location=mbr --timeout=1 --boot-drive=sda
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part /boot --fstype="xfs" --ondisk=sda --size=1024 --label=boot
part pv.1015 --fstype="lvmpv" --ondisk=sda --size=29695 --grow
volgroup vg_root --pesize=4096 pv.1015
logvol /var/log  --fstype="xfs" --size=2048 --name=lv_varlog --vgname=vg_root
logvol /tmp  --fstype="xfs" --size=4096 --name=lv_tmp --vgname=vg_root
logvol swap  --fstype="swap" --size=4096 --name=lv_swap --vgname=vg_root
logvol /  --fstype="xfs" --size=15360 --name=lv_root --vgname=vg_root --grow
shutdown

%packages --ignoremissing --nobase --nocore
@^minimal
realmd
oddjob
oddjob-mkhomedir
sssd
krb5-workstation
samba-common-tools
sssd-libwbclient
sssd-tools
wget
nfs-utils
chrony
cifs-utils
parted
epel-release
nano
centos-release-scl
centos-release-scl-rh
dstat
bash-completion
bash-completion-extras
htop
dkms
gcc
gcc-c++
binutils
open-vm-tools
make
kernel
kernel-headers
kernel-devel
tuned-utils
tuned
numad
numactl-devel
tuna
mlocate
xfsprogs-devel

-dracut-config-rescue
-Network*
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-biosdevname
-iprutils
-linux-firmware
-ivtv-firmware
-iwl*-firmware
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

# Enable tmpfs /tmp mount
systemctl enable tmp.mount

# Enable SSH keepalive
sed -i 's/^#\(ClientAliveInterval\).*$/\1 180/g' /etc/ssh/sshd_config


# Configure network
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
USERCTL=no
PEERDNS=yes
IPV6INIT=no
NM_CONTROLLED=no
PERSISTENT_DHCLIENT=yes
EOF

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
# Disable persistent net rules
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules /etc/udev/rules.d/70-persistent-net.rules 2>/dev/null

# Modify yum
echo "http_caching=packages" >> /etc/yum.conf
yum -C -y remove linux-firmware avahi\* Network\*
# Remove firewalld; it is required to be present for install/image building.
# but we dont ship it in cloud
yum -C -y remove firewalld --setopt="clean_requirements_on_remove=1"
yum clean all

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tuned/active-profile

# setup systemd to boot to the right runlevel
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# Fix some first boot issues
rpm --rebuilddb
touch /.autorelabel

# Fix hostname on boot
sed -i '/HOSTNAME/d' /etc/sysconfig/network
rm /etc/hostname

# reorder console entries
sed -i 's/^\(GRUB_CMDLINE_LINUX\)=".*"$/\1="console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0"/g' /etc/default/grub

# Rebuild the grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg

# Clean up
yum clean all
rm -f /root/install.log
rm -f /root/install.log.syslog
find /var/log -type f -delete

%end
