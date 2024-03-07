import collections
import datetime
import json
import pathlib
import subprocess
import sys
import threading
import time
from dateutil import parser
from GPIO_mosfet_control.dimm_light import select_res_by_percent
from GPIO_mosfet_control.led_light import power_on

SECONDS_PER_MINUTE = 60
SECONDS_PER_DAY = SECONDS_PER_MINUTE * 60 * 24

TimesOfWeek = collections.namedtuple("WeekTimes", ["time_of_day", "days_of_week"])
EMPTY_TIMES_OF_WEEK = TimesOfWeek(datetime.datetime.now(), [])

music_process: subprocess.Popen = None
playing_music: bool = False


def play_music(music):
    music = f"/home/pi/Music/{music}"
    if music == "Default Music" or not pathlib.Path(music).exists():
        return "/home/pi/Music/Awaken.m4a"
    command = ["cvlc", music]
    global music_process
    music_process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    result = music_process.returncode
    # Check the result
    if result.returncode == 0:
        print("Command executed successfully")
        print("Output:", result.stdout)
        global playing_music
        playing_music = True
    else:
        print("Error executing command")
        print("Error:", result.stderr)


def stop_music():
    global music_process, playing_music
    if music_process is not None:
        music_process.terminate()
        # music_process.kill()
    playing_music = False


class AlarmList(threading.Thread):
    def __init__(self, delay=10):
        super(AlarmList, self).__init__()

        self.alarms = []
        self.delay = delay
        self._lock = threading.Lock()
        self.setDaemon(True)

    def add_alarm(self, alarm):
        with self._lock:
            self.alarms.append(alarm)

    def remove_alarm(self, alarm_id: int):
        with self._lock:
            self.alarms.pop(alarm_id)

    def to_json(self):
        alarms_repr = [alarm.to_json() for alarm in self.alarms]
        return json.dumps({"alarms": alarms_repr, "delay": self.delay})

    def run(self):
        while True:
            try:
                self.tick()
            except Exception as e:
                print(sys.exc_info()[0])
            finally:
                time.sleep(self.delay)

    # TODO make the alarm stop once it is ignored for 10 minutes.
    # TODO make sure that alarms don't interfere: do not allow alarms that are wake_up_minutes apart
    def tick(self):
        now = datetime.datetime.now()
        for alarm in self.alarms:
            # TODO maybe rather parse days of week to datetime so you have localization independent impl
            if not alarm.enabled or not now.strftime('%A') in alarm.days_of_week:
                continue
            delta: datetime.datetime = alarm.time_of_day - now
            print(f"delta: {delta}")
            print(f"delta2: {delta <= datetime.timedelta(0)}")
            delta_minutes = (delta.seconds % SECONDS_PER_DAY) / SECONDS_PER_MINUTE
            print(f"deltamin: {delta_minutes}")
            # TODO disable intensity when delta  <= timedelta(0)
            light_intensity = alarm.calculate_light_intensity(delta_minutes)
            global playing_music
            if not playing_music and delta < datetime.timedelta(0) and not delta < datetime.timedelta(minutes=-10):
                play_music(alarm.music)
            if light_intensity == 0:
                continue
            else:
                select_res_by_percent(light_intensity)
                power_on()

    def to_file(self, file_name):
        try:
            file_json = self.to_json()
            with open(file_name, "w") as f:
                f.write(file_json)
            print("written: ", file_json)
        except (PermissionError, IOError) as e:
            print(f"Error writing to file: {e}")

    @staticmethod
    def load(state_dict):
        alarm_list = AlarmList(delay=state_dict["delay"])
        for alarm_data in state_dict["alarms"]:
            times_of_week = TimesOfWeek(
                parser.parse(alarm_data["time_of_day"]),
                alarm_data["days_of_week"]
            )
            loaded_alarm = Alarm(
                times_of_week,
                alarm_data["wake_up_minutes"],
                alarm_data["grace"],
                alarm_data["music"],
                alarm_data["enabled"]
            )
            alarm_list.add_alarm(loaded_alarm)
        return alarm_list

    @staticmethod
    def from_file(file_path, recursive=False):
        with open(file_path, "r") as f:
            state_dict = json.load(f)
            return AlarmList.load(state_dict)

    def update_alarm(self, new_alarm, alarm_id):
        with self._lock:
            self.alarms[alarm_id] = new_alarm


class Alarm:
    def __init__(self, times_of_week=EMPTY_TIMES_OF_WEEK, wake_up_minutes=30, grace_minutes=10, music=None,
                 enabled=True):
        super(Alarm, self).__init__()

        self._times_of_week = times_of_week
        self.wake_up_minutes = float(wake_up_minutes)
        self.grace_minutes = grace_minutes
        self._enabled = enabled
        self.music = music

    @property
    def enabled(self):
        return self._enabled

    @enabled.setter
    def enabled(self, enabled: bool):
        self._enabled = enabled

    @property
    def time_of_day(self):
        return self.times_of_week.time_of_day

    @property
    def days_of_week(self):
        return self.times_of_week.days_of_week

    @property
    def times_of_week(self):
        return self._times_of_week

    @times_of_week.setter
    def times_of_week(self, times_of_week):
        self._times_of_week = times_of_week

    def calculate_light_intensity(self, remaining_minutes: float):
        if remaining_minutes > self.wake_up_minutes:
            return 0
        elif remaining_minutes < 0:
            return 100
        else:
            return int((1 - (remaining_minutes / self.wake_up_minutes)) * 100)

    def to_json(self):
        return {
            "time_of_day": self.time_of_day.isoformat(),
            "days_of_week": self.days_of_week,
            "grace": self.grace_minutes,
            "wake_up_minutes": self.wake_up_minutes,
            "music": self.music,
            "enabled": self.enabled
        }

    def __repr__(self):
        return str(self.to_json())
