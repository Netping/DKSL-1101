#!/usr/bin/env bash
#v0.2 4d4441@gmail.com

if [ -f ver ]
then
  export $(cat ./ver | sed 's/#.*//g' | xargs)
else 
  echo "ver Environment fine not exist"
  exit 0
fi
apt update
apt install -y rsync cloud-image-utils isolinux xorriso mc netcat git

cd /tmp && rm -rf ./iso*
mkdir ./iso && chmod 777 ./iso

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
git clone git@github.com:Netping/DKSL-1101.git

rsync -vr /tmp/isogit/boot/iso/ ./iso/
rm -rf ./isogit

apt clean
apt install --download-only -y dksl-1101 ubnt-1101-dc-source ubnt-1101-dc-voltmeter-ampermeter ubnt-1101-discrete-in ubnt-1101-panel ubnt-1101-relays 
cp /var/cache/apt/archives/*.deb ./iso/netping/deb/updates/

apt clean
apt install --download-only -y python3.10
cp /var/cache/apt/archives/*.deb ./iso/netping/deb/python/

VERSION=$MAJOR_VERSION.$MINOR_VERSION-$PATH_VERSION-$BUILD_VERSION$(date '+%Y-%m-%dT%H:%M:%S')
echo $VERSION > ./iso/netping/np_version

mv ./iso/ubuntu ./
cd ./iso/; find '!' -name "md5sum.txt" '!' -path "./isolinux/*" -follow -type f -exec "$(which md5sum)" {} ; > ../md5sum.txt
cd .. ; mv ./md5sum.txt ./iso/ ; mv ./ubuntu ./iso/

#combine to bootable iso 
xorriso -as mkisofs -r   -V Ubuntu\ NetpingZabbix   -o DKSL1101.$VERSION.iso   -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot   -boot-load-size 4 -boot-info-table   -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot   -isohybrid-gpt-basdat -isohybrid-apm-hfsplus   -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin    iso/boot iso

