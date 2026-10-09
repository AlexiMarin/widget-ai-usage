import ServiceManagement
import SwiftUI
import WidgetKit

@main
struct AIUsageApp: App {
    @StateObject private var model = UsageModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            Text(model.menuTitle)
        }
    }
}

@MainActor
final class UsageModel: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled

    private let claude: UsageProvider = ClaudeUsageClient()
    private var timer: Timer?
    private static let interval: TimeInterval = 5 * 60

    init() {
        snapshot = SharedStore.load() ?? .empty
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    var menuTitle: String {
        guard snapshot.status == .ok,
              let p = snapshot.claude.first(where: { $0.id == "five_hour" })?.percent
        else { return "✳︎ –" }
        return "✳︎ \(Int(p.rounded()))%"
    }

    func refresh() async {
        var next = snapshot
        next.updatedAt = .now
        do {
            let result = try await claude.fetch()
            next.status = .ok
            next.message = nil
            next.plan = result.plan
            next.claude = result.meters
        } catch UsageError.tokenMissing {
            next.status = .tokenMissing
            next.message = UsageError.tokenMissing.errorDescription
        } catch UsageError.tokenExpired {
            next.status = .tokenExpired
            next.message = UsageError.tokenExpired.errorDescription
        } catch {
            // Keep the last good meters; just flag the error.
            next.status = next.claude.isEmpty ? .error : .ok
            next.message = error.localizedDescription
        }
        snapshot = next
        try? SharedStore.save(next)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Launch at login failed: \(error)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

struct MenuContent: View {
    @ObservedObject var model: UsageModel

    var body: some View {
        let s = model.snapshot
        if let plan = s.plan { Text("Claude \(plan.capitalized)") }
        ForEach(s.claude) { m in
            if let p = m.percent {
                Text("\(m.label): \(Int(p.rounded()))%" + (m.resetsAt.map { " · reinicia en \($0.compactUntil())" } ?? ""))
            }
        }
        if let msg = s.message { Text("⚠︎ \(msg)") }
        Text("Actualizado \(s.updatedAt.formatted(date: .omitted, time: .shortened))")
        Divider()
        Button("Actualizar") { Task { await model.refresh() } }
            .keyboardShortcut("r")
        Toggle("Abrir al iniciar sesión", isOn: Binding(
            get: { model.launchAtLogin },
            set: { model.setLaunchAtLogin($0) }))
        Divider()
        Button("Salir") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
