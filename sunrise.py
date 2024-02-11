import functools
import os
import os.path
import sys
import time
import json

from dateutil.parser import parser
from flask import Flask, request, session, jsonify, send_from_directory

import config
from alarm import TimesOfWeek, EMPTY_TIMES_OF_WEEK, Alarm
from GPIO_mosfet_control.led_light import power_off, all_off

WEEKDAYS = {"Mo": 0, "Tu": 1, "We": 2, "Th": 3, "Fr": 4, "Sa": 5, "Su": 6}
WEEKDAYS_REVERSE = {v: k for (k, v) in WEEKDAYS.items()}

app = Flask(__name__)
power_off()
all_off()
# led.all_off()


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
    level = 1.0

    if "level" in request.args:
        level = float(request.args["level"])

    print("turning on with brightness", level)
    # led.fill(Color(255, 255, 255, level))
    # led.update()
    return jsonify({"status": "OK"})


@app.route("/off")
def off():
    print("turning off...")
    # led.all_off()
    return jsonify({"status": "OK"})


def flash(count=3, delay=0.5):
    print("flashing...")
    for _ in range(count):
        on()
        time.sleep(delay)
        off()
        time.sleep(delay)


@app.route("/stat")
def stat():
    stat = {}
    status = "None"
    if app.alarm.days_of_week:
        stat = json.loads(repr(app.alarm))
        # prettify
        stat["time"] = parser.parse(stat["time"]).strftime("%H:%M")
        stat["weekdays"] = [WEEKDAYS_REVERSE[x] for x in stat["weekdays"]]
        status = "OK"
    return jsonify({"status": status, "stat": stat})


@app.route("/set")
def set():
    args = request.args
    print("set request-args", args)
    date_time = parser.parse(args["time"])
    days_of_week = [WEEKDAYS[x] for x in args if x in WEEKDAYS]
    app.alarm.times_of_week = TimesOfWeek(date_time, days_of_week)
    flash()
    # serialize updated state
    print("Updating state-file ", app.statePath, "with alarm", app.alarm, "daysOfWeek", days_of_week)
    app.alarm.to_file(app.statePath)
    return jsonify({"status": "OK"})


@app.route("/reset")
def reset():
    app.alarm.times_of_week = EMPTY_TIMES_OF_WEEK
    if os.path.exists(app.statePath):
        try:
            os.remove(app.statePath)
        except OSError as e:
            print("Could not remove", app.statePath, "due to", sys.exc_info())
    flash()
    return jsonify({"status": "OK"})


def main():
    app.secret_key = config.secretKey
    app.statePath = config.statePath
    app.alarm = Alarm()
    if os.path.exists(app.statePath):
        try:
            app.alarm = Alarm.from_file(app.statePath)
        except Exception as e:
            os.remove(app.statePath)
            print("Cannot read app-state from " + app.statePath, e)

    print("Starting with alarm", str(app.alarm))
    app.alarm.start()
    app.run(host=config.host, port=config.port, threaded=config.threaded)


if __name__ == "__main__":
    main()
