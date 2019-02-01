#!/usr/bin/env python3

import sys
import usb1
from adepttool.device import get_devices
import time

W = 320
H = 200
B = 256

with usb1.USBContext() as ctx:
    devs = get_devices(ctx)
    if not devs:
        print('No devices found.')
        sys.exit(1)
    dev = devs[0]
    dev.start()
    port = dev.depp_ports[0]
    port.enable()

    WHITE = 1
    fore_color = 0
    back_color = WHITE

    port.put_reg(3, [7])

    while port.get_reg(15, 1)[0]:
        pass

    print("done")

    port.disable()

