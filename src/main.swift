import AppKit
import Foundation

final class UsageBar: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let detail = NSMenuItem(title: "正在读取额度…", action: nil, keyEquivalent: "")
    private let weeklyDetail = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let updated = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private var refreshing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.title = "5h -- · 7d --"
        menu.addItem(detail)
        menu.addItem(weeklyDetail)
        menu.addItem(updated)
        menu.addItem(.separator())
        let refreshItem = NSMenuItem(title: "立即刷新", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        let quitItem = NSMenuItem(title: "退出额度栏", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
        refresh()
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
    }

    @objc private func refresh() {
        guard !refreshing else { return }
        refreshing = true
        let helper = Bundle.main.resourceURL!.appendingPathComponent("usage.py")
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = [helper.path]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = Pipe()
            var result: [String: Any] = [:]
            do {
                try process.run()
                let data = output.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                result = (try JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
            } catch {
                result = ["error": error.localizedDescription]
            }
            DispatchQueue.main.async {
                self?.show(result)
                self?.refreshing = false
            }
        }
    }

    private func show(_ result: [String: Any]) {
        if let error = result["error"] as? String {
            statusItem.button?.title = "5h -- · 7d --"
            detail.title = "读取失败：\(error)"
            weeklyDetail.title = ""
            updated.title = "可点“立即刷新”重试"
            return
        }
        guard let primary = result["primary"] as? [String: Any],
              let secondary = result["secondary"] as? [String: Any],
              let primaryUsed = primary["usedPercent"] as? Double,
              let secondaryUsed = secondary["usedPercent"] as? Double else {
            statusItem.button?.title = "5h -- · 7d --"
            detail.title = "当前账号暂无完整额度数据"
            weeklyDetail.title = ""
            updated.title = ""
            return
        }
        let fiveHour = max(0, min(100, 100 - Int(primaryUsed.rounded())))
        let week = max(0, min(100, 100 - Int(secondaryUsed.rounded())))
        statusItem.button?.title = "5h \(fiveHour)% · 7d \(week)%"
        let allowed = result["allowed"] as? Bool
        let state = allowed == false ? " · 当前额度不可用" : ""
        detail.title = "5 小时剩 \(fiveHour)%（\(resetText(primary))）\(state)"
        weeklyDetail.title = "每周剩 \(week)%（\(resetText(secondary))）"
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        updated.title = "上次更新：\(time) · 每分钟自动刷新"
    }

    private func resetText(_ window: [String: Any]) -> String {
        guard let timestamp = window["resetsAt"] as? TimeInterval else { return "重置时间未知" }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "\(formatter.string(from: date)) 重置"
    }

    @objc private func quit() { NSApplication.shared.terminate(nil) }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = UsageBar()
app.delegate = delegate
app.run()
