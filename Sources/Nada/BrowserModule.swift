import NadaCore
import WebKit

protocol BrowserModule: AnyObject {
    var commands: [ModuleCommand] { get }
    var settings: [Setting] { get }
    func configure(_ configuration: WKWebViewConfiguration)
    func run(_ commandID: String)
    func changeSetting(_ settingID: String)
    func whenReady(_ action: @escaping () -> Void)
}

extension BrowserModule {
    func whenReady(_ action: @escaping () -> Void) {
        action()
    }
}
