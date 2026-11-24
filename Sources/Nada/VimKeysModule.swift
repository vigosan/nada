import NadaCore
import WebKit

final class VimKeysModule: NSObject, BrowserModule, WKScriptMessageHandler {
    private var enabled = !UserDefaults.standard.bool(forKey: "vimkeys.disabled")
    private let controllers = NSHashTable<WKUserContentController>.weakObjects()
    private let script = WKUserScript(source: VimKeys.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .defaultClient)
    private let openInPane: (URL, WKWebView) -> Void

    init(openInPane: @escaping (URL, WKWebView) -> Void) {
        self.openInPane = openInPane
    }

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
        controller.add(self, contentWorld: .defaultClient, name: VimKeys.openInPaneMessage)
        if enabled { controller.addUserScript(script) }
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let address = message.body as? String, let url = URL(string: address), let webView = message.webView else { return }
        openInPane(url, webView)
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
