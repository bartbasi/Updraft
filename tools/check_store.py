# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
"""Checks the Play store material in docs/store/ against Google Play's rules.

    python tools/check_store.py

Graphics: the app icon (512x512, 32-bit PNG, every pixel opaque, under 1 MB), the feature
graphic (1024x500, 24-bit PNG with no alpha) and 4 to 8 screenshots (24-bit PNG, each side 320 to
3840 px, the long side at most twice the short one, under 8 MB). Text: the listing's app name,
short and full descriptions fit Play's limits and their written character counts are right, and
the listing and privacy policy use no em dashes or double hyphens. Python 3, standard library
only. Exits with 1 if anything fails.
"""

import os
import re
import struct
import sys
import zlib

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
STORE = os.path.join(ROOT, "docs", "store")
GRAPHICS = os.path.join(STORE, "graphics")
problems = []


def fail(message):
    problems.append(message)
    print("FAIL  " + message)


def read_png(path):
    """Width, height, bit depth, colour type and (for 8-bit RGBA) the smallest alpha, or None
    if the file is not a whole PNG."""
    try:
        return _read_png(path)
    except (struct.error, TypeError, zlib.error, IndexError):
        return None


def _read_png(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    pos, idat, header = 8, b"", None
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length
    width, height, depth, colour, _, _, interlace = header
    min_alpha = None
    if colour == 6 and depth == 8 and interlace == 0:
        min_alpha = _min_alpha(zlib.decompress(idat), width, height)
    return width, height, depth, colour, min_alpha


def _min_alpha(raw, width, height):
    """Undoes the PNG row filters of an 8-bit RGBA image and returns its smallest alpha."""
    bpp, stride = 4, width * 4
    previous = bytearray(stride)
    lowest = 255
    pos = 0
    for _ in range(height):
        kind = raw[pos]
        row = bytearray(raw[pos + 1:pos + 1 + stride])
        pos += 1 + stride
        for i in range(stride):
            left = row[i - bpp] if i >= bpp else 0
            up = previous[i]
            corner = previous[i - bpp] if i >= bpp else 0
            if kind == 1:
                row[i] = (row[i] + left) & 255
            elif kind == 2:
                row[i] = (row[i] + up) & 255
            elif kind == 3:
                row[i] = (row[i] + (left + up) // 2) & 255
            elif kind == 4:
                p = left + up - corner
                pa, pb, pc = abs(p - left), abs(p - up), abs(p - corner)
                predictor = left if pa <= pb and pa <= pc else (up if pb <= pc else corner)
                row[i] = (row[i] + predictor) & 255
        lowest = min(lowest, min(row[3::4]))
        previous = row
    return lowest


def check_graphics():
    icon = os.path.join(GRAPHICS, "icon_512.png")
    info = read_png(icon) if os.path.exists(icon) else None
    if info is None:
        fail("icon_512.png is missing or not a PNG")
    else:
        w, h, depth, colour, min_alpha = info
        if (w, h, depth, colour) != (512, 512, 8, 6):
            fail("icon: %dx%d, depth %d, colour type %d (want 512x512 32-bit RGBA)" % (w, h, depth, colour))
        if min_alpha != 255:
            fail("icon: not every pixel is opaque (lowest alpha %s); Play wants a full square" % min_alpha)
        if os.path.getsize(icon) >= 1024 * 1024:
            fail("icon: 1 MB or more")
        print("ok    icon_512.png")

    feature = os.path.join(GRAPHICS, "feature_graphic_1024x500.png")
    info = read_png(feature) if os.path.exists(feature) else None
    if info is None:
        fail("feature_graphic_1024x500.png is missing or not a PNG")
    else:
        w, h, depth, colour, _ = info
        if (w, h, depth, colour) != (1024, 500, 8, 2):
            fail("feature graphic: %dx%d, depth %d, colour type %d (want 1024x500 24-bit RGB)" % (w, h, depth, colour))
        if os.path.getsize(feature) >= 15 * 1024 * 1024:
            fail("feature graphic: 15 MB or more")
        print("ok    feature_graphic_1024x500.png")

    shots = sorted(f for f in os.listdir(GRAPHICS) if f.startswith("screenshot_"))
    if not 4 <= len(shots) <= 8:
        fail("%d screenshots (want 4 to 8)" % len(shots))
    for name in shots:
        path = os.path.join(GRAPHICS, name)
        info = read_png(path)
        if info is None:
            fail("%s is not a PNG" % name)
            continue
        w, h, depth, colour, _ = info
        if depth != 8 or colour != 2:
            fail("%s: depth %d, colour type %d (want 24-bit RGB, no alpha)" % (name, depth, colour))
        if not (320 <= min(w, h) and max(w, h) <= 3840 and max(w, h) <= 2 * min(w, h)):
            fail("%s: %dx%d is outside Play's sizes" % (name, w, h))
        if os.path.getsize(path) >= 8 * 1024 * 1024:
            fail("%s: 8 MB or more" % name)
        print("ok    %s (%dx%d)" % (name, w, h))
    for name in os.listdir(GRAPHICS):
        if name.lower().endswith((".jpg", ".jpeg")):
            fail("%s: an old JPEG is still here" % name)


def quoted(text, label):
    """The text quoted (with >) after the bold label in the listing."""
    match = re.search(r"\*\*" + re.escape(label) + r"\*\*.*?: (\d+) characters\n\n> (.*)\n", text)
    if not match:
        fail("listing: no %s with its character count" % label)
        return None, None
    return int(match.group(1)), match.group(2)


def check_text():
    listing = open(os.path.join(STORE, "listing.md"), encoding="utf-8").read()
    for label, limit in (("App name", 30), ("Short description", 80)):
        written, value = quoted(listing, label)
        if value is None:
            continue
        if len(value) > limit:
            fail("%s is %d characters (at most %d)" % (label, len(value), limit))
        if written != len(value):
            fail("%s: the listing says %d characters, it is %d" % (label, written, len(value)))
        print("ok    %s: %d of %d characters" % (label, len(value), limit))
    match = re.search(r"\*\*Full description\*\*.*?: (\d+) characters", listing)
    body = re.search(r"<!-- full description start -->\n(.*?)\n<!-- full description end -->", listing, re.S)
    if not (match and body):
        fail("listing: no full description with its character count")
    else:
        length = len(body.group(1))
        if length > 4000:
            fail("Full description is %d characters (at most 4000)" % length)
        if int(match.group(1)) != length:
            fail("Full description: the listing says %s characters, it is %d" % (match.group(1), length))
        print("ok    Full description: %d of 4000 characters" % length)
    for name in ("listing.md", "privacy-policy.md", "index.md", os.path.join("graphics", "README.md")):
        text = open(os.path.join(STORE, name), encoding="utf-8").read()
        prose = re.sub(r"^---\n.*?\n---\n", "", text, flags=re.S)  # front matter
        prose = re.sub(r"`[^`]*`", "", prose)  # code, such as command-line flags
        prose = re.sub(r"<!--.*?-->", "", prose)  # comments
        prose = re.sub(r"^\|[-| ]+\|$", "", prose, flags=re.M)  # a table's rule
        if "—" in prose or "–" in prose or "--" in prose:
            fail("%s has an em dash, an en dash or a double hyphen" % name)
        else:
            print("ok    %s style" % name)


check_graphics()
check_text()
if problems:
    print("\n%d problem(s)" % len(problems))
    sys.exit(1)
print("\nall good")
