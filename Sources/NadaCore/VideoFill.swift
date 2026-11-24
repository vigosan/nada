public enum VideoFill {
    public static let toggle = #"""
    (() => {
      const root = document.documentElement;
      const restore = () => {
        document.querySelectorAll("[data-nada-fill], [data-nada-fill-path], [data-nada-fill-inner]").forEach(el => {
          el.removeAttribute("data-nada-fill");
          el.removeAttribute("data-nada-fill-path");
          el.removeAttribute("data-nada-fill-inner");
        });
        root.removeAttribute("data-nada-filling");
        document.removeEventListener("keydown", window.__nadaFillEscape, true);
        delete window.__nadaFillEscape;
        dispatchEvent(new Event("resize"));
      };
      if (root.hasAttribute("data-nada-filling")) {
        restore();
        return "off";
      }
      const area = el => { const r = el.getBoundingClientRect(); return r.width * r.height; };
      const video = [...document.querySelectorAll("video")].filter(v => area(v) > 0).sort((a, b) => area(b) - area(a))[0];
      if (!video) return "none";
      const size = video.getBoundingClientRect();
      let player = video;
      while (player.parentElement && player.parentElement !== document.body) {
        const r = player.parentElement.getBoundingClientRect();
        if (r.width > size.width + 2 || r.height > size.height + 2) break;
        player = player.parentElement;
      }
      if (!window.__nadaFillSheet) {
        window.__nadaFillSheet = new CSSStyleSheet();
        window.__nadaFillSheet.replaceSync(
          "[data-nada-fill] { position: fixed !important; inset: 0 !important; width: 100vw !important; height: 100vh !important;" +
          " max-width: none !important; max-height: none !important; margin: 0 !important; transform: none !important;" +
          " z-index: 2147483647 !important; background: #000 !important; object-fit: contain !important; }" +
          "[data-nada-fill] video { position: absolute !important; inset: 0 !important; width: 100% !important; height: 100% !important;" +
          " max-width: none !important; max-height: none !important; transform: none !important; object-fit: contain !important; }" +
          "[data-nada-fill-inner] { width: 100% !important; height: 100% !important; max-width: none !important;" +
          " max-height: none !important; top: 0 !important; left: 0 !important; margin: 0 !important; padding: 0 !important; transform: none !important; }" +
          "[data-nada-fill-path] { transform: none !important; filter: none !important; contain: none !important;" +
          " will-change: auto !important; z-index: 2147483647 !important; }" +
          "html[data-nada-filling], html[data-nada-filling] body { overflow: hidden !important; }"
        );
        document.adoptedStyleSheets = [...document.adoptedStyleSheets, window.__nadaFillSheet];
      }
      for (let el = player.parentElement; el; el = el.parentElement) el.setAttribute("data-nada-fill-path", "");
      for (let el = video.parentElement; el && el !== player; el = el.parentElement) el.setAttribute("data-nada-fill-inner", "");
      player.setAttribute("data-nada-fill", "");
      root.setAttribute("data-nada-filling", "");
      window.__nadaFillEscape = event => {
        if (event.key !== "Escape") return;
        event.stopPropagation();
        restore();
      };
      document.addEventListener("keydown", window.__nadaFillEscape, true);
      dispatchEvent(new Event("resize"));
      return "on";
    })()
    """#
}
