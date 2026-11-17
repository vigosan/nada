import AppKit
import NadaCore
import WebKit

final class Pane {
    let view = NSView()
    let webView: WKWebView
    var observations: [NSKeyValueObservation] = []
    var recordedURL: URL?

    init(configuration: WKWebViewConfiguration) {
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        configuration.applicationNameForUserAgent = "Version/26.0 Safari/605.1.15"
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.isInspectable = true
        webView.allowsBackForwardNavigationGestures = true
        webView.autoresizingMask = [.width, .height]
        view.wantsLayer = true
        view.layer?.backgroundColor = Theme.window.cgColor
        view.addSubview(webView)
    }

    var isBlank: Bool {
        webView.url == nil
    }

    var title: String {
        if let title = webView.title, !title.isEmpty { return title }
        return webView.url?.host() ?? "Pestaña nueva"
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
