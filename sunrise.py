import datetime
import functools
import os
import os.path
import shutil
import sys
import time
import json

from dateutil import parser
from flask import Flask, request, session, jsonify, send_from_directory
from flask_cors import CORS

import config
from GPIO_mosfet_control.dimm_light import select_res_by_percent
from alarm import TimesOfWeek, EMPTY_TIMES_OF_WEEK, Alarm, AlarmList
from GPIO_mosfet_control.led_light import power_off, all_off, power_on

WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
WEEKDAYS_REVERSE = WEEKDAYS.copy()
WEEKDAYS_REVERSE.reverse()

app = Flask(__name__, static_folder='public/static')
CORS(app)  # Enable CORS for all routes
app.alarmList: AlarmList = None

power_off()
all_off()


def with_login(f):
    @functools.wraps(f)
    def wrapper(*args, **kwds):
        if "username" not in session:
            return json.dumps({"status": "error", "message": "Please log in."})
        request.username = session["username"]
        return f(*args, **kwds)

    return wrapper


@app.route("/<path:path>")
def static_content(path):
    return send_from_directory('public/', path)


@app.route("/")
def redirect_to_main():
    return send_from_directory('public/', "index.html")


@app.route("/on")
def on():
    level = 100

    if "brightness" in request.args:
        level = int(request.args.get("brightness"))

    print("turning on with brightness", level)
    select_res_by_percent(level)
    power_on()
    return jsonify({"status": "OK"})


@app.route("/off")
def off():
    print("turning off...")
    power_off()
    all_off()
    return jsonify({"status": "OK"})


@app.route("/list_music_files")
# @with_login  # Decorate with the login check if needed
def list_music_files():
    music_folder = "/home/johannes/Musik/"  # Adjust the path to your music folder

    # Get a list of all files in the music folder
    music_files = [f for f in os.listdir(music_folder) if os.path.isfile(os.path.join(music_folder, f))]
    print(music_files)
    # Return the list as JSON
    return jsonify({"status": "OK", "music_files": music_files})


@app.route("/get_alarms")
def get_alarms():
    state_path = config.statePath

    # Attempt to load the alarm from the state file
    alarm = AlarmList.from_file(state_path)
    alarm_json = []
    # Prettify each alarm
    for a in alarm.alarms:
        a = a.to_json()
        a["time_of_day"] = parser.parse(a["time_of_day"]).strftime("%H:%M")
        # a["days_of_week"] = [WEEKDAYS_REVERSE[x] for x in a["days_of_week"]]
        alarm_json.append(a)
    status = "OK"
    ret = jsonify({"status": status, "alarms": alarm_json})
    print("get_alarms: ", ret.data)
    return ret


@app.route("/update_alarm")
def update_alarm():
    data = request.args
    print("update_alarm request-args: ", data)
    # Extract alarm data from the JSON payload
    alarm_time = parser.parse(data.get("time_of_day"))
    alarm_days = data.get("days_of_week")
    alarm_id = int(data.get("alarm_id"))
    enabled = bool(data.get("enabled"))
    print("days", alarm_days)
    alarm_days = alarm_days.split(",")
    # validate days
    if not set(alarm_days).issubset(set(WEEKDAYS)):
        print(f"ERROR: {alarm_days} not in {WEEKDAYS}")
        return jsonify({"status": "error",
                        "message": f"alarm_days '{alarm_days}' is not subset of week days: {WEEKDAYS}"})
    alarm_music = str(data.get("music"))
    # Create a new alarm instance and configure it
    new_alarm = Alarm(music=alarm_music, enabled=enabled)
    new_alarm.times_of_week = TimesOfWeek(alarm_time, alarm_days)

    # Add the new alarm to the list of alarms
    app.alarmList.update_alarm(new_alarm, alarm_id)

    # Serialize updated state
    app.alarmList.to_file(app.statePath)

    return jsonify({"status": "OK"})


@app.route("/add_alarm")
def add_alarm():
    data = request.args
    print("add_alarm request-args: ", data)
    # Extract alarm data from the JSON payload
    alarm_time = parser.parse(data.get("time_of_day"))
    alarm_days = data.get("days_of_week")
    # print("days", alarm_days)
    alarm_days = alarm_days.split(",")
    # validate days
    if not set(alarm_days).issubset(set(WEEKDAYS)):
        print(f"ERROR: {alarm_days} not in {WEEKDAYS}")
        return jsonify({"status": "error",
                        "message": f"alarm_days '{alarm_days}' is not subset of week days: {WEEKDAYS}"})
    alarm_music = data.get("music")
    # Create a new alarm instance and configure it
    new_alarm = Alarm(music=alarm_music)
    new_alarm.times_of_week = TimesOfWeek(alarm_time, alarm_days)

    # Add the new alarm to the list of alarms
    app.alarmList.add_alarm(new_alarm)

    # Serialize updated state
    app.alarmList.to_file(app.statePath)

    return jsonify({"status": "OK"})


@app.route("/reset")
def reset():
    data = request.args
    id = data.get("alarm_id")
    app.alarmList.remove_alarm(id)
    app.alarmList.to_file(app.statePath)
    return jsonify({"status": "OK"})


def main():
    app.secret_key = config.secretKey
    app.statePath = config.statePath

    app.alarmList = AlarmList()
    if os.path.exists(app.statePath):
        try:
            app.alarmList = AlarmList.from_file(app.statePath)
        except Exception as e:
            # Copy backup
            backup_path = f"{app.statePath}.backup_{datetime.datetime.now().isoformat()}"
            shutil.copy2(app.statePath, backup_path)
            os.remove(app.statePath)
            print("Cannot read app-state from " + app.statePath, e)
            print("Creating a new one! ")
            app.alarmList.to_file(app.statePath)
    else:
        app.alarmList.to_file(app.statePath)

    print("Starting with alarms", str(app.alarmList.alarms))
    app.alarmList.start()
    if config.debug:
        app.config['TEMPLATES_AUTO_RELOAD'] = True
        app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0
    app.run(host=config.host, port=config.port, threaded=config.threaded, debug=config.debug)


if __name__ == "__main__":
    main()
