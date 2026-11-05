#!/usr/bin/env python3
"""Package only the required app files, without local filesystem metadata."""

import hashlib
import json
import plistlib
from pathlib import Path
import subprocess
import sys
import zipfile


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    root = Path(__file__).resolve().parent.parent
    app = Path(sys.argv[1]).resolve()
    included = [
        "Contents/Info.plist",
        "Contents/MacOS/UsageBar",
        "Contents/Resources/usage.py",
        "Contents/_CodeSignature/CodeResources",
    ]
    for name in included:
        path = app / name
        if not path.is_file() or path.is_symlink():
            raise ValueError(f"Missing or unsafe app file: {name}")
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    if info["CFBundleIdentifier"] != "local.codex.usagebar":
        raise ValueError("Unexpected bundle identifier")
    if (app / "Contents/Resources/usage.py").read_bytes() != (root / "src/usage.py").read_bytes():
        raise ValueError("Bundled helper does not match source")
    archive = root / "dist/codex-usage-bar-1.0.0-macos-arm64.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for name in included:
            entry = zipfile.ZipInfo(f"Codex 额度栏.app/{name}", date_time=(1980, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.compress_type = zipfile.ZIP_DEFLATED
            mode = 0o100755 if name == "Contents/MacOS/UsageBar" else 0o100644
            entry.external_attr = mode << 16
            output.writestr(entry, (app / name).read_bytes())
    compiler = subprocess.check_output(["xcrun", "swiftc", "--version"], text=True).splitlines()[0]
    manifest = {
        "application": "Codex 额度栏",
        "version": info["CFBundleShortVersionString"],
        "bundle_identifier": info["CFBundleIdentifier"],
        "architecture": "arm64",
        "deployment_target": "macOS 13.0",
        "compiler": compiler,
        "signing": "ad-hoc; no developer identity; not notarized",
        "archive": archive.name,
        "archive_size_bytes": archive.stat().st_size,
        "archive_sha256": sha256(archive),
        "source_sha256": {name: sha256(root / name) for name in [
            "src/main.swift", "src/usage.py", "resources/Info.plist",
            "scripts/build.sh", "scripts/package.py",
        ]},
        "app_files": {name: {"size_bytes": (app / name).stat().st_size, "sha256": sha256(app / name)} for name in included},
    }
    (root / "dist/BUILD_INFO.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (root / "dist/SHA256SUMS").write_text(f"{sha256(archive)}  {archive.name}\n", encoding="utf-8")
    print(f"Packaged dist/{archive.name}")


if __name__ == "__main__":
    main()
