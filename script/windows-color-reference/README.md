# Windows color names

The workflow `windows-color-reference.yml` runs on Windows and checks the release ZIP's SHA-256 before loading its WinUI classifier and English string resources. The artifact contains a byte per RGB value in packed `0xRRGGBB` order plus a JSON name list. The app bundles a smaller lossless table of runs along the blue channel.

To regenerate and check the table from that artifact, run these commands at the repository root, replacing `/path/to/artifact` with the downloaded directory. The comparison exercises the Swift lookup used by the picker for every opaque RGB value.

```sh
python3 script/windows-color-reference/pack.py /path/to/artifact Resources/WindowsColorNames.plist
swiftc -O Models/WindowsColorNames.swift script/windows-color-reference/Compare.swift -o /tmp/scrooge-compare-colors
/tmp/scrooge-compare-colors /path/to/artifact/rgb.bin /path/to/artifact/names.json Resources/WindowsColorNames.plist
```
