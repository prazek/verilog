import curses
import os
import usb1
import sys
from time import sleep
from adepttool.adepttool.device import get_devices

def main():
    with usb1.USBContext() as ctx:
        devs = get_devices(ctx)
        if not devs:
            print('No devices found.')
            sys.exit(1)
        dev = devs[0]
        dev.start()
        port = dev.depp_ports[0]
        port.enable()

        curses.wrapper(interact, port)

        port.disable()


k2c = {
    'KEY_RIGHT': 1,
    'KEY_UP': 2,
    'KEY_LEFT': 4,
    'KEY_DOWN': 8,
    ' ': 16,
    'b': 32,
    'v': 64,
    'r': 128
}

def interact(win, port):
    win.nodelay(True)
    key=""
    win.clear()                
    win.addstr("Detected key:")

    while 1:          
        try:                 
            key = win.getkey()
            win.clear()
            win.addstr("Detected key: ")
            k = str(key)
            win.addstr(k)

            if k in k2c:
                port.put_reg(0, [k2c[k]])
        except Exception:
           pass         

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass