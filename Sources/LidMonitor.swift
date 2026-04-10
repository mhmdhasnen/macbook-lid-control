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

        // Just initializing the singleton is enough to start observing
        _ = LidMonitor.shared
    }

    func applyStoredPowerSettings() {
        applyPowerSettings(action: storedAction())
    }

    func applyPowerSettings(action: LidAction) {
        let command = powerCommand(for: action)

        runAppleScriptAsAdmin("do shell script \"\(command)\"")
    }
    
    @objc func receiveSleepNote(note: NSNotification) {
        let action = storedAction()
        
        if action == .shutdown {
            if isClamshellClosed() {
                // Execute shutdown
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

    private func powerCommand(for action: LidAction) -> String {
        if action == .doNothing {
            return "/usr/bin/pmset -a sleep 0; /usr/bin/pmset -a disablesleep 1"
        }

        return "/usr/bin/pmset -a disablesleep 0; /usr/bin/pmset -a sleep 1"
    }

    private func runAppleScriptAsAdmin(_ scriptStr: String) {
        let source = "\(scriptStr) with administrator privileges"
        if let script = NSAppleScript(source: source) {
            var error: NSDictionary?
            DispatchQueue.global(qos: .userInitiated).async {
                script.executeAndReturnError(&error)
                if let error = error {
                    print("AppleScript Error: \(error)")
                }
            }
        }
    }
}
