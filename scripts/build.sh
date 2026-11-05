#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
mkdir -p .build dist
BUILD_DIR="$(mktemp -d "$PROJECT_ROOT/.build/run.XXXXXX")"
APP_DIR="$BUILD_DIR/Codex 额度栏.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$BUILD_DIR/module-cache"

# Use neutral source paths in the compiled executable; omit debug information.
xcrun swiftc -O -target arm64-apple-macosx13.0 \
  -module-name UsageBar \
  -module-cache-path "$BUILD_DIR/module-cache" \
  -file-prefix-map "$PROJECT_ROOT=/src/codex-usage-bar" \
  -debug-prefix-map "$PROJECT_ROOT=/src/codex-usage-bar" \
  src/main.swift -o "$APP_DIR/Contents/MacOS/UsageBar"
cp resources/Info.plist "$APP_DIR/Contents/Info.plist"
cp src/usage.py "$APP_DIR/Contents/Resources/usage.py"
chmod 755 "$APP_DIR/Contents/MacOS/UsageBar"
codesign --force --sign - --identifier local.codex.usagebar --timestamp=none "$APP_DIR"
codesign --verify --strict "$APP_DIR"
python3 scripts/package.py "$APP_DIR"
