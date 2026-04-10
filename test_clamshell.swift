import Foundation
import IOKit

func isClamshellClosed() -> Bool {
    var closed = false
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
    if service != 0 {
        if let clamshellStateCF = IORegistryEntryCreateCFProperty(service, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool {
            closed = clamshellStateCF
        } else if let clamshellStateCF = IORegistryEntryCreateCFProperty(service, "AppleClamshellClosed" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool {
            closed = clamshellStateCF
        }
        IOObjectRelease(service)
    }
    return closed
}

print("Is clamshell closed? \(isClamshellClosed())")
