#!/usr/bin/env python3

import sys
import usb1
from adepttool.device import get_devices
import time

num_flushes = int(sys.argv[1])

W = 320
H = 200

with usb1.USBContext() as ctx:
    devs = get_devices(ctx)
    if not devs:
        print('No devices found.')
        sys.exit(1)
    dev = devs[0]
    dev.start()
    port = dev.depp_ports[0]
    port.enable()

    color = 0

    port.put_reg(0, [0])
    port.put_reg(1, [0])
    port.put_reg(2, [0])
    port.put_reg(3, [0])
    port.put_reg(8, [W % 256])
    port.put_reg(9, [W // 256])
    port.put_reg(10, [H % 256])
    port.put_reg(11, [H // 256])

    def draw_rect(color):
        port.put_reg(0x0d, [color])

    for i in range(num_flushes):
        draw_rect(i % 2)

        while port.get_reg(15, 1)[0]:
            pass

    port.disable()

