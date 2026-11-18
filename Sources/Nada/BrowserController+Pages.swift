import AppKit
import NadaCore
import WebKit

extension BrowserController: WKNavigationDelegate, WKDownloadDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if webView.url?.scheme != "about" { pane(for: webView)?.failedURL = nil }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showFailure(error, in: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showFailure(error, in: webView)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard let pane = pane(for: webView), let url = pane.address else { return }
        pane.failedURL = url
        webView.loadHTMLString(ErrorPage.html(url: url, reason: "La página se ha cerrado inesperadamente."), baseURL: nil)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let newTab = navigationAction.navigationType == .linkActivated && LinkClick.opensNewTab(
            command: navigationAction.modifierFlags.contains(.command),
            button: navigationAction.buttonNumber
        )
        if newTab, !navigationAction.shouldPerformDownload {
            openInBackground(navigationAction.request)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(navigationAction.shouldPerformDownload ? .download : .allow)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        let disposition = (navigationResponse.response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Disposition")
        let attachment = disposition?.lowercased().hasPrefix("attachment") == true
        decisionHandler(navigationResponse.canShowMIMEType && !attachment ? .allow : .download)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        let folder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let name = Downloads.freeName(for: suggestedFilename) {
            FileManager.default.fileExists(atPath: folder.appending(path: $0).path)
        }
        downloads[ObjectIdentifier(download)] = folder.appending(path: name)
        completionHandler(folder.appending(path: name))
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let file = downloads.removeValue(forKey: ObjectIdentifier(download)) else { return }
        DistributedNotificationCenter.default().post(name: Notification.Name("com.apple.DownloadFileFinished"), object: file.path)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let file = downloads.removeValue(forKey: ObjectIdentifier(download))
        ask("No se pudo descargar \(file?.lastPathComponent ?? "el archivo")", detail: error.localizedDescription, buttons: ["Aceptar"]) { _ in }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        ask(message, detail: frame.securityOrigin.host, buttons: ["Aceptar"]) { _ in completionHandler() }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        ask(message, detail: frame.securityOrigin.host, buttons: ["Aceptar", "Cancelar"]) { completionHandler($0 == .alertFirstButtonReturn) }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let field = NSTextField(string: defaultText ?? "")
        field.frame = NSRect(x: 0, y: 0, width: 260, height: 24)
        ask(prompt, detail: frame.securityOrigin.host, buttons: ["Aceptar", "Cancelar"], accessory: field) {
            completionHandler($0 == .alertFirstButtonReturn ? field.stringValue : nil)
        }
    }

    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping ([URL]?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.beginSheetModal(for: window) { completionHandler($0 == .OK ? panel.urls : nil) }
    }

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        let device = switch type {
        case .camera: "la cámara"
        case .microphone: "el micrófono"
        default: "la cámara y el micrófono"
        }
        ask("¿Permitir que \(origin.host) use \(device)?", detail: "", buttons: ["Permitir", "No permitir"]) {
            decisionHandler($0 == .alertFirstButtonReturn ? .grant : .deny)
        }
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let space = challenge.protectionSpace
        guard Challenge(method: space.authenticationMethod) == .credentials else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let user = NSTextField(frame: NSRect(x: 0, y: 30, width: 260, height: 24))
        user.placeholderString = "Usuario"
        let password = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        password.placeholderString = "Contraseña"
        user.nextKeyView = password
        let fields = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 54))
        fields.addSubview(user)
        fields.addSubview(password)
        ask("\(space.host) pide usuario y contraseña", detail: space.realm ?? "", buttons: ["Entrar", "Cancelar"], accessory: fields) {
            guard $0 == .alertFirstButtonReturn else {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            let credential = URLCredential(user: user.stringValue, password: password.stringValue, persistence: .forSession)
            completionHandler(.useCredential, credential)
        }
    }

    private func showFailure(_ error: Error, in webView: WKWebView) {
        let error = error as NSError
        let interrupted = error.domain == "WebKitErrorDomain" && error.code == 102
        guard error.code != NSURLErrorCancelled, !interrupted,
              let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL ?? webView.url else { return }
        pane(for: webView)?.failedURL = url
        webView.loadHTMLString(ErrorPage.html(url: url, reason: error.localizedDescription), baseURL: nil)
    }

    private func ask(
        _ message: String,
        detail: String,
        buttons: [String],
        accessory: NSView? = nil,
        completion: @escaping (NSApplication.ModalResponse) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.accessoryView = accessory
        buttons.forEach { alert.addButton(withTitle: $0) }
        alert.beginSheetModal(for: window, completionHandler: completion)
    }
}
