import Foundation

public enum ExtensionShim {
    public static let chromeVersion = 150
    public static let userAgentSuffix = "Chrome/\(chromeVersion).0.0.0 Safari/537.36"

    public static let shimFile = "nada-shim.js"
    public static let workerFile = "nada-background.js"

    public struct Wrapped: Equatable {
        public let manifest: Data
        public let worker: String
    }

    public static func wrapping(_ manifest: Data) -> Wrapped? {
        guard var json = (try? JSONSerialization.jsonObject(with: manifest)) as? [String: Any],
              var background = json["background"] as? [String: Any],
              let original = background["service_worker"] as? String,
              original != workerFile else { return nil }
        background["service_worker"] = workerFile
        json["background"] = background
        guard let wrapped = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) else { return nil }
        let worker = background["type"] as? String == "module"
            ? "import \"./\(shimFile)\";\nimport \"./\(original)\";\n"
            : "importScripts(\"\(shimFile)\", \"\(original)\");\n"
        return Wrapped(manifest: wrapped, worker: worker)
    }

    public static let script = """
    (() => {
      const event = () => ({ addListener() {}, removeListener() {}, hasListener() { return false; } });
      const answer = (value) => (...given) => {
        const callback = given[given.length - 1];
        if (typeof callback === "function") callback(value);
        return Promise.resolve(value);
      };
      const namespaces = {
        notifications: {
          onClicked: event(), onClosed: event(), onButtonClicked: event(), onShown: event(),
          create: (id, ...rest) => answer(typeof id === "string" ? id : "nada")(id, ...rest),
          clear: answer(true), update: answer(false), getAll: answer({}),
        },
      };
      const members = {
        storage: { managed: { get: answer({}), getBytesInUse: answer(0), onChanged: event() } },
        webNavigation: { onCreatedNavigationTarget: event() },
      };
      const kept = globalThis.nadaKept = globalThis.nadaKept || [];
      for (const root of [globalThis.chrome, globalThis.browser]) {
        if (!root) continue;
        for (const [name, value] of Object.entries(namespaces)) {
          try { if (!root[name]) root[name] = value; } catch (error) {}
        }
        for (const [name, extra] of Object.entries(members)) {
          const namespace = root[name];
          if (!namespace) continue;
          kept.push(namespace);
          for (const [key, value] of Object.entries(extra)) {
            try { if (!(key in namespace)) namespace[key] = value; } catch (error) {}
          }
        }
      }
    })();
    """
}
