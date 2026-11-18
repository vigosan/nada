import AppKit
import NadaCore
import WebKit

final class DimView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

final class Pane: NSObject {
    weak var browser: BrowserController?
    let view = NSView()
    let dim = DimView()
    let webView: WKWebView
    var observations: [NSKeyValueObservation] = []
    var recordedURL: URL?
    var failedURL: URL?
    var pending: SessionPage?

    init(configuration: WKWebViewConfiguration, extensionPage: Bool = false) {
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        configuration.preferences.isElementFullscreenEnabled = true
        if !extensionPage { configuration.applicationNameForUserAgent = "Version/26.0 Safari/605.1.15" }
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        super.init()
        webView.isInspectable = true
        webView.allowsBackForwardNavigationGestures = true
        webView.autoresizingMask = [.width, .height]
        view.wantsLayer = true
        view.layer?.backgroundColor = Theme.window.cgColor
        view.addSubview(webView)
        dim.frame = view.bounds
        dim.autoresizingMask = [.width, .height]
        dim.wantsLayer = true
        dim.layer?.backgroundColor = Theme.veil.cgColor
        view.addSubview(dim)
    }

    var isBlank: Bool {
        webView.url == nil && pending == nil
    }

    var address: URL? {
        failedURL ?? pending?.url ?? webView.url
    }

    var title: String {
        if let title = webView.title, !title.isEmpty { return title }
        return pending?.title ?? webView.url?.host() ?? "Pestaña nueva"
    }
}

final class Tab {
    var layout = PaneLayout()
    var panes: [Int: Pane]

    init(pane: Pane) {
        panes = [layout.focused: pane]
    }

    var focused: Pane? {
        panes[layout.focused]
    }

    var title: String {
        focused?.title ?? ""
    }
}
