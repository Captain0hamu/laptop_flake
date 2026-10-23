"""Give Breeze's native popup and panel frames a fixed background opacity."""

import gzip
import json
from pathlib import Path
import re
import sys

base, output = map(Path, sys.argv[1:3])
opacity = float(sys.argv[3])
assert 0 <= opacity <= 1
output.mkdir(parents=True, exist_ok=True)

for asset in ("dialogs/background.svgz", "widgets/panel-background.svgz"):
    # Preserve Breeze's nine-slice geometry, outlines, shadows and size hints.
    svg = gzip.decompress((base / "translucent" / asset).read_bytes()).decode()
    svg, count = re.subn(r"opacity:0\.85(?=[;\"])", f"opacity:{opacity:.2f}", svg)
    if count != 9:
        raise ValueError(f"{asset}: expected nine Breeze background fills, got {count}")
    # Cover adaptive/solid paths as well, so maximized windows cannot undo it.
    for variant in ("", "translucent", "solid", "opaque"):
        target = output / variant / asset
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(gzip.compress(svg.encode(), mtime=0))

# Keep Breeze's author/license metadata, but replace its translated display names.
metadata = json.loads((base / "metadata.json").read_text())
plugin = metadata["KPlugin"]
for key in list(plugin):
    if key.startswith(("Name[", "Description[")):
        del plugin[key]
plugin.update({
    "Id": "personal-translucent",
    "Name": "Personal Translucent",
    "Description": f"Breeze with {100 * (1 - opacity):g}% transparent popup and panel backgrounds",
    "Version": f"1.0.{round(opacity * 100)}",
})
(output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
(output / "plasmarc").write_text("""[Settings]
FallbackTheme=default

[AdaptiveTransparency]
enabled=false

[ContrastEffect]
enabled=false

[BlurBehindEffect]
enabled=true
""")
