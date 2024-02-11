import RPi.GPIO as GPIO

from GPIO_mosfet_control.relay_pin_list import *

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)


def all_off():
    for r in r_all:
        GPIO.setup(r, GPIO.IN)


def power_on():
    # TODO only set GPIO if it isn't already on
    print("gpio_fun: ", GPIO.gpio_function(on_off))
    GPIO.setup(on_off, GPIO.OUT)


def power_off():
    GPIO.setup(on_off, GPIO.IN)
