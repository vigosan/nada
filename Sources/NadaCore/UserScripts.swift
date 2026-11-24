import WebKit

extension WKUserContentController {
    public func setUserScript(_ script: WKUserScript, enabled: Bool) {
        let others = userScripts.filter { $0 !== script }
        removeAllUserScripts()
        others.forEach(addUserScript)
        if enabled { addUserScript(script) }
    }
}
