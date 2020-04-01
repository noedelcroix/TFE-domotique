from gpiozero import LEDBoard
import homeControl
from time import sleep

while True:
    try:
        data = homeControl.getData()
        type0=[[],[]]
        type1=[]
        global leds

        for pin in data["pins"]:
            if pin["type"] == 0:
                type0[0].append(pin["number"])
                type0[1].append(pin["value"])
            elif pin["type"] == 1:
                type1.append(pin["number"])

        if len(type0[0]) != 0:
            if "leds" not in globals():
                leds = LEDBoard(*type0[0], pwm=True)
                print("there wasn't leds")
            else:
                ledsUsed = []
                for led in leds.leds:
                    ledsUsed.append(int(str(led.pin).replace("GPIO", "")))

                if not set(ledsUsed) == set(type0[0]):
                    print("num PIN changed")
                    leds.close()
                    leds = LEDBoard(*type0[0], pwm=True)
            if leds.value != tuple(type0[1]):
                leds.value = tuple(type0[1])
                print("change")
        elif "leds" in globals():
            leds.close()
            del leds
            print("All pins deleted")
    except:
        continue
