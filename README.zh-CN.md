# Codex 额度栏

[English](README.md) · 简体中文

**Codex 还剩多少额度，抬眼就能看到。**

一个轻量的 macOS 菜单栏 App，把 Codex 剩余额度放在屏幕顶部。相比打开官方应用查看，菜单栏里的数字更直观：看一眼知道还剩多少，点一下查看每项额度的具体重置时间。

```text
5h 75% · 7d 50%
```

以上为模拟数据，两项数值均表示剩余额度百分比。

## 特点

- **菜单栏查看额度**：同时显示 5 小时与每周剩余额度，抬眼即可查看。
- **准确查看重置时间**：读取 Codex 返回的重置日期与时间，按本地时区显示，精确到分钟。
- **自动与手动刷新**：启动时读取，之后每 60 秒刷新一次；菜单内支持立即刷新，并显示上次更新时间。

本项目为独立工具，与 OpenAI 无隶属关系。App 界面目前为简体中文。

## 兼容性

> [!IMPORTANT]
> **建议使用 macOS 27 及以上版本。** 在较旧系统中，菜单栏拥挤可能导致状态项无法显示，或菜单无法展开。

| 项目 | 要求 |
| --- | --- |
| Mac | Apple Silicon；仓库内安装包为 arm64 构建 |
| macOS | 推荐 27 及以上；最低编译目标为 13.0 |
| Codex | 已登录，且支持本工具 app-server 额度查询的 Codex CLI |
| Python | `/usr/bin/python3` 可用 |
| 界面语言 | 简体中文 |

重置时间与额度是否可用以 Codex 返回的数据为准，界面每分钟轮询更新。

## 安装

1. [下载 Apple Silicon 安装包](dist/codex-usage-bar-1.0.0-macos-arm64.zip?raw=true)。
2. 解压，将 `Codex 额度栏.app` 移入“应用程序”文件夹。
3. 确认本机已安装兼容的 Codex CLI 并完成登录，然后打开 App。
4. 在菜单栏找到 `5h … · 7d …`，点击即可查看两项额度的重置时间或手动刷新。

安装包采用 ad-hoc 本地签名，尚未经过 Apple 公证。如果系统阻止打开，可在 **系统设置 → 隐私与安全性** 中允许打开。

## 隐私

App 使用你在当前 Mac 上已有的 Codex 登录状态。仓库和安装包不包含凭证、账号配置、聊天记录或额度快照。

辅助程序与本机 Codex CLI 通信，CLI 可能访问其服务以查询额度。本 App 没有新增遥测或独立的数据收集服务。打包时的隐私处理详见 [PRIVACY.md](PRIVACY.md)。

## 从源码构建

需要 Xcode Command Line Tools（包含 Swift 编译器与 macOS SDK）以及 Python 3。在仓库根目录运行：

```sh
bash scripts/build.sh
```

脚本会编译 Apple Silicon 版本、添加本地签名，并将 ZIP、构建信息及校验值输出到 `dist/`。临时构建文件保留在 `.build/`，不纳入 Git。

| 文件 | 用途 |
| --- | --- |
| `src/main.swift` | 菜单栏界面与刷新逻辑 |
| `src/usage.py` | 通过本机 Codex CLI 查询额度 |
| `resources/Info.plist` | App 信息 |
| `scripts/` | 构建与打包脚本 |
| [dist/BUILD_INFO.json](dist/BUILD_INFO.json) | 版本、架构、文件大小与 SHA-256 校验值 |

辅助程序使用 `app-server --stdio` 和 `account/rateLimits/read`。CLI 路径或协议发生变化时，可能需要更新 `src/usage.py`。

如需校验下载的 ZIP，将它与 [SHA256SUMS](dist/SHA256SUMS) 放在同一目录，并在该目录运行：

```sh
shasum -a 256 -c SHA256SUMS
```

## 常见问题

| 情况 | 处理方式 |
| --- | --- |
| 状态项不显示，或菜单无法展开 | 隐藏或退出其他菜单栏工具，留出显示空间；建议使用 macOS 27 及以上版本。 |
| 显示 `5h -- · 7d --` | 确认 Codex 已登录、CLI 兼容且 `/usr/bin/python3` 可用，然后点击“立即刷新”。 |
| 无法查看重置时间 | Codex 可能尚未返回重置时间戳，可以刷新后再查看。 |
