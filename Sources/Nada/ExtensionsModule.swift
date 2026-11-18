import AppKit
import NadaCore
import WebKit

final class ExtensionsModule: NSObject, BrowserModule {
    static let folder = URL.applicationSupportDirectory.appending(path: "Nada/extensions")

    let controller: WKWebExtensionController
    private(set) var contexts: [WKWebExtensionContext] = []

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
        let folders = ((try? FileManager.default.contentsOfDirectory(at: Self.folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { FileManager.default.fileExists(atPath: $0.appending(path: "manifest.json").path) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        Task { @MainActor in
            for folder in folders { await load(folder) }
        }
    }

    var commands: [ModuleCommand] {
        []
    }

    var settings: [Setting] {
        []
    }

    func configure(_ configuration: WKWebViewConfiguration) {
        configuration.webExtensionController = controller
    }

    func run(_ commandID: String) {}

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
