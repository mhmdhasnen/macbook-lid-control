import AppKit
import ServiceManagement

enum LidAction: String, CaseIterable, Identifiable {
    case sleep = "Sleep"
    case shutdown = "Shutdown"
    case doNothing = "Do Nothing"

    var id: String { rawValue }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var window: NSWindow?
    private var statusDebugLabel: NSTextField?
    private var sleepButton: NSButton?
    private var shutdownButton: NSButton?
    private var doNothingButton: NSButton?
    private var launchAtLoginCheckbox: NSButton?
    private let actionItemTags: [LidAction: Int] = [
        .sleep: 1001,
        .shutdown: 1002,
        .doNothing: 1003
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        LidMonitor.shared.start()
        setupStatusItem()
        setupWindow()

        // Stay as .accessory — do NOT switch to .regular.
        // .regular gives the app its own menu bar (File, Edit, etc.) which
        // pushes status items off-screen on notched MacBooks.
        // orderFrontRegardless works even in .accessory mode.
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func setupStatusItem() {
        // Remove any previous item before creating a new one
        if let old = statusItem {
            NSStatusBar.system.removeStatusItem(old)
            statusItem = nil
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        if let button = item.button {
            button.title = ""
            button.image = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "Lid Controller")
            button.image?.isTemplate = true
            button.imagePosition = .imageOnly
            button.toolTip = "Lid Controller"
        }

        item.menu = buildMenu()
        // Do NOT call item.isVisible — let it default to true.
        // Explicitly setting it can trigger bugs on some macOS versions.
        refreshMenuState()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(makeActionItem(title: "Sleep (Default)", action: .sleep))
        menu.addItem(makeActionItem(title: "Shutdown", action: .shutdown))
        menu.addItem(makeActionItem(title: "Do Nothing", action: .doNothing))
        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.tag = 2001
        menu.addItem(loginItem)

        let showWindowItem = NSMenuItem(title: "Show Window", action: #selector(showWindow(_:)), keyEquivalent: "")
        showWindowItem.target = self
        menu.addItem(showWindowItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func makeActionItem(title: String, action: LidAction) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(selectAction(_:)), keyEquivalent: "")
        item.target = self
        item.tag = actionItemTags[action] ?? 0
        return item
    }

    private func setupWindow() {
        let rect = NSRect(x: 0, y: 0, width: 420, height: 280)
        let window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Lid Controller"
        window.center()
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: rect)

        let titleLabel = NSTextField(labelWithString: "Lid Controller is running")
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.frame = NSRect(x: 24, y: 228, width: 320, height: 28)

        let bodyLabel = NSTextField(labelWithString: "If the menu bar item is hidden on your Mac, you can change the lid behavior here instead.")
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.maximumNumberOfLines = 3
        bodyLabel.frame = NSRect(x: 24, y: 184, width: 360, height: 36)

        let statusDebugLabel = NSTextField(labelWithString: "")
        statusDebugLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        statusDebugLabel.lineBreakMode = .byWordWrapping
        statusDebugLabel.maximumNumberOfLines = 2
        statusDebugLabel.frame = NSRect(x: 24, y: 160, width: 360, height: 20)
        self.statusDebugLabel = statusDebugLabel

        let sleepButton = NSButton(radioButtonWithTitle: "Sleep (Default)", target: self, action: #selector(selectSleep(_:)))
        sleepButton.frame = NSRect(x: 24, y: 126, width: 200, height: 22)
        self.sleepButton = sleepButton

        let shutdownButton = NSButton(radioButtonWithTitle: "Shutdown", target: self, action: #selector(selectShutdown(_:)))
        shutdownButton.frame = NSRect(x: 24, y: 98, width: 200, height: 22)
        self.shutdownButton = shutdownButton

        let doNothingButton = NSButton(radioButtonWithTitle: "Do Nothing", target: self, action: #selector(selectDoNothing(_:)))
        doNothingButton.frame = NSRect(x: 24, y: 70, width: 200, height: 22)
        self.doNothingButton = doNothingButton

        let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(toggleLaunchAtLoginFromWindow(_:)))
        launchAtLoginCheckbox.frame = NSRect(x: 24, y: 40, width: 200, height: 22)
        self.launchAtLoginCheckbox = launchAtLoginCheckbox

        let closeButton = NSButton(title: "Close Window", target: self, action: #selector(closeWindow(_:)))
        closeButton.frame = NSRect(x: 24, y: 10, width: 120, height: 26)
        closeButton.bezelStyle = .rounded

        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(statusDebugLabel)
        contentView.addSubview(sleepButton)
        contentView.addSubview(shutdownButton)
        contentView.addSubview(doNothingButton)
        contentView.addSubview(launchAtLoginCheckbox)
        contentView.addSubview(closeButton)

        window.contentView = contentView
        self.window = window
        refreshWindowState()
    }

    @objc private func selectAction(_ sender: NSMenuItem) {
        guard let selectedAction = actionItemTags.first(where: { $0.value == sender.tag })?.key else {
            return
        }

        UserDefaults.standard.set(selectedAction.rawValue, forKey: "action")
        LidMonitor.shared.applyPowerSettings(action: selectedAction)
        refreshMenuState()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        toggleLaunchAtLogin()
    }

    @objc private func toggleLaunchAtLoginFromWindow(_ sender: NSButton) {
        toggleLaunchAtLogin()
    }

    private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }

        refreshMenuState()
        refreshWindowState()
    }

    @objc private func selectSleep(_ sender: Any?) {
        updateAction(.sleep)
    }

    @objc private func selectShutdown(_ sender: Any?) {
        updateAction(.shutdown)
    }

    @objc private func selectDoNothing(_ sender: Any?) {
        updateAction(.doNothing)
    }

    @objc private func showWindow(_ sender: Any?) {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func closeWindow(_ sender: Any?) {
        window?.close()
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func refreshMenuState() {
        guard let menu = statusItem?.menu else {
            return
        }

        let selectedAction = storedAction()
        for (action, tag) in actionItemTags {
            menu.item(withTag: tag)?.state = action == selectedAction ? .on : .off
        }

        menu.item(withTag: 2001)?.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    private func refreshWindowState() {
        let selectedAction = storedAction()
        sleepButton?.state = selectedAction == .sleep ? .on : .off
        shutdownButton?.state = selectedAction == .shutdown ? .on : .off
        doNothingButton?.state = selectedAction == .doNothing ? .on : .off
        launchAtLoginCheckbox?.state = SMAppService.mainApp.status == .enabled ? .on : .off
        if statusItem?.button != nil {
            statusDebugLabel?.stringValue = "Menu bar icon: active"
        } else {
            statusDebugLabel?.stringValue = "Menu bar icon: not attached"
        }
    }

    private func updateAction(_ action: LidAction) {
        UserDefaults.standard.set(action.rawValue, forKey: "action")
        LidMonitor.shared.applyPowerSettings(action: action)
        refreshMenuState()
        refreshWindowState()
    }

    private func storedAction() -> LidAction {
        let actionString = UserDefaults.standard.string(forKey: "action") ?? LidAction.sleep.rawValue
        return LidAction(rawValue: actionString) ?? .sleep
    }
}

@main
final class LidControllerApplication: NSObject {
    private static let sharedDelegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.delegate = sharedDelegate
        app.run()
    }
}
