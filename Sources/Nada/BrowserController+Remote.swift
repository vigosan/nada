import AppKit
import NadaCore
import WebKit

extension BrowserController {
    func answer(_ request: RemoteRequest) async -> RemoteResponse {
        switch request {
        case .open(let address):
            guard let url = resolve(address) else { return RemoteResponse(ok: false, output: "no sé abrir «\(address)»") }
            open(url)
            return RemoteResponse(ok: true, output: "")
        case .tabs(let json):
            return RemoteResponse(ok: true, output: RemoteTab.render(remoteTabs, json: json))
        case .eval(let script):
            return await evaluate(script)
        case .text:
            return await evaluate("document.body.innerText")
        case .screenshot(let path):
            return await screenshot(to: path)
        }
    }

    private func evaluate(_ script: String) async -> RemoteResponse {
        guard let webView = focusedPane?.webView else { return RemoteResponse(ok: false, output: "no hay página activa") }
        do {
            return RemoteResponse(ok: true, output: RemoteResult.render(try await run("return (\n\(script)\n);", in: webView)))
        } catch where message(of: error).hasPrefix("SyntaxError") {
            do {
                return RemoteResponse(ok: true, output: RemoteResult.render(try await run(script, in: webView)))
            } catch {
                return RemoteResponse(ok: false, output: message(of: error))
            }
        } catch {
            return RemoteResponse(ok: false, output: message(of: error))
        }
    }

    private func run(_ body: String, in webView: WKWebView) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            webView.callAsyncJavaScript(body, arguments: [:], in: nil, in: .page) { result in
                continuation.resume(with: result.map { $0 as Any? })
            }
        }
    }

    private func message(of error: Error) -> String {
        (error as NSError).userInfo["WKJavaScriptExceptionMessage"] as? String ?? error.localizedDescription
    }

    private func screenshot(to path: String) async -> RemoteResponse {
        guard let webView = focusedPane?.webView else { return RemoteResponse(ok: false, output: "no hay página activa") }
        do {
            let image = try await webView.takeSnapshot(configuration: nil)
            guard let tiff = image.tiffRepresentation,
                  let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
            else { return RemoteResponse(ok: false, output: "la captura no se pudo convertir a PNG") }
            try png.write(to: URL(fileURLWithPath: path))
            return RemoteResponse(ok: true, output: path)
        } catch {
            return RemoteResponse(ok: false, output: error.localizedDescription)
        }
    }
}
