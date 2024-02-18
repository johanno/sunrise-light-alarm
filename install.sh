#!/bin/bash

if [ -z "$1" ]
then
    echo "Usage: ./install.sh remote_user@remote_host"
    echo "eg: ./install.sh pi@raspberrypi"
    exit 
fi

remote=$1

#executed locally
echo "building flutter web"
cd flutter_app/ || exit
flutter build web
cd ..
echo "tar-ing project"
rm -f bundle.tar.gz
tar -zcvf bundle.tar.gz flutter_app/build/web GPIO_mosfet_control *.py sunrise requirements.txt

echo "copying project to remote " $1
scp bundle.tar.gz $1:~/

echo "unpacking project on remote " $1

#executed on remote (raspberry-pi)
ssh $1 '
sudo apt-get install python3-pip

mkdir -p sunrise
mv bundle.tar.gz sunrise
cd sunrise
tar -zxvf bundle.tar.gz
sudo pip3 install -r requirements.txt

#
#sys-v-init service
#
chmod +x sunrise
sudo cp sunrise /etc/init.d
sudo update-rc.d sunrise defaults
echo "rebooting remote"
sudo reboot

'
