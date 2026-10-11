import AppKit

// MARK: - Veri

struct Entry { let date: Date; let tokens: Int }

enum UsageReader {
    static let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/projects")

    static func load(since cutoff: Date) -> [Entry] {
        let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        var seen = Set<String>(); var out: [Entry] = []
        guard let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else { return [] }
        for case let url as URL in en where url.pathExtension == "jsonl" {
            if let m = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate, m < cutoff { continue }
            guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else { continue }
            for line in text.split(separator: "\n") where line.contains("\"usage\"") {
                guard let o = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                      let msg = o["message"] as? [String: Any], let u = msg["usage"] as? [String: Any],
                      let ts = o["timestamp"] as? String, let d = iso.date(from: ts) ?? iso2.date(from: ts), d >= cutoff
                else { continue }
                let key = "\(msg["id"] as? String ?? "")|\(o["requestId"] as? String ?? "")"
                if key != "|" { if seen.contains(key) { continue }; seen.insert(key) }
                let n = (u["input_tokens"] as? Int ?? 0) + (u["output_tokens"] as? Int ?? 0) + (u["cache_creation_input_tokens"] as? Int ?? 0)
                out.append(Entry(date: d, tokens: n))
            }
        }
        return out.sorted { $0.date < $1.date }
    }
}

struct Snapshot {
    var blockTokens = 0; var blockEnd: Date? = nil; var dayTokens = 0
}

func compute(_ entries: [Entry], now: Date) -> Snapshot {
    var s = Snapshot()
    let dayStart = Calendar.current.startOfDay(for: now)
    s.dayTokens = entries.filter { $0.date >= dayStart }.reduce(0) { $0 + $1.tokens }
    // 5 saatlik bloklar: ilk mesajla başlar (saate yuvarlanır), 5 saat sürer
    var start: Date? = nil; var tokens = 0
    for e in entries {
        if let st = start, e.date < st.addingTimeInterval(5 * 3600) { tokens += e.tokens }
        else {
            let c = Calendar.current.dateComponents([.year, .month, .day, .hour], from: e.date)
            start = Calendar.current.date(from: c); tokens = e.tokens
        }
    }
    if let st = start, now < st.addingTimeInterval(5 * 3600) { s.blockTokens = tokens; s.blockEnd = st.addingTimeInterval(5 * 3600) }
    return s
}

// MARK: - Resmî veri (usage.json)

struct Official { var fivePct: Int; var fiveReset: Date?; var weekPct: Int?; var updated: Date }

enum OfficialReader {
    static let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude-usage-bar/usage.json")
    static func read() -> Official? {
        guard let d = try? Data(contentsOf: url), let o = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let f = o["fiveHour"] as? [String: Any], let p = f["percent"] as? Int,
              let u = o["updatedAt"] as? String else { return nil }
        let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        func dt(_ x: Any?) -> Date? { (x as? String).flatMap { iso.date(from: $0) ?? iso2.date(from: $0) } }
        guard let upd = dt(u) else { return nil }
        let w = o["weekly"] as? [String: Any]
        return Official(fivePct: p, fiveReset: dt(f["resetsAt"]), weekPct: w?["percent"] as? Int, updated: upd)
    }
}

// MARK: - Ayarlar

enum Prefs {
    static var fiveHourLimit: Int { get { UserDefaults.standard.object(forKey: "l5") as? Int ?? 1_000_000 } set { UserDefaults.standard.set(newValue, forKey: "l5") } }
    static var dayLimit: Int { get { UserDefaults.standard.object(forKey: "ld") as? Int ?? 5_000_000 } set { UserDefaults.standard.set(newValue, forKey: "ld") } }
}

func fmt(_ n: Int) -> String {
    n >= 1_000_000 ? String(format: "%.2fM", Double(n) / 1e6) : n >= 1000 ? String(format: "%.1fK", Double(n) / 1e3) : "\(n)"
}
func pct(_ v: Int, _ l: Int) -> Int { l > 0 ? min(100, Int((Double(v) / Double(l) * 100).rounded())) : 0 }

// MARK: - Uygulama

