import SwiftUI
import ServiceManagement

enum LidAction: String, CaseIterable, Identifiable {
    case sleep = "Sleep"
    case shutdown = "Shutdown"
    case doNothing = "Do Nothing"
    
    var id: String { self.rawValue }
}

@main
struct LidControllerApp: App {
    @AppStorage("action") private var action: LidAction = .sleep
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    
    var body: some Scene {
        MenuBarExtra("Lid Action", systemImage: "laptopcomputer") {
            Button(action: { setAction(.sleep) }) {
                HStack {
                    Text("Sleep (Default)")
                    if action == .sleep { Image(systemName: "checkmark") }
                }
            }

            Button(action: { setAction(.shutdown) }) {
                HStack {
                    Text("Shutdown")
                    if action == .shutdown { Image(systemName: "checkmark") }
                }
            }

            Button(action: { setAction(.doNothing) }) {
                HStack {
                    Text("Do Nothing")
                    if action == .doNothing { Image(systemName: "checkmark") }
                }
            }
            
            Divider()
            
            Button(action: toggleLaunchAtLogin) {
                HStack {
                    Text("Launch at Login")
                    if launchAtLogin {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    init() {
        LidMonitor.shared.start()
    }
    
    private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                launchAtLogin = false
            } else {
                try SMAppService.mainApp.register()
                launchAtLogin = true
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }
    
    private func setAction(_ action: LidAction) {
        self.action = action
        LidMonitor.shared.applyPowerSettings(action: action)
    }
}
