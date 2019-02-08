#!/usr/bin/env python3

from PIL import Image
import sys
import usb1
from adepttool.device import get_devices
import time
import random

img = Image.open(sys.argv[1])
back_color = int(sys.argv[2])
img_w, img_h = img.size
img_w = (img_w // 2) * 2
img_h = (img_h // 2) * 2
W = 320
H = 200
B = 256

def simulate(port):
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
    border_w = (W - img_w) // 2
    border_h = (H - img_h) // 2
    bbox_w = W - border_w * 2
    bbox_h = H - border_h * 2
    cur_w = border_w
    cur_h = border_h
    max_w = border_w * 2
    max_h = border_h * 2

    def shift_image(dw, dh):
        nonlocal cur_w
        nonlocal cur_h
        print(dw, dh, cur_w + bbox_w, cur_h + bbox_h)

        old_w, old_h = cur_w, cur_h

        port.put_reg(4, [cur_w % B])
        port.put_reg(5, [cur_w // B])
        port.put_reg(6, [cur_h % B])
        port.put_reg(7, [cur_h // B])
        cur_w += dw
        cur_h += dh
        port.put_reg(0, [cur_w % B])
        port.put_reg(1, [cur_w // B])
        port.put_reg(2, [cur_h % B])
        port.put_reg(3, [cur_h // B])
        port.put_reg(8, [bbox_w % B])
        port.put_reg(9, [bbox_w // B])
        port.put_reg(10, [bbox_h % B])
        port.put_reg(11, [bbox_h // B])
        port.put_reg(0x0c, [0])
        while port.get_reg(15, 1)[0]:
            pass

        if dw > 0:
            draw_rect(cur_w - dw, old_h, abs(dw), bbox_h + abs(dh), back_color)
        elif dw < 0:
            draw_rect(cur_w + bbox_w, old_h, abs(dw), bbox_h + abs(dh), back_color)

        if dh > 0:
            draw_rect(old_w, cur_h - dh, bbox_w + abs(dw), abs(dh), back_color)
        elif dh < 0:
            draw_rect(old_w, cur_h + bbox_h, bbox_w + abs(dw), abs(dh), back_color)


    draw_rect(0, 0, W, H, 1 - back_color)
    draw_rect(2, 2, W - 4, H - 4, back_color)

    for y in range(0, img_h):
        port.put_reg(2, [y + border_h])
        for x in range(0, img_w, 8):
            bits = 0
            for dx in range(8):
                if x + dx >= img_w: break
                bits += (1 if img.getpixel((x + dx, y)) else 0) * 2 ** dx
            if bits != (255 * back_color): 
                port.put_reg(0, [(x + border_w) % B])
                port.put_reg(1, [(x + border_w) // B])
                port.put_reg(0x0e, [bits])

    step_dw = 0.7
    step_dh = 1.3

    cur_float_w = cur_w
    cur_float_h = cur_h
    while True:
        cur_float_w += step_dw
        cur_float_h += step_dh
        if not (2 <= cur_float_w < max_w - 2):
            step_dw = -step_dw
            cur_float_w += 2 * step_dw
        if not (2 <= cur_float_h < max_h - 2):
            step_dh = -step_dh
            cur_float_h += 2 * step_dh
        
        new_coord = (int(cur_float_w), int(cur_float_h))
        if new_coord != (cur_w, cur_h):
            shift_image(new_coord[0] - cur_w, new_coord[1] - cur_h)


with usb1.USBContext() as ctx:
    devs = get_devices(ctx)
    if not devs:
        print('No devices found.')
        sys.exit(1)
    dev = devs[0]
    dev.start()
    port = dev.depp_ports[0]
    port.enable()

    try:
        simulate(port)
    finally:
        port.disable()

