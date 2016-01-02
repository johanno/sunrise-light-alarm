from flask import Flask, request, session, redirect, url_for, escape, Session, make_response, jsonify, send_from_directory

import os, sys, os.path
import functools
import urllib, urllib2
import time
from dateutil import parser
import traceback
import config
from alarm import *
import logging
from ledstrip_bootstrap import * 

WEEKDAYS = {"Mo": 0, "Tu": 1, "We": 2, "Th": 3, "Fr": 4, "Sa": 5, "Su": 6}

app = Flask(__name__)
led.all_off() 

def main():
    app.alarm = None

    app.debug = config.debug 
    app.secret_key = config.secretKey 
    app.statePath = config.statePath
    if os.path.exists(app.statePath): 
        try :
            app.alarm = Alarm.fromFile(app.statePath)
        except Exception as e:
            os.remove(app.statePath)
            print("Cannot read app-state from "+ app.statePath, e)
        
    print("Starting with alarm", str(app.alarm))
    if app.alarm is not None: 
        app.alarm.start()
    app.run(host=config.host, port=config.port, threaded=config.threaded)

def with_login(f):
    @functools.wraps(f)
    def wrapper(*args, **kwds):
        if not "username" in session:
            return json.dumps({"status": "error", "message": "Please log in."})
        request.username = session["username"]
        return f(*args, **kwds)
    return wrapper

@app.route("/<path:path>")
def static_content(path):
    return send_from_directory('public/', path)

@app.route("/")
def redirct_to_main():
    return send_from_directory('public/', "index.html")

@app.route("/set")
def set():
    args = request.args
    print("set request-args", args)
    date_time = parser.parse(args["time"])
    daysOfWeek =  [WEEKDAYS[x] for x in args if x in WEEKDAYS]


    if app.alarm is None: 
        app.alarm = Alarm(date_time, daysOfWeek)
        app.alarm.start()
    else: 
        app.alarm.timeOfDay = date_time
        app.alarm.daysOfWeek =daysOfWeek

    on()
    time.sleep(5)
    off()

    #serialize updated state
    print("Updating state-file ", app.statePath, "with alarm", str(app.alarm), "daysOfWeek", daysOfWeek)
    app.alarm.toFile(app.statePath)

    return jsonify({"status": "OK"}) 

@app.route("/test")
def test():
    print("testing...")
    anim = Wave(led, Color(255, 0, 0), 4)
    for i in range(led.lastIndex):
	anim.step()
	led.update()
    led.all_off() 
    return jsonify({"status": "OK"}) 

@app.route("/on")
def on():
    level = 1.0

    if "level" in request.args: level = float(request.args["level"])

    print("turning on with brightness", level)
    led.fill(Color(255, 255, 255, level))
    led.update()
    return jsonify({"status": "OK"}) 

@app.route("/off")
def off():
    print("turning off...")
    led.all_off()
    return jsonify({"status": "OK"}) 

if __name__ == "__main__":
    main()
