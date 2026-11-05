# Codex Usage Bar / Codex 额度栏

English · [简体中文](README.zh-CN.md)

**Your Codex quota, at a glance.**

A lightweight macOS menu bar app that keeps your remaining Codex quota visible while you work. Check your balance without opening the official app's usage view, then click to see exactly when each limit resets.

```text
5h 75% · 7d 50%
```

Example with sample data. Both values show the percentage remaining.

## Features

- **Quota in your menu bar:** see your remaining 5-hour and weekly quota at a glance.
- **Precise reset times:** view the reset date and time reported by Codex for each quota window, displayed in your local time zone to the minute.
- **Automatic and manual refresh:** updates on launch and every 60 seconds, with a refresh action and the last update time in the menu.

This is an independent utility, unaffiliated with OpenAI. The app interface is currently in Simplified Chinese.

## Compatibility

> [!IMPORTANT]
> **macOS 27 or later is recommended.** On earlier versions, a crowded menu bar may prevent the status item from appearing or its menu from opening.

| Requirement | Details |
| --- | --- |
| Mac | Apple Silicon; the included build is arm64 |
| macOS | 27 or later recommended; minimum deployment target: 13.0 |
| Codex | A signed-in Codex CLI compatible with the app-server usage query |
| Python | Python 3 available at `/usr/bin/python3` |
| App language | Simplified Chinese |

Reset times and quota availability depend on the data returned by Codex. Updates are polled once a minute.

## Install

1. [Download the Apple Silicon app](dist/codex-usage-bar-1.0.0-macos-arm64.zip?raw=true).
2. Unzip it and move `Codex 额度栏.app` to your Applications folder.
3. Make sure a compatible Codex CLI is installed and signed in, then open the app.
4. Find `5h … · 7d …` in the menu bar. Click it to see both reset times or refresh manually.

The build is ad-hoc signed and has not been notarized by Apple. If macOS blocks opening it, you may need to allow it in **System Settings → Privacy & Security**.

## Privacy

The app uses the Codex login already present on your Mac. The repository and installer do not include credentials, account configuration, chat history, or usage snapshots.

The helper communicates with the local Codex CLI, which may contact its service to retrieve quota data. This app adds no telemetry or separate data collection service. See [PRIVACY.md](PRIVACY.md) for packaging details.

## Build from source

You need Xcode Command Line Tools, including Swift and the macOS SDK, plus Python 3. From the repository root, run:

```sh
bash scripts/build.sh
```

The script builds for Apple Silicon, applies an ad-hoc signature, and writes the ZIP, build information, and checksums to `dist/`. Temporary build files stay in `.build/` and are excluded from Git.

| File | Purpose |
| --- | --- |
| `src/main.swift` | Menu bar interface and refresh logic |
| `src/usage.py` | Queries the local Codex CLI for quota data |
| `resources/Info.plist` | App metadata |
| `scripts/` | Build and packaging scripts |
| [dist/BUILD_INFO.json](dist/BUILD_INFO.json) | Version, architecture, file sizes, and SHA-256 hashes |

The helper uses `app-server --stdio` and `account/rateLimits/read`. CLI paths or protocol changes may require an update to `src/usage.py`.

To verify the downloaded ZIP, place it beside [SHA256SUMS](dist/SHA256SUMS) and run from that directory:

```sh
shasum -a 256 -c SHA256SUMS
```

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| The status item is missing or its menu will not open | Free up menu bar space by hiding or quitting other menu bar utilities. macOS 27 or later is recommended. |
| The app shows `5h -- · 7d --` | Confirm Codex is signed in, the CLI is compatible, and `/usr/bin/python3` is available; then choose `立即刷新` (Refresh). |
| A reset time is unavailable | Codex may not have returned a reset timestamp. Refresh and check again. |
