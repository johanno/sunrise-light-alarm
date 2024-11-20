#!/bin/bash

if [ -z "$1" ]
then
    echo "Usage: ./install.sh remote_user@remote_host"
    echo "eg: ./install.sh pi@raspberrypi"
    exit 
fi

remote="$1"

#executed locally
echo "building flutter web"
cd flutter_app/ || exit
flutter build web
cd ..
echo "tar-ing project"
rm -f bundle.tar.gz
tar -zcvf bundle.tar.gz flutter_app/build/web GPIO_mosfet_control *.py sunrise* requirements.txt

echo "copying project to remote " $remote
scp bundle.tar.gz $remote:~/

echo "unpacking project on remote " $remote

# executed on remote (raspberry-pi)
ssh $remote '

mkdir -p sunrise
mv bundle.tar.gz sunrise
cd sunrise
tar -zxvf bundle.tar.gz
sudo apt-get install python3-pip vlc python3-vlc
sudo pip3 install -r requirements.txt

#
# systemd service
#
sudo cp sunrise.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable sunrise.service
sudo systemctl restart sunrise.service
'
