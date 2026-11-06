#!/usr/bin/env python3
"""Pack Generate.cs output into the Mac picker's English RGB color-name table."""
import argparse
import hashlib
from itertools import groupby
import json
from pathlib import Path
import plistlib


def pack(oracle_dir):
    colors = (oracle_dir / "rgb.bin").read_bytes()
    names = json.loads((oracle_dir / "names.json").read_text(encoding="utf-8-sig"))
    if len(colors) != 1 << 24:
        raise ValueError("Expected exactly one name index for each opaque 24-bit RGB value")
    if not isinstance(names, list) or not 1 <= len(names) <= 256:
        raise ValueError("Expected an array of up to 256 color names")
    if any(not isinstance(name, str) or not name.strip() for name in names):
        raise ValueError("Expected a nonempty localized string for every color name")
    if max(colors) >= len(names):
        raise ValueError("Oracle contains an out-of-range name index")

    # Red and green choose the row. Within each row, encode equal consecutive
    # names as pairs of (last blue value, original oracle name index).
    runs = bytearray()
    for start in range(0, len(colors), 256):
        last_blue = -1
        for name_index, group in groupby(colors[start:start + 256]):
            last_blue += sum(1 for _ in group)
            runs.extend((last_blue, name_index))

    return plistlib.dumps({
        "version": 1,
        "names": names,
        "runs": bytes(runs),
        "language": "en-US",
        "rgbSHA256": hashlib.sha256(colors).hexdigest(),
    }, fmt=plistlib.FMT_BINARY, sort_keys=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("oracle_dir", type=Path, help="Directory with rgb.bin and names.json")
    parser.add_argument("output", type=Path, help="Output WindowsColorNames.plist")
    args = parser.parse_args()
    args.output.write_bytes(pack(args.oracle_dir))
