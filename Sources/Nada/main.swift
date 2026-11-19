import AppKit
import NadaCore

let arguments = Array(CommandLine.arguments.dropFirst())
if let command = arguments.first, RemoteRequest.isCommand(command) {
    RemoteClient.run(arguments)
}

UserDefaults.standard.register(defaults: ["NSFullScreenMenuItemEverywhere": false])
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.setActivationPolicy(.regular)
NSApplication.shared.run()
