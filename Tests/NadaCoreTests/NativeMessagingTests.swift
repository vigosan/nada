import Foundation
import Testing
@testable import NadaCore

@Suite("Una extensión habla con su app de escritorio como lo haría en Chrome")
struct NativeMessagingTests {
    private let id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"

    private func manifest(name: String = "com.1password.1password", type: String = "stdio", origins: [String]? = nil) -> Data {
        let allowed = (origins ?? ["chrome-extension://\(id)/"]).map { "\"\($0)\"" }.joined(separator: ",")
        return Data(#"{"name":"\#(name)","path":"/Applications/App.app/helper","type":"\#(type)","allowed_origins":[\#(allowed)]}"#.utf8)
    }

    @Test("la app se lanza solo si su manifiesto nombra a esta extensión, porque es ella quien decide con quién habla")
    func launchesOnlyForAllowedExtensions() {
        let host = NativeHost(manifest: manifest(), name: "com.1password.1password", extension: id)
        #expect(host?.path == "/Applications/App.app/helper")
        #expect(host?.origin == "chrome-extension://\(id)/")
        #expect(NativeHost(manifest: manifest(origins: ["chrome-extension://otra/"]), name: "com.1password.1password", extension: id) == nil)
    }

    @Test("un manifiesto de otra app, o de un tipo que no sea por tubería, no vale")
    func rejectsOtherManifests() {
        #expect(NativeHost(manifest: manifest(name: "com.otra.app"), name: "com.1password.1password", extension: id) == nil)
        #expect(NativeHost(manifest: manifest(type: "socket"), name: "com.1password.1password", extension: id) == nil)
        #expect(NativeHost(manifest: Data("roto".utf8), name: "com.1password.1password", extension: id) == nil)
    }

    @Test("el nombre que pide la extensión se usa como nombre de fichero, así que no puede llevar rutas")
    func namesCannotEscapeTheFolder() {
        #expect(NativeHost.file(for: "com.1password.1password") == "com.1password.1password.json")
        #expect(NativeHost.file(for: "../../etc/passwd") == nil)
        #expect(NativeHost.file(for: "con/barra") == nil)
        #expect(NativeHost.file(for: "") == nil)
        #expect(NativeHost.file(for: ".oculto") == nil)
    }

    @Test("cada mensaje viaja precedido de su tamaño en cuatro bytes, que es como la app sabe dónde acaba")
    func framesAMessage() {
        let framed = NativeMessages.frame(Data(#"{"a":1}"#.utf8))
        #expect(framed == Data([7, 0, 0, 0]) + Data(#"{"a":1}"#.utf8))
    }

    @Test("la respuesta llega a trozos y los mensajes se entregan enteros, uno a uno")
    func reassemblesMessages() {
        var messages = NativeMessages()
        let stream = NativeMessages.frame(Data("uno".utf8)) + NativeMessages.frame(Data("dos!".utf8))
        #expect(messages.receive(stream.prefix(5)) == [])
        #expect(messages.receive(stream.dropFirst(5).prefix(4)) == [Data("uno".utf8)])
        #expect(messages.receive(stream.dropFirst(9)) == [Data("dos!".utf8)])
        #expect(messages.receive(stream) == [Data("uno".utf8), Data("dos!".utf8)])
    }
}
