#!/usr/bin/env python3

import sys
from textwrap import wrap

if len(sys.argv) < 2:
    print("Missing file argument")
    exit()

filepath = sys.argv[1]
with open(filepath) as file:

    def filter_func(x):
        # Ignore file type line and comments
        return not (x.startswith("P") or x.startswith("#"))

    lines = list(filter(filter_func, file.readlines()))

    # Get sprite dimensions
    width, height = map(int, lines.pop(0).split(" "))
    # Remove max value line
    lines.pop(0)

    line_count = len(lines)
    if line_count % 3 != 0:
        print("The number of color values is not divisible by 3.")
        exit()
    if line_count != width * height * 3:
        print(
            f"The number of pixel values doesn't match the dimensions. Expected {width * height * 3} values, got {line_count}."
        )
        exit()

    # Start with 1 extra word because otherwise leading 0s would be removed
    bit_num = 0xFFFFFFFF
    for i in range(0, line_count, 3):
        color = sum(map(int, lines[i : i + 3]))
        bit_num = bit_num << 1
        # Draw pixel if it's black
        if color == 0:
            bit_num += 1

    hex_string = f"{bit_num:x}"
    hex_vals = wrap(hex_string, 8)
    hex_vals[-1] = hex_vals[-1].ljust(8, "0")
    hex_vals.pop(0)  # Remove extra word
    print(width, height, *map(lambda x: f"0x{x}", hex_vals), sep=",")