final class App: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var snap = Snapshot()
    var official: Official? = nil
    var isFresh: Bool { official.map { Date().timeIntervalSince($0.updated) < 20 * 60 } ?? false }
    let queue = DispatchQueue(label: "usage", qos: .utility)

    func applicationDidFinishLaunching(_ n: Notification) {
        render()
        refresh()
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        queue.async { [self] in
            let now = Date()
            let cutoff = min(Calendar.current.startOfDay(for: now), now.addingTimeInterval(-10 * 3600))
            let s = compute(UsageReader.load(since: cutoff), now: now)
            let o = OfficialReader.read()
            DispatchQueue.main.async { self.snap = s; self.official = o; self.render() }
        }
    }

    func color(_ p: Int) -> NSColor { p >= 90 ? .systemRed : p >= 70 ? .systemOrange : .labelColor }

    func render() {
        let f = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let dim = [NSAttributedString.Key.font: f, .foregroundColor: NSColor.secondaryLabelColor]
        let t = NSMutableAttributedString()
        if let o = official, isFresh {
            t.append(NSAttributedString(string: "5s %\(o.fivePct)", attributes: [.font: f, .foregroundColor: color(o.fivePct)]))
            if let w = o.weekPct {
                t.append(NSAttributedString(string: "  ·  ", attributes: dim))
                t.append(NSAttributedString(string: "Hf %\(w)", attributes: [.font: f, .foregroundColor: color(w)]))
            }
        } else {
            let p5 = pct(snap.blockTokens, Prefs.fiveHourLimit), pd = pct(snap.dayTokens, Prefs.dayLimit)
            t.append(NSAttributedString(string: "~5s %\(p5)", attributes: [.font: f, .foregroundColor: color(p5)]))
            t.append(NSAttributedString(string: "  ·  ", attributes: dim))
            t.append(NSAttributedString(string: "~Gün %\(pd)", attributes: [.font: f, .foregroundColor: color(pd)]))
        }
        item.button?.attributedTitle = t
        item.menu = buildMenu(pct(snap.blockTokens, Prefs.fiveHourLimit), pct(snap.dayTokens, Prefs.dayLimit))
    }

    func buildMenu(_ p5: Int, _ pd: Int) -> NSMenu {
        let m = NSMenu()
        func add(_ s: String, enabled: Bool = false) { let i = NSMenuItem(title: s, action: nil, keyEquivalent: ""); i.isEnabled = enabled; m.addItem(i) }
        if let o = official, isFresh {
            add("Resmî 5 saatlik limit: %\(o.fivePct)")
            if let r = o.fiveReset { let m = max(0, Int(r.timeIntervalSinceNow / 60)); add("   Sıfırlanma: \(m / 60) sa \(m % 60) dk sonra") }
            if let w = o.weekPct { add("Resmî haftalık limit: %\(w)") }
            let ago = Int(Date().timeIntervalSince(o.updated) / 60); add("   Son güncelleme: \(ago) dk önce")
        } else {
            add(official == nil ? "Resmî veri yok — yerel tahmin gösteriliyor (~)" : "Resmî veri eski — yerel tahmin gösteriliyor (~)")
        }
        m.addItem(.separator())
        add("Yerel tahmin, 5 saat: \(fmt(snap.blockTokens)) / \(fmt(Prefs.fiveHourLimit))  (%\(p5))")
        if let e = snap.blockEnd {
            let r = Int(e.timeIntervalSinceNow / 60)
            add("   Sıfırlanma: \(r / 60) sa \(r % 60) dk sonra")
        } else { add("   Aktif pencere yok") }
        m.addItem(.separator())
        add("Bugün: \(fmt(snap.dayTokens)) / \(fmt(Prefs.dayLimit))  (%\(pd))")
        m.addItem(.separator())
        let r = NSMenuItem(title: "Yenile", action: #selector(doRefresh), keyEquivalent: "r"); r.target = self; m.addItem(r)
        let l = NSMenuItem(title: "Limitleri ayarla…", action: #selector(setLimits), keyEquivalent: ","); l.target = self; m.addItem(l)
        let login = NSMenuItem(title: "Girişte başlat", action: #selector(toggleLogin), keyEquivalent: ""); login.target = self
        login.state = FileManager.default.fileExists(atPath: agentURL.path) ? .on : .off; m.addItem(login)
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: "Çık", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return m
    }

    @objc func doRefresh() { refresh() }

    @objc func setLimits() {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert(); a.messageText = "Token limitleri"
        a.informativeText = "Kendi planında 5 saatte / günde harcayabildiğin yaklaşık token miktarı. (giriş + çıkış + cache yazma)"
        let v = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 58))
        let f5 = NSTextField(frame: NSRect(x: 100, y: 32, width: 160, height: 22)); f5.stringValue = "\(Prefs.fiveHourLimit)"
        let fd = NSTextField(frame: NSRect(x: 100, y: 4, width: 160, height: 22)); fd.stringValue = "\(Prefs.dayLimit)"
        for (t, y) in [("5 saatlik:", 34), ("Günlük:", 6)] { let l = NSTextField(labelWithString: t); l.frame = NSRect(x: 0, y: y, width: 95, height: 18); v.addSubview(l) }
        v.addSubview(f5); v.addSubview(fd); a.accessoryView = v
        a.addButton(withTitle: "Kaydet"); a.addButton(withTitle: "İptal")
        if a.runModal() == .alertFirstButtonReturn {
            if let x = Int(f5.stringValue), x > 0 { Prefs.fiveHourLimit = x }
            if let x = Int(fd.stringValue), x > 0 { Prefs.dayLimit = x }
            render()
        }
    }

    var agentURL: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents/com.local.claudeusagebar.plist") }

    @objc func toggleLogin() {
        if FileManager.default.fileExists(atPath: agentURL.path) { try? FileManager.default.removeItem(at: agentURL) }
        else {
            let plist: [String: Any] = ["Label": "com.local.claudeusagebar", "ProgramArguments": [Bundle.main.executablePath ?? ""], "RunAtLoad": true]
            (plist as NSDictionary).write(to: agentURL, atomically: true)
        }
        render()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = App()
app.delegate = delegate
app.run()
