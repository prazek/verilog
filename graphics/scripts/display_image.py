#!/usr/bin/env python3

from PIL import Image
import sys
import usb1
from adepttool.device import get_devices

img = Image.open(sys.argv[1])
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

    written_bytes = []

    for y in range(H):
        port.put_reg(2, [y])
        for x in range(0, W, 8):
            port.put_reg(0, [x % 256])
            port.put_reg(1, [x // 256])
            bits = 0
            for dx in range(8):
                bits += (1 if img.getpixel((x + dx, y)) else 0) * 2 ** dx
            port.put_reg(0x0e, [bits])
            written_bytes.append(bits)

    read_bytes = []

    tab_idx = 0
    for y in range(H):
        port.put_reg(2, [y])
        for x in range(0, W, 8):
            port.put_reg(0, [x % 256])
            port.put_reg(1, [x // 256])
            read_bytes.append(port.get_reg(0x0e, 1)[0])

    assert(read_bytes == written_bytes)

    port.disable()

