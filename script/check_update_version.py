#!/usr/bin/env python3
"""Reject non-advancing Scrooge build numbers before replacing the update feed."""
import argparse
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SPARKLE_VERSION = "{http://www.andymatuschak.org/xml-namespaces/sparkle}version"


def build_number(value: str) -> int:
    if not re.fullmatch(r"[1-9][0-9]*", value):
        raise ValueError("Update build numbers must be positive integers.")
    return int(value)


def check(candidate: str, feed: bytes) -> None:
    proposed = build_number(candidate)
    root = ET.fromstring(feed)
    items = root.findall("./channel/item")
    if root.tag != "rss" or not items:
        raise ValueError("The published update feed has no release items.")
    versions = []
    for item in items:
        value = item.findtext(SPARKLE_VERSION)
        if value is None:
            enclosure = item.find("enclosure")
            value = enclosure.get(SPARKLE_VERSION) if enclosure is not None else None
        if value is None:
            raise ValueError("A published update is missing its build number.")
        versions.append(build_number(value.strip()))
    if proposed <= max(versions):
        raise ValueError(f"Build {proposed} does not advance the published build {max(versions)}. Use a newer commit.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("build")
    parser.add_argument("feed", type=Path)
    args = parser.parse_args()
    try:
        check(args.build, args.feed.read_bytes())
    except (OSError, ET.ParseError, ValueError) as error:
        parser.exit(1, f"Update publication rejected: {error}\n")


if __name__ == "__main__":
    main()
