import Testing
@testable import NadaCore

@Suite("Las descargas se pueden seguir sin una ventana aparte")
struct DownloadsTests {
    @Test("la descarga más reciente va primero, que es la que se acaba de pedir")
    func newestComesFirst() {
        var list = DownloadList()
        _ = list.start(name: "a.zip")
        _ = list.start(name: "b.zip")
        #expect(list.items.map(\.name) == ["b.zip", "a.zip"])
    }

    @Test("el progreso resume lo que falta de todo lo que está bajando, y desaparece cuando no baja nada")
    func progressCoversWhatIsStillRunning() {
        var list = DownloadList()
        #expect(list.progress == nil)
        let first = list.start(name: "a.zip")
        let second = list.start(name: "b.zip")
        list.update(first, to: .running(0.5))
        #expect(list.progress == 0.25)
        list.update(second, to: .finished)
        #expect(list.progress == 0.5)
        #expect(list.running == 1)
        list.update(first, to: .finished)
        #expect(list.progress == nil)
    }

    @Test("una descarga que ya terminó, falló o se canceló no vuelve a ponerse en marcha por un aviso tardío")
    func settledDownloadsStaySettled() {
        var list = DownloadList()
        let id = list.start(name: "a.zip")
        list.update(id, to: .cancelled)
        list.update(id, to: .running(0.9))
        list.update(id, to: .failed)
        #expect(list.items.first?.state == .cancelled)
    }
}
