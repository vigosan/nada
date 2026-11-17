import NoBrowserCore
import WebKit

protocol BrowserModule: AnyObject {
    var commands: [ModuleCommand] { get }
    func configure(_ configuration: WKWebViewConfiguration)
    func run(_ commandID: String)
}
