public enum ExtensionShim {
    public static let chromeVersion = 150
    public static let userAgentSuffix = "Chrome/\(chromeVersion).0.0.0 Safari/537.36"

    public static let script = """
    (() => {
      const event = () => ({ addListener() {}, removeListener() {}, hasListener() { return false; } });
      const answer = (value, callback) => {
        if (typeof callback === "function") callback(value);
        return Promise.resolve(value);
      };
      const notifications = {
        onClicked: event(), onClosed: event(), onButtonClicked: event(), onShown: event(),
        create: (id, options, callback) => answer(typeof id === "string" ? id : "nada", typeof options === "function" ? options : callback),
        clear: (id, callback) => answer(true, callback),
        update: (id, options, callback) => answer(false, callback),
        getAll: (callback) => answer({}, callback),
      };
      for (const root of [window.chrome, window.browser]) {
        if (!root) continue;
        try {
          if (!root.notifications) root.notifications = notifications;
          if (root.webNavigation && !root.webNavigation.onCreatedNavigationTarget) root.webNavigation.onCreatedNavigationTarget = event();
        } catch (error) {}
      }
    })();
    """
}
