import NadaCore
import WebKit

final class AdBlockModule: BrowserModule {
    private let content = WKUserContentController()
    private var lists: [WKContentRuleList] = []
    private var enabled = !UserDefaults.standard.bool(forKey: "adblock.disabled")

    init() {
        load()
    }

    var commands: [ModuleCommand] {
        []
    }

    func configure(_ configuration: WKWebViewConfiguration) {
        configuration.userContentController = content
    }

    var settings: [Setting] {
        [Setting(id: "adblock.enabled", title: "Bloqueo de anuncios", value: enabled ? "Activado" : "Desactivado")]
    }

    func run(_ commandID: String) {}

    func changeSetting(_ settingID: String) {
        toggle()
    }

    private func toggle() {
        enabled.toggle()
        UserDefaults.standard.set(!enabled, forKey: "adblock.disabled")
        if enabled {
            lists.forEach(content.add)
        } else {
            content.removeAllContentRuleLists()
        }
    }

    private func load() {
        let directory = URL.applicationSupportDirectory.appending(path: "Nada/filters")
        let files = ((try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )) ?? []).filter { $0.pathExtension == "json" }
        guard let store = WKContentRuleListStore.default(), !files.isEmpty else {
            NSLog("Bloqueo de anuncios sin filtros en %@: ejecuta make filters", directory.path)
            return
        }
        let identifiers = files.map(identifier)
        store.getAvailableContentRuleListIdentifiers { available in
            for stale in available ?? [] where !identifiers.contains(stale) {
                store.removeContentRuleList(forIdentifier: stale) { _ in }
            }
        }
        for (file, identifier) in zip(files, identifiers) {
            store.lookUpContentRuleList(forIdentifier: identifier) { [weak self] cached, _ in
                if let cached {
                    self?.add(cached)
                    return
                }
                guard let json = try? String(contentsOf: file, encoding: .utf8) else {
                    NSLog("Bloqueo de anuncios: no se puede leer %@", file.path)
                    return
                }
                store.compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: json) { compiled, error in
                    if let error {
                        NSLog("Bloqueo de anuncios: %@ no compila: %@", file.lastPathComponent, "\(error)")
                    }
                    compiled.map { self?.add($0) }
                }
            }
        }
    }

    private func identifier(for file: URL) -> String {
        let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        return "\(file.deletingPathExtension().lastPathComponent)-\(Int(modified?.timeIntervalSince1970 ?? 0))"
    }

    private func add(_ list: WKContentRuleList) {
        lists.append(list)
        if enabled { content.add(list) }
    }
}
