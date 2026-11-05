# Codex 额度栏

一个 macOS 菜单栏小工具，用于显示当前 Codex 账号的 5 小时和每周剩余额度。每分钟刷新一次，也可以从菜单手动刷新。

## 安装

1. 下载 `dist/codex-usage-bar-1.0.0-macos-arm64.zip`，解压后将 `Codex 额度栏.app` 放到应用程序文件夹。
2. 本构建面向 Apple Silicon（arm64），最低系统目标为 macOS 13。
3. 需要本机提供 `/usr/bin/python3`，以及已登录、支持 `account/rateLimits/read` 的 Codex CLI。
4. 应用按源码中的路径查找桌面应用内置 CLI、Homebrew CLI 或 PATH 内的 CLI。

安装包采用本地 ad-hoc 签名，未经过 Apple 公证。系统可能要求在“隐私与安全性”中手动允许打开。

程序从本机 Codex CLI 的 `app-server` 读取额度；CLI 可能通过网络向其服务查询。安装包不包含任何账号或登录状态，使用时需在当前机器自行登录。CLI 路径和协议如发生变化，可能需要调整 `src/usage.py`。

## 文件结构

| 路径 | 内容 |
| --- | --- |
| `src/main.swift` | 菜单栏界面与刷新逻辑 |
| `src/usage.py` | Codex 额度读取程序 |
| `resources/Info.plist` | 应用信息，使用通用 bundle ID |
| `scripts/build.sh` | 编译、签名与打包入口 |
| `scripts/package.py` | 只打包指定文件，移除附加元数据 |
| `dist/*.zip` | 可解压安装的应用 |
| `dist/BUILD_INFO.json` | 版本、架构、构建信息、大小和 SHA-256 |
| `dist/SHA256SUMS` | 安装包校验值 |
| `PRIVACY.md` | 发布物的隐私处理范围 |

## 从源码构建

需要 Xcode Command Line Tools（Swift 编译器与 macOS SDK）以及 Python 3。在项目目录运行：

```sh
bash scripts/build.sh
```

构建目录位于 `.build/`，不纳入 Git；新的 ZIP 和文件清单输出到 `dist/`。此仓库保留原有两个源文件的功能，应用标识已通用化。最低系统版本是编译目标，不表示已在每个 macOS 版本上实际运行验证。

## 校验安装包

在 `dist/` 目录运行：

```sh
shasum -a 256 -c SHA256SUMS
```
