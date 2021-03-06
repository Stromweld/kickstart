skipx
text
install
url --url=http://mirror.centos.org/centos/7/os/x86_64/
# Firewall configuration
firewall --disabled --ssh --service=ssh
eula --agreed
#vnc --password=Root1234! --port=5500

repo --name=centos-base --baseurl=http://olcentgbl.trafficmanager.net/centos/7/os/x86_64/
repo --name=centos-updates --baseurl=http://olcentgbl.trafficmanager.net/centos/7/updates/x86_64/
repo --name=centos-extras --baseurl=http://olcentgbl.trafficmanager.net/centos/7/extras/x86_64/
#repo --name=centos-centosplus --baseurl=http://olcentgbl.trafficmanager.net/centos/7/centosplus/x86_64/
repo --name=centos-fasttrack --baseurl=http://mirror.centos.org/centos/7/fasttrack/x86_64/
repo --name=centos-sclo --baseurl=http://mirror.centos.org/centos/7/sclo/x86_64/sclo/
repo --name=centos-sclo-rh --baseurl=http://mirror.centos.org/centos/7/sclo/x86_64/rh/
repo --name=centos-epel --baseurl=http://download.fedoraproject.org/pub/epel/7/x86_64/
#repo --name=centos-spacewalk-client --baseurl=http://yum.spacewalkproject.org/2.6-client/RHEL/7/x86_64/
repo --name="openlogic" --baseurl=http://olcentgbl.trafficmanager.net/openlogic/7/openlogic/x86_64/

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
bootloader --append="console=tty1 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 rootdelay=300 net.ifnames=0" --location=mbr --timeout=1 --boot-drive=sda
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part /boot --fstype="xfs" --ondisk=sda --size=1024 --label=boot
part pv.1015 --fstype="lvmpv" --ondisk=sda --size=29695 --grow
volgroup vg_root --pesize=4096 pv.1015
logvol /var/log  --fstype="xfs" --size=2048 --name=lv_varlog --vgname=vg_root --fsoptions="nobarrier,nofail"
logvol /tmp  --fstype="xfs" --size=4096 --name=lv_tmp --vgname=vg_root --fsoptions="nobarrier,nofail"
logvol /  --fstype="xfs" --size=15360 --name=lv_root --vgname=vg_root --grow --fsoptions="nobarrier,nofail"
reboot

%packages --ignoremissing --nobase
@^minimal
ncdu
WALinuxAgent
hyperv-daemons
udftools
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
net-tools
kernel
kernel-headers
kernel-devel
tuned-utils
tuned
numad
numactl-devel
librdmacm-devel
libmnl-devel
tuna
mlocate
xfsprogs-devel

-dracut-config-rescue
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

# Add openlogic repo
cat << EOF > /etc/yum.repos.d/openlogic.repo
[openlogic]
name=CentOS-7 - openlogic packages for x86_64
baseurl=http://olcentgbl.trafficmanager.net/openlogic/7/openlogic/x86_64/
enabled=1
gpgcheck=0
EOF

# Import CentOS and OpenLogic public keys
curl -so /etc/pki/rpm-gpg/OpenLogic-GPG-KEY https://raw.githubusercontent.com/szarkos/AzureBuildCentOS/master/config/OpenLogic-GPG-KEY
rpm --import /etc/pki/rpm-gpg/OpenLogic-GPG-KEY

# Set the kernel cmdline
sed -i 's/^\(GRUB_CMDLINE_LINUX\)=".*"$/\1="console=tty1 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 rootdelay=300 net.ifnames=0 biosdevname=0"/g' /etc/default/grub

# Enable grub serial console
echo 'GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"' >> /etc/default/grub
sed -i 's/^GRUB_TERMINAL_OUTPUT=".*"$/GRUB_TERMINAL="serial console"/g' /etc/default/grub

# Disable recovery
echo 'GRUB_DISABLE_RECOVERY="true"' >> /etc/default/grub

# Blacklist the nouveau driver
cat << EOF > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

# Install DPDK dependancies
yum -y groupinstall "Infiniband Support"
yum install -y microsoft-hyper-v
dracut --add-drivers "mlx4_en mlx4_ib mlx5_ib" -f -v

# Add Hyper-V drivers to dracut
dracut --add-drivers "hv_vmbus hv_netvsc hv_storvsc" -f -v

# download dpdk
wget https://fast.dpdk.org/rel/dpdk-19.02.tar.xz
tar xzf dpdk-19.02.tar.xz
cd dpdk*
make config T=x86_64-native-linuxapp-gcc
sed -ri 's,(MLX._PMD=)n,\1y,' build/.config
make
make install

# Configure dpdk runtime environment
echo 1024 | tee /sys/devices/system/node/node*/hugepages/hugepages-2048kB/nr_hugepages
mkdir /mnt/huge
mount -t hugetlbfs nodev /mnt/huge
grep Huge /proc/meminfo
modprobe -a ib_uverbs
echo 'modprobe -a ib_uverbs' >> /etc/rc.local

# Rebuild grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg

# Enable SSH keepalive
sed -i 's/^#\(ClientAliveInterval\).*$/\1 180/g' /etc/ssh/sshd_config

# Ensure WALinuxAgent auto update enabled and use resource drive for swap
sed -i 's/.*AutoUpdate.Enabled=.*$/AutoUpdate.Enabled=y/g' /etc/waagent.conf
sed -i 's/.*ResourceDisk.Filesystem=.*$/ResourceDisk.Filesystem=xfs/g' /etc/waagent.conf
sed -i 's/.*ResourceDisk.EnableSwap=.*$/ResourceDisk.EnableSwap=y/g' /etc/waagent.conf
sed -i 's/.*ResourceDisk.SwapSizeMB=.*$/ResourceDisk.SwapSizeMB=4096/g' /etc/waagent.conf
sed -i 's/,*ResourceDisk.MountOptions=.*$/ResourceDisk.MountOptions=nobarrier,noatime,nofail/g' /etc/waagent.conf

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
EOF

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
# Disable persistent net rules
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules /etc/udev/rules.d/70-persistent-net.rules 2>/dev/null

# Disable NetworkManager handling of the SRIOV interfaces
curl -so /etc/udev/rules.d/68-azure-sriov-nm-unmanaged.rules https://raw.githubusercontent.com/LIS/lis-next/master/hv-rhel7.x/hv/tools/68-azure-sriov-nm-unmanaged.rules

# Modify yum
echo "http_caching=packages" >> /etc/yum.conf
yum -C -y remove linux-firmware
yum clean all

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tuned/active-profile

# setup systemd to boot to the right runlevel
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .


sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

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
sed -i '/HOSTNAME/d' /etc/sysconfig/network
rm /etc/hostname

# Start WALinuxAgent on boot up
systemctl enable waagent

# Clean up
yum clean all
rm -f /root/install.log
rm -f /root/install.log.syslog
find /var/log -type f -delete

# Deprovision and prepare for Azure
#/usr/sbin/waagent -force -deprovision
#export HISTSIZE=0

%end
