import AppKit
import NadaCore
import WebKit

final class ExtensionsModule: NSObject, BrowserModule, WKWebExtensionControllerDelegate {
    static let folder = URL.applicationSupportDirectory.appending(path: "Nada/extensions")

    let controller: WKWebExtensionController
    private(set) var contexts: [WKWebExtensionContext] = []
    weak var browser: BrowserController?
    private var connections: [ObjectIdentifier: NativeConnection] = [:]

    override init() {
        let pages = WKWebViewConfiguration()
        pages.applicationNameForUserAgent = ExtensionShim.userAgentSuffix
        pages.userContentController.addUserScript(
            WKUserScript(source: ExtensionShim.script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        )
        let configuration = WKWebExtensionController.Configuration.default()
        configuration.webViewConfiguration = pages
        controller = WKWebExtensionController(configuration: configuration)
        super.init()
        controller.delegate = self
        let folders = ((try? FileManager.default.contentsOfDirectory(at: Self.folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { FileManager.default.fileExists(atPath: $0.appending(path: "manifest.json").path) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        Task { @MainActor in
            for folder in folders { await load(folder) }
        }
    }

    var commands: [ModuleCommand] {
        contexts.map {
            ModuleCommand(id: "extension:\($0.uniqueIdentifier)", title: "Extensión: \(name(of: $0))")
        } + contexts.map {
            ModuleCommand(id: "extensions.remove:\($0.uniqueIdentifier)", title: "Quitar extensión: \(name(of: $0))")
        } + [
            ModuleCommand(id: "extensions.install", title: "Instalar la extensión de esta página"),
            ModuleCommand(id: "extensions.folder", title: "Abrir carpeta de extensiones"),
        ]
    }

    var settings: [Setting] {
        []
    }

    func configure(_ configuration: WKWebViewConfiguration) {
        configuration.webExtensionController = controller
    }

    func run(_ commandID: String) {
        if commandID == "extensions.install" {
            install()
            return
        }
        if commandID == "extensions.folder" {
            try? FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
            NSWorkspace.shared.open(Self.folder)
            return
        }
        if let removed = contexts.first(where: { "extensions.remove:\($0.uniqueIdentifier)" == commandID }) {
            remove(removed)
            return
        }
        contexts.first { "extension:\($0.uniqueIdentifier)" == commandID }?.performAction(for: browser?.focusedPane)
    }

    private func name(of context: WKWebExtensionContext) -> String {
        context.webExtension.displayShortName ?? context.webExtension.displayName ?? context.uniqueIdentifier
    }

    private func remove(_ context: WKWebExtensionContext) {
        browser?.ask(
            "¿Quitar «\(name(of: context))»?",
            detail: "Se borrará la extensión de Nada.",
            buttons: ["Quitar", "Cancelar"]
        ) { [weak self] response in
            guard let self, response == .alertFirstButtonReturn else { return }
            try? controller.unload(context)
            contexts.removeAll { $0 === context }
            try? FileManager.default.removeItem(at: Self.folder.appending(path: context.uniqueIdentifier))
        }
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        openWindowsFor extensionContext: WKWebExtensionContext
    ) -> [any WKWebExtensionWindow] {
        browser.map { [$0] } ?? []
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        focusedWindowFor extensionContext: WKWebExtensionContext
    ) -> (any WKWebExtensionWindow)? {
        browser
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        presentActionPopup action: WKWebExtension.Action,
        for context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        guard let popover = action.popupPopover, let view = browser?.window.contentView else {
            completionHandler(CocoaError(.featureUnsupported))
            return
        }
        let anchor = NSRect(x: view.bounds.maxX - 40, y: view.bounds.maxY - 40, width: 1, height: 1)
        popover.show(relativeTo: anchor, of: view, preferredEdge: .minY)
        completionHandler(nil)
    }

    func changeSetting(_ settingID: String) {}

    func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewTabUsing configuration: WKWebExtension.TabConfiguration,
        for context: WKWebExtensionContext,
        completionHandler: @escaping ((any WKWebExtensionTab)?, (any Error)?) -> Void
    ) {
        completionHandler(open(configuration.url, for: context), nil)
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        openOptionsPageFor context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = open(context.optionsPageURL, for: context)
        completionHandler(nil)
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissions permissions: Set<WKWebExtension.Permission>,
        in tab: (any WKWebExtensionTab)?,
        for context: WKWebExtensionContext,
        completionHandler: @escaping (Set<WKWebExtension.Permission>, Date?) -> Void
    ) {
        confirm(permissions.map(\.rawValue).sorted(), for: context) { completionHandler($0 ? permissions : [], nil) }
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionToAccess urls: Set<URL>,
        in tab: (any WKWebExtensionTab)?,
        for context: WKWebExtensionContext,
        completionHandler: @escaping (Set<URL>, Date?) -> Void
    ) {
        confirm(urls.compactMap { $0.host() }.sorted(), for: context) { completionHandler($0 ? urls : [], nil) }
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionMatchPatterns matchPatterns: Set<WKWebExtension.MatchPattern>,
        in tab: (any WKWebExtensionTab)?,
        for context: WKWebExtensionContext,
        completionHandler: @escaping (Set<WKWebExtension.MatchPattern>, Date?) -> Void
    ) {
        confirm(matchPatterns.map(\.string).sorted(), for: context) { completionHandler($0 ? matchPatterns : [], nil) }
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        connectUsing port: WKWebExtension.MessagePort,
        for context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        guard let connection = connect(to: port.applicationIdentifier, for: context) else {
            completionHandler(CocoaError(.fileNoSuchFile))
            return
        }
        let key = ObjectIdentifier(connection)
        connection.onMessage = { port.sendMessage($0) { _ in } }
        connection.onClose = { [weak self] in
            self?.connections[key] = nil
            if !port.isDisconnected { port.disconnect() }
        }
        port.messageHandler = { message, _ in message.map(connection.send) }
        port.disconnectHandler = { _ in connection.close() }
        completionHandler(nil)
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        sendMessage message: Any,
        toApplicationWithIdentifier applicationIdentifier: String?,
        for context: WKWebExtensionContext,
        replyHandler: @escaping (Any?, (any Error)?) -> Void
    ) {
        guard let connection = connect(to: applicationIdentifier, for: context) else {
            replyHandler(nil, CocoaError(.fileNoSuchFile))
            return
        }
        let key = ObjectIdentifier(connection)
        var answered = false
        connection.onMessage = { reply in
            answered = true
            replyHandler(reply, nil)
            connection.close()
        }
        connection.onClose = { [weak self] in
            self?.connections[key] = nil
            if !answered { replyHandler(nil, CocoaError(.fileReadUnknown)) }
        }
        connection.send(message)
    }

    private func connect(to application: String?, for context: WKWebExtensionContext) -> NativeConnection? {
        guard let host = NativeConnection.host(named: application, for: context.uniqueIdentifier),
              let connection = try? NativeConnection(host) else { return nil }
        connections[ObjectIdentifier(connection)] = connection
        return connection
    }

    private func open(_ url: URL?, for context: WKWebExtensionContext) -> Pane? {
        let own = url?.scheme == context.baseURL.scheme && url?.host() == context.baseURL.host()
        return browser?.openExtensionPage(url, configuration: own ? context.webViewConfiguration : nil)
    }

    private func confirm(_ wanted: [String], for context: WKWebExtensionContext, completion: @escaping (Bool) -> Void) {
        guard let browser else {
            completion(false)
            return
        }
        browser.ask("«\(name(of: context))» pide permiso", detail: wanted.joined(separator: "\n"), buttons: ["Permitir", "No permitir"]) {
            completion($0 == .alertFirstButtonReturn)
        }
    }

    private func install() {
        guard let browser else { return }
        guard let identifier = browser.focusedPane?.webView.url.flatMap({ ChromeStore.identifier(in: $0.absoluteString) }) else {
            browser.ask(
                "Esta página no es de una extensión",
                detail: "Abre la página de la extensión en chromewebstore.google.com y repite la orden.",
                buttons: ["Aceptar"]
            ) { _ in }
            return
        }
        Task { @MainActor in
            do {
                let (package, _) = try await URLSession.shared.data(from: ChromeStore.download(identifier))
                guard let archive = ChromeStore.archive(in: package) else { throw CocoaError(.fileReadCorruptFile) }
                let unpacked = FileManager.default.temporaryDirectory.appending(path: "nada-\(identifier)")
                try? FileManager.default.removeItem(at: unpacked)
                try unpack(archive, into: unpacked)
                let webExtension = try await WKWebExtension(resourceBaseURL: unpacked)
                let name = webExtension.displayName ?? identifier
                let wanted = webExtension.requestedPermissions.map(\.rawValue).sorted().joined(separator: ", ")
                browser.ask(
                    "¿Instalar «\(name)»?",
                    detail: "Podrá leer y cambiar las páginas que visites.\n\nPermisos: \(wanted)",
                    buttons: ["Instalar", "Cancelar"]
                ) { response in
                    guard response == .alertFirstButtonReturn else { return }
                    Task { @MainActor in await self.replace(identifier, with: unpacked) }
                }
            } catch {
                browser.ask("No se pudo instalar la extensión", detail: error.localizedDescription, buttons: ["Aceptar"]) { _ in }
            }
        }
    }

    private func unpack(_ archive: Data, into folder: URL) throws {
        let file = folder.appendingPathExtension("zip")
        try archive.write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let ditto = Process()
        ditto.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        ditto.arguments = ["-x", "-k", file.path, folder.path]
        try ditto.run()
        ditto.waitUntilExit()
        guard ditto.terminationStatus == 0 else { throw CocoaError(.fileReadCorruptFile) }
    }

    @MainActor
    private func replace(_ identifier: String, with unpacked: URL) async {
        let folder = Self.folder.appending(path: identifier)
        do {
            if let loaded = contexts.first(where: { $0.uniqueIdentifier == identifier }) {
                try controller.unload(loaded)
                contexts.removeAll { $0 === loaded }
            }
            try FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: folder)
            try FileManager.default.moveItem(at: unpacked, to: folder)
            await load(folder)
        } catch {
            browser?.ask("No se pudo instalar la extensión", detail: error.localizedDescription, buttons: ["Aceptar"]) { _ in }
        }
    }

    private func supplyMissingAPIs(in folder: URL) throws {
        try ExtensionShim.script.write(to: folder.appending(path: ExtensionShim.shimFile), atomically: true, encoding: .utf8)
        let manifest = folder.appending(path: "manifest.json")
        guard let wrapped = try ExtensionShim.wrapping(Data(contentsOf: manifest)) else { return }
        try wrapped.worker.write(to: folder.appending(path: ExtensionShim.workerFile), atomically: true, encoding: .utf8)
        try wrapped.manifest.write(to: manifest)
    }

    @MainActor
    private func load(_ folder: URL) async {
        do {
            try supplyMissingAPIs(in: folder)
            let webExtension = try await WKWebExtension(resourceBaseURL: folder)
            let context = WKWebExtensionContext(for: webExtension)
            context.uniqueIdentifier = folder.lastPathComponent
            context.isInspectable = true
            for permission in webExtension.requestedPermissions {
                context.setPermissionStatus(.grantedExplicitly, for: permission)
            }
            for pattern in webExtension.allRequestedMatchPatterns {
                context.setPermissionStatus(.grantedExplicitly, for: pattern)
            }
            try controller.load(context)
            contexts.append(context)
            if webExtension.hasBackgroundContent {
                try await context.loadBackgroundContent()
            }
            NSLog("Extensión cargada: %@", webExtension.displayName ?? folder.lastPathComponent)
        } catch {
            NSLog("La extensión %@ no se pudo cargar: %@", folder.lastPathComponent, "\(error)")
        }
    }
}
