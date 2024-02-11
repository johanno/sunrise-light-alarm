import RPi.GPIO as GPIO

from GPIO_mosfet_control.relay_pin_list import *

GPIO.setwarnings(False)


def select_res_by_percent(percent: int):
    """ sets the resistance by percent of min and max resistance"""
    min_r = 130
    max_r = 600
    r_by_percent: int = round(((max_r - min_r)/100) * percent) + min_r
    create_res_by_number(r_by_percent)


def create_res_by_number(resistance: int):
    """ sets the resistance of the mosfet as close as possible to the given
        @param resistance in k"""
    print(f"resistance: {resistance}k")

    resistance = round(resistance / 10)
    res_list = []
    if resistance < 10:
        add_10k_pins(resistance, res_list)
    elif resistance > 60:
        print("Can't create such high resistance")
        exit(-1)
    else:
        resistances = list(str(resistance))
        add_10k_pins(int(resistances[1]), res_list)
        add_100k_pins(int(resistances[0]), res_list)

    # print(f"selected pins: {res_list}")
    GPIO.setmode(GPIO.BCM)
    # TODO get a list of set and not set GPIOs and then only change the diff
    for pin in r_all:
        GPIO.setup(pin, GPIO.OUT)
    for pin in res_list:
        GPIO.setup(pin, GPIO.IN)


def add_100k_pins(res, res_list):
    if res == 1:
        res_list.append(r_100_k)
    elif res == 2:
        res_list.append(r_100_k)
        res_list.append(r_100_k_2)
    elif res == 3:
        res_list.append(r_300_k)
    elif res == 4:
        res_list.append(r_300_k)
        res_list.append(r_100_k)
    elif res == 5:
        res_list.append(r_300_k)
        res_list.append(r_100_k)
        res_list.append(r_100_k_2)
    elif res == 6:
        res_list.extend(r_all)


def add_10k_pins(res, res_list):
    if res == 1:
        res_list.append(r_10_k)
    elif res == 2:
        res_list.append(r_10_k)
        res_list.append(r_10_k_2)
    elif res == 3:
        res_list.append(r_20_k)
        res_list.append(r_10_k)
    elif res == 4:
        res_list.append(r_20_k)
        res_list.append(r_10_k)
        res_list.append(r_10_k_2)
    elif res == 5:
        res_list.append(r_50_k)
    elif res == 6:
        res_list.append(r_50_k)
        res_list.append(r_10_k)
    elif res == 7:
        res_list.append(r_50_k)
        res_list.append(r_20_k)
    elif res == 8:
        res_list.append(r_50_k)
        res_list.append(r_20_k)
        res_list.append(r_10_k)
    elif res == 9:
        res_list.append(r_50_k)
        res_list.append(r_20_k)
        res_list.append(r_10_k)
        res_list.append(r_10_k_2)
