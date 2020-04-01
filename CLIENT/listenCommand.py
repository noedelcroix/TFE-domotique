#!/usr/bin/python3
#-*- coding: utf-8 -*-

import socket, homeControl, json
from pathlib import Path

connection = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

connection.bind(("", 85))

while True:
    dataRecev, addr = connection.recvfrom(1024)
    try:
        dataRecev = eval(str(dataRecev, "utf8"))

        print(dataRecev["command"])
        dataLocal = homeControl.getData()

        if dataRecev["command"].lower() == "set":
            dataLocal[dataRecev["key"]] = dataRecev["value"]

        config = open(str(Path(__file__).parent.absolute())+"/configHomeControl.json", "w+")
        config.write(json.dumps(dataLocal))
        config.close()
    except:
        continue

