#!/bin/ash

cat >> /etc/sysctl.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF

sysctl -p

mkdir /media/setup
cp -a /media/sda/* /media/setup
 
mkdir /lib/setup
cp -a /.modloop/* /lib/setup

/etc/init.d/modloop stop
umount /dev/sda

mv /media/setup/* /media/sda/
mv /lib/setup/* /.modloop/

echo "READY!!!"

#For virtualbox 
#After setup-alpine 

mkdir /media/setup
cp -a /media/sda* /media/setup
 
mkdir /lib/setup
cp -a /.modloop/* /lib/setup

/etc/init.d/modloop stop
umount /dev/sda

mv /media/setup/* /media/sda*
mv /lib/setup/* /.modloop/

echo "Now start setup-disk!!!"
