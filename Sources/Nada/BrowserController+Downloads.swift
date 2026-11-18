import AppKit
import NadaCore
import WebKit

extension BrowserController: WKDownloadDelegate {
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
}
