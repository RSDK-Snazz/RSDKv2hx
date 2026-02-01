# Requires the Pillow dependency
import sys, math, itertools
from PIL import Image
from pathlib import Path

WIDTH = 8
HEIGHT = 8
CHARCOUNT = 128
COLCOUNT = 16

IMGWIDTH = (COLCOUNT if CHARCOUNT >= COLCOUNT else CHARCOUNT) * WIDTH
IMGHEIGHT = math.ceil(CHARCOUNT / COLCOUNT) * HEIGHT

def encode_font(image_path):
    print(f"Opening {image_path}...")

    img = Image.open(image_path).convert("1")
    assert img.size == (IMGWIDTH, IMGHEIGHT), f"Image does not match expected size ({IMGWIDTH}x{IMGHEIGHT})"

    print("Encoding pixel data...")
    data = bytearray()

    row = 0
    col = 0
    for char in range(CHARCOUNT):
        h = row * HEIGHT
        for y in range(h, h + HEIGHT):
            for x in range(WIDTH):
                data.append(0x01 if img.getpixel((x + (col * WIDTH), y)) else 0x00)
        col += 1
        if col >= COLCOUNT:
            col = 0
            row += 1

    return data

def main():
    assert len(sys.argv) > 1, "No input file given"

    img_file = Path(sys.argv[1])
    data = encode_font(img_file)

    output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else img_file.with_name(img_file.stem + ".hx")
    print(f"Writing to {output_file}...")

    try:
        with output_file.open("w") as hx:
            hx.write("package rsdk.dev;\n\n")
            hx.write("import haxe.io.Bytes;\n\n")
            hx.write("class DevFont {\n")

            if CHARCOUNT == 128:
                hx.write("    // First 128 characters of Code page 437 on old IBM computers\n")

            hx.write(f"    public static final devTextStencil:Bytes = Bytes.ofHex(\"")

            hx.write("".join(f"{b:02X}" for b in data))

            hx.write("\");\n")
            hx.write("}\n")

        print("Done!")
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    main()
