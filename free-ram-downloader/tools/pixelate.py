"""Crunch a 256px screenshot to the 16-colour Windows palette (no dithering), upscale with nearest neighbour.
usage: pixelate.py in.png out.png size"""
import sys
from PIL import Image

VGA = [(0,0,0),(128,0,0),(0,128,0),(128,128,0),(0,0,128),(128,0,128),(0,128,128),(192,192,192),
       (128,128,128),(255,0,0),(0,255,0),(255,255,0),(0,0,255),(255,0,255),(0,255,255),(255,255,255)]
src, dst, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
pal = Image.new("P", (1, 1))
flat = [c for rgb in VGA for c in rgb] + [0] * (768 - 48)
pal.putpalette(flat)
img = Image.open(src).convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
img.resize((size, size), Image.NEAREST).save(dst)   # RGB, no alpha: iOS icons must be opaque
