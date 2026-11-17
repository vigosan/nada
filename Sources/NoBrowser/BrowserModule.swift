import NoBrowserCore
import WebKit

protocol BrowserModule: AnyObject {
    var commands: [ModuleCommand] { get }
    var settings: [Setting] { get }
    func configure(_ configuration: WKWebViewConfiguration)
    func run(_ commandID: String)
    func changeSetting(_ settingID: String)
}
