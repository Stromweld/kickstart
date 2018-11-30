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
repo --name="openlogic" --baseurl=http://olcentgbl.trafficmanager.net/openlogic/7/openlogic/x86_64/

rootpw  --iscrypted $6$ilihUFZO06brTJkm$BzgKcXqlehkKF6dQSzE7I.Wf6vKmIZmB3N6NA7MV99DFNDVkibYvL8D9dH78YUeDipOODswj6RBzZJ0ox0rD60
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
part pv.1015 --fstype="lvmpv" --ondisk=sda --size=29695
part /boot --fstype="xfs" --ondisk=sda --size=1024 --label=boot
volgroup vg_root --pesize=4096 pv.1015
logvol /var/log  --fstype="xfs" --size=2048 --name=lv_varlog --vgname=vg_root
logvol /tmp  --fstype="xfs" --size=4096 --name=lv_tmp --vgname=vg_root
logvol swap  --fstype="swap" --size=4096 --name=lv_swap --vgname=vg_root
logvol /  --fstype="xfs" --size=15360 --name=lv_root --vgname=vg_root --grow
shutdown

%packages --ignoremissing --nobase
@^minimal
@base
@console-internet
WALinuxAgent
chrony
cifs-utils
hypervkvpd
parted
python-pyasn1
sudo
epel-release
nano
centos-release-scl
centos-release-scl-rh
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
binutils
microsoft-hyper-v
kmod-microsoft-hyper-v
make
kernel
kernel-headers
kernel-devel
librdmacm-devel
libmnl-devel
tuned-utils
tuned
numad
numactl-devel.x86_64
tuna
mlocate
xfsprogs-devel

-dracut-config-rescue
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

# Disable the root account
usermod root -p '!!'

# Enable tmpfs /tmp mount
systemctl enable tmp.mount

# Import CentOS and OpenLogic public keys
curl -so /etc/pki/rpm-gpg/OpenLogic-GPG-KEY https://raw.githubusercontent.com/szarkos/AzureBuildCentOS/master/config/OpenLogic-GPG-KEY
rpm --import /etc/pki/rpm-gpg/OpenLogic-GPG-KEY

# Set the kernel cmdline
sed -i 's/^\(GRUB_CMDLINE_LINUX\)=".*"$/\1="console=tty1 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 rootdelay=300 net.ifnames=0"/g' /etc/default/grub

# Enable grub serial console
echo 'GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"' >> /etc/default/grub
sed -i 's/^GRUB_TERMINAL_OUTPUT=".*"$/GRUB_TERMINAL="serial console"/g' /etc/default/grub

# Blacklist the nouveau driver
cat << EOF > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

# Install DPDK dependancies
yum -y groupinstall "Infiniband Support"
dracut --add-drivers "mlx4_en mlx4_ib mlx5_ib" -f

# download dpdk
wget https://fast.dpdk.org/rel/dpdk-18.05.1.tar.xz
tar xzf dpdk-18.05.1.tar.xz
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

# Ensure WALinuxAgent auto update enabled
sed -i 's/# AutoUpdate.Enabled=n/AutoUpdate.Enabled=y/g' /etc/waagent.conf

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

# Disable NetworkManager handling of the SRIOV interfaces
curl -so /etc/udev/rules.d/68-azure-sriov-nm-unmanaged.rules https://raw.githubusercontent.com/LIS/lis-next/master/hv-rhel7.x/hv/tools/68-azure-sriov-nm-unmanaged.rules

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

sed -i -e 's/\(preserve_hostname:\).*/\1 False/' /etc/cloud/cloud.cfg
sed -i '/HOSTNAME/d' /etc/sysconfig/network
rm /etc/hostname

# Clean up
yum clean all
rm -f /root/install.log
rm -f /root/install.log.syslog
find /var/log -type f -delete

# Deprovision and prepare for Azure
/usr/sbin/waagent -force -deprovision
rm -f /etc/resolv.conf 2>/dev/null # workaround old agent bug

%end
