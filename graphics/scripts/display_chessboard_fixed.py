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

    def draw_rect(x, y, dx, dy, color):
        port.put_reg(0, [x % B])
        port.put_reg(1, [x // B])
        port.put_reg(2, [y % B])
        port.put_reg(3, [y // B])
        port.put_reg(8, [dx % B])
        port.put_reg(9, [dx // B])
        port.put_reg(10, [dy % B])
        port.put_reg(11, [dy // B])
        port.put_reg(0x0d, [color])
        while port.get_reg(15, 1)[0]:
            pass

    for block_size in range(16, 48, 2):
        draw_rect(0, 0, W, H, back_color)
        y_idx = 0

        for y in range(0, H, block_size):
            x_idx = 0
            for x in range(0, W, block_size):
                dx = min(block_size, W - x)
                dy = min(block_size, H - y)
                if (y_idx + x_idx) % 2 == 0:
                    draw_rect(x, y, dx, dy, fore_color)
                x_idx += 1
            y_idx += 1

        time.sleep(0.5)
        fore_color, back_color = back_color, fore_color

    port.disable()

