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
