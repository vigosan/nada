import NadaCore
import WebKit

final class VimKeysModule: BrowserModule {
    private var enabled = !UserDefaults.standard.bool(forKey: "vimkeys.disabled")
    private let controllers = NSHashTable<WKUserContentController>.weakObjects()
    private let script = WKUserScript(source: VimKeys.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

    var commands: [ModuleCommand] {
        []
    }

    var settings: [Setting] {
        [Setting(id: "vimkeys.enabled", title: "Teclas vim", value: enabled ? "Activadas" : "Desactivadas")]
    }

    func configure(_ configuration: WKWebViewConfiguration) {
        let controller = configuration.userContentController
        guard !controllers.contains(controller) else { return }
        controllers.add(controller)
        if enabled { controller.addUserScript(script) }
    }

    func run(_ commandID: String) {}

    func changeSetting(_ settingID: String) {
        enabled.toggle()
        UserDefaults.standard.set(!enabled, forKey: "vimkeys.disabled")
        for controller in controllers.allObjects {
            controller.removeAllUserScripts()
            if enabled { controller.addUserScript(script) }
        }
    }
}
