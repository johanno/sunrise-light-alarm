# Sunrise Alarm
forked from cboddy/sunrise-light-alarm

A [Flask](https://pypi.python.org/pypi/Flask) web-service for controlling a home brew dimmable LED light via relays with a raspberry-pi via a [Flutter](https://flutter.dev/) web-app.

For port 80 to work on pi you can remove the privileged ports:
```bash
#save configuration permanently
sudo nano /etc/sysctl.d/50-unprivileged-ports.conf
# and add this line 
'net.ipv4.ip_unprivileged_port_start=80'
#apply conf
sudo sysctl --system
```
This will make every port beginning with 80 able to be bind by any user. Shouldn't be a problem on a pi.

## Setup

My setup uses a MOSFET from [amazon](https://www.amazon.de/gp/product/B075QFQN7S/) 
that controls the frequency of a LED 230v light bulb.
![Mosfet](images/mosfet.png)

The potentiometer is replaced by relays, controlled by the pi, switching on and of resistors.

[//]: # (TODO image of my setup.)

The GPIO_mosfet_control folder controls those relays. It calculates the resistance and then switches on the
needed relays.

This setup was for learning experience. If you want to use this MOSFET then a stepper motor controlling the
potentiometer is probably easier. Or even more reasonable would be to use an USB powered
dimmable LED.




