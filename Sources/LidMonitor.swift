import Cocoa
import IOKit

class LidMonitor {
    static let shared = LidMonitor()

    private init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(receiveSleepNote),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
    }

    func start() {
        applyStoredPowerSettings()
        _ = LidMonitor.shared
    }

    func applyStoredPowerSettings() {
        applyPowerSettings(action: storedAction())
    }

    func applyPowerSettings(action: LidAction) {
        let commands = powerCommands(for: action)
        for args in commands {
            runPmset(args)
        }
    }

    @objc func receiveSleepNote(note: NSNotification) {
        let action = storedAction()

        if action == .shutdown {
            if isClamshellClosed() {
                let source = "tell app \"System Events\" to shut down"
                if let script = NSAppleScript(source: source) {
                    var error: NSDictionary?
                    script.executeAndReturnError(&error)
                    if let error = error {
                        print("Failed to shut down: \(error)")
                    }
                }
            }
        }
    }

    private func isClamshellClosed() -> Bool {
        var closed = false
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        if service != 0 {
            if let clamshellStateCF = IORegistryEntryCreateCFProperty(service, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool {
                closed = clamshellStateCF
            } else if let clamshellClosedCF = IORegistryEntryCreateCFProperty(service, "AppleClamshellClosed" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool {
                closed = clamshellClosedCF
            }
            IOObjectRelease(service)
        }
        return closed
    }

    private func storedAction() -> LidAction {
        let actionStr = UserDefaults.standard.string(forKey: "action") ?? LidAction.sleep.rawValue
        return LidAction(rawValue: actionStr) ?? .sleep
    }

    /// Returns pmset argument arrays for the given action.
    private func powerCommands(for action: LidAction) -> [[String]] {
        if action == .doNothing {
            return [
                ["-a", "sleep", "0"],
                ["-a", "disablesleep", "1"]
            ]
        }
        return [
            ["-a", "disablesleep", "0"],
            ["-a", "sleep", "1"]
        ]
    }

    /// Runs /usr/bin/pmset via sudo.
    /// After install.sh sets up the sudoers rule, this won't prompt for a password.
    private func runPmset(_ args: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["/usr/bin/pmset"] + args
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus != 0 {
                    print("[LidController] pmset failed with status \(process.terminationStatus) for args: \(args)")
                }
            } catch {
                print("[LidController] Failed to run pmset: \(error)")
            }
        }
    }
}
