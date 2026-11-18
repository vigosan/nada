import AppKit

UserDefaults.standard.register(defaults: ["NSFullScreenMenuItemEverywhere": false])
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.setActivationPolicy(.regular)
NSApplication.shared.run()
