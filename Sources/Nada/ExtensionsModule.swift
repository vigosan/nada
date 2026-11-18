import AppKit
import NadaCore
import WebKit

final class ExtensionsModule: NSObject, BrowserModule, WKWebExtensionControllerDelegate {
    static let folder = URL.applicationSupportDirectory.appending(path: "Nada/extensions")

    let controller: WKWebExtensionController
    private(set) var contexts: [WKWebExtensionContext] = []
    weak var browser: BrowserController?

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
            let name = $0.webExtension.displayShortName ?? $0.webExtension.displayName ?? $0.uniqueIdentifier
            return ModuleCommand(id: "extension:\($0.uniqueIdentifier)", title: "Extensión: \(name)")
        } + [ModuleCommand(id: "extensions.folder", title: "Abrir carpeta de extensiones")]
    }

    var settings: [Setting] {
        []
    }

    func configure(_ configuration: WKWebViewConfiguration) {
        configuration.webExtensionController = controller
    }

    func run(_ commandID: String) {
        if commandID == "extensions.folder" {
            try? FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
            NSWorkspace.shared.open(Self.folder)
            return
        }
        contexts.first { "extension:\($0.uniqueIdentifier)" == commandID }?.performAction(for: browser?.focusedPane)
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

    private func open(_ url: URL?, for context: WKWebExtensionContext) -> Pane? {
        let own = url?.scheme == context.baseURL.scheme && url?.host() == context.baseURL.host()
        return browser?.openExtensionPage(url, configuration: own ? context.webViewConfiguration : nil)
    }

    private func confirm(_ wanted: [String], for context: WKWebExtensionContext, completion: @escaping (Bool) -> Void) {
        guard let browser else {
            completion(false)
            return
        }
        let name = context.webExtension.displayShortName ?? context.webExtension.displayName ?? context.uniqueIdentifier
        browser.ask("«\(name)» pide permiso", detail: wanted.joined(separator: "\n"), buttons: ["Permitir", "No permitir"]) {
            completion($0 == .alertFirstButtonReturn)
        }
    }

    @MainActor
    private func load(_ folder: URL) async {
        do {
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
