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
        let id = downloads.start(name: name)
        downloadFiles[id] = folder.appending(path: name)
        let observation = download.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            let fraction = progress.fractionCompleted
            DispatchQueue.main.async { self?.downloadProgressed(id, to: fraction) }
        }
        activeDownloads[ObjectIdentifier(download)] = (id, download, observation)
        downloadsChanged()
        completionHandler(folder.appending(path: name))
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let id = settle(download, as: .finished), let file = downloadFiles[id] else { return }
        DistributedNotificationCenter.default().post(name: Notification.Name("com.apple.DownloadFileFinished"), object: file.path)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let file = settle(download, as: .failed).flatMap { downloadFiles[$0] }
        ask("No se pudo descargar \(file?.lastPathComponent ?? "el archivo")", detail: error.localizedDescription, buttons: ["Aceptar"]) { _ in }
    }

    private func downloadProgressed(_ id: Int, to fraction: Double) {
        guard case .running(let shown)? = downloads.items.first(where: { $0.id == id })?.state,
              Int(shown * 100) != Int(fraction * 100) else { return }
        downloads.update(id, to: .running(fraction))
        downloadsChanged()
    }

    private func settle(_ download: WKDownload, as state: DownloadState) -> Int? {
        guard let active = activeDownloads.removeValue(forKey: ObjectIdentifier(download)) else { return nil }
        downloads.update(active.id, to: state)
        downloadsChanged()
        return active.id
    }
}
