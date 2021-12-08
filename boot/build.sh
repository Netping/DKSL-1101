#!/usr/bin/env bash
#v0.2 4d4441@gmail.com

if [ -f ver ]
then
  export $(cat ./ver | sed 's/#.*//g' | xargs)
else 
  echo "ver Environment fine not exist"
  exit 0
fi

cd /tmp && rm -rf /tmp/iso*
mkdir /tmp/iso && chmod 777 /tmp/iso

apt install -y rsync cloud-image-utils isolinux xorriso mc netcat git
wget http://repo.ubnt.netping.ru/DKSL-1101_0.1.deb
dpkg -i ./DKSL-1101_0.1.deb
add-apt-repository ppa:deadsnakes/ppa
apt update

#mount if iso exist and download & mount iso if not exist   
if [ -f $(basename -- $UBUNTU_ISO) ]
then
  mount ./$(basename -- $UBUNTU_ISO) /mnt
else
  wget $UBUNTU_ISO
  mount ./$(basename -- $UBUNTU_ISO) /mnt
fi

rsync -av --progress /mnt/ ./iso/

#clone repo with configs and sync with iso
git clone git@github.com:Netping/DKSL-1101.git /tmp/isogit

rsync -vr /tmp/isogit/boot/iso/ /tmp/iso/
rm -rf /tmp/isogit

#dksl-1101
apt clean
apt install --download-only -y dksl-1101 ubnt-1101-relays ubnt-1101-panel ubnt-1101-discrete-in ubnt-1101-dc-voltmeter-ampermeter ubnt-1101-dc-source
cp /var/cache/apt/archives/*.deb ./iso/netping/deb/updates/

#python 3.10
apt clean
apt install --download-only -y python3.10
cp /var/cache/apt/archives/*.deb ./iso/netping/deb/python/

VERSION=$MAJOR_VERSION.$MINOR_VERSION-$BUILD_VERSION$(date '+%Y-%m-%dT%H:%M:%S')
echo $VERSION > ./iso/netping/np_version

mv ./iso/ubuntu ./
cd ./iso/; find '!' -name "md5sum.txt" '!' -path "./isolinux/*" -follow -type f -exec "$(which md5sum)" {} ; > ../md5sum.txt
cd .. ; mv ./md5sum.txt ./iso/ ; mv ./ubuntu ./iso/

#combine to bootable iso 
xorriso -as mkisofs -r   -V Ubuntu\ NetpingZabbix   -o DKSL1101.$VERSION.iso   -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot   -boot-load-size 4 -boot-info-table   -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot   -isohybrid-gpt-basdat -isohybrid-apm-hfsplus   -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin    iso/boot iso

