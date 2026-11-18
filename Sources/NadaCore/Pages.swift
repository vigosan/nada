import Foundation

public enum ErrorPage {
    public static func html(url: URL, reason: String) -> String {
        """
        <!doctype html>
        <meta charset="utf-8">
        <meta name="color-scheme" content="dark">
        <title>No se puede abrir \(escape(url.host() ?? url.absoluteString))</title>
        <style>
          body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #1b1c27; color: #a3a7c2; font: 15px/1.6 -apple-system, sans-serif; }
          main { max-width: 32rem; padding: 2rem; }
          h1 { margin: 0 0 .5rem; color: #cdd0e6; font-size: 1.4rem; }
          p { margin: 0 0 1.25rem; }
          a { color: #6cc4f2; }
        </style>
        <main>
          <h1>No se puede abrir \(escape(url.host() ?? url.absoluteString))</h1>
          <p>\(escape(reason))</p>
          <a href="\(escape(url.absoluteString))">Reintentar</a>
        </main>
        """
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

public enum LinkClick {
    public static func opensNewTab(command: Bool, button: Int) -> Bool {
        command || button == 2
    }
}

public enum Challenge: Equatable {
    case credentials
    case trust
    case system

    public init(method: String) {
        switch method {
        case NSURLAuthenticationMethodHTTPBasic, NSURLAuthenticationMethodHTTPDigest, NSURLAuthenticationMethodNTLM:
            self = .credentials
        case NSURLAuthenticationMethodServerTrust:
            self = .trust
        default:
            self = .system
        }
    }
}

public enum Downloads {
    public static func freeName(for suggested: String, exists: (String) -> Bool) -> String {
        let last = (suggested as NSString).lastPathComponent
        let name = ["", ".", "..", "/"].contains(last) ? "descarga" : last
        guard exists(name) else { return name }
        let base = (name as NSString).deletingPathExtension
        let suffix = (name as NSString).pathExtension.isEmpty ? "" : "." + (name as NSString).pathExtension
        var number = 2
        while exists("\(base) \(number)\(suffix)") { number += 1 }
        return "\(base) \(number)\(suffix)"
    }
}

public struct SessionPage: Codable, Equatable {
    public let url: URL
    public let title: String

    public init(url: URL, title: String) {
        self.url = url
        self.title = title
    }
}

public struct Session: Codable {
    public let tabs: [SessionPage]
    public let active: Int

    public init(pages: [SessionPage?], active: Int) {
        tabs = pages.compactMap { $0 }
        self.active = max(0, min(tabs.count - 1, pages.prefix(active).compactMap { $0 }.count))
    }
}

public enum TabLabel {
    public static func text(title: String, address: URL?, active: Bool) -> String {
        guard active, let address, let scheme = address.scheme, ["http", "https"].contains(scheme),
              let host = address.host(percentEncoded: false) else { return title }
        let bare = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        let site = scheme == "http" ? "http://\(bare)" : bare
        return title == host || title == bare ? site : "\(site) — \(title)"
    }
}
