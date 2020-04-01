import subprocess, re, json
from pathlib import Path

def getData():
    try:
        return json.load(open(str(Path(__file__).parent.absolute())+'/configHomeControl.json'))
    except:
        pass

def findGateway():
    routes = subprocess.check_output(["ip", "route"]).splitlines()
    for route in routes:
        if "default" in str(route):
            return re.search(r"([0-9]{1,3}[\.]){3}[0-9]{1,3}", str(route)).group()
    return False

def isInt(value):
  try:
    int(value)
    return True
  except:
    return False