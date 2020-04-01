#!/usr/bin/python3
#-*- coding: utf-8 -*-

import socket, time, homeControl, json

connection = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

while True:
    try:
        if homeControl.findGateway():
            byte = json.dumps(homeControl.getData()).encode("utf8")
            connection.sendto(byte, (homeControl.findGateway(), 85))
            time.sleep(1)
    except:
        continue