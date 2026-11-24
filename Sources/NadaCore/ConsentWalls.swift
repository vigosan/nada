public enum ConsentWalls {
    public static let unlockScroll = #"""
    (() => {
      const sheet = new CSSStyleSheet();
      sheet.replaceSync(
        "html.didomi-popup-open, body.didomi-popup-open, html.sp-message-open, body.sp-message-open" +
        "{ overflow: auto !important; position: static !important; }"
      );
      document.adoptedStyleSheets = [...document.adoptedStyleSheets, sheet];
    })();
    """#

    public static let rejectYouTube = #"""
    (() => {
      if (!/(^|\.)youtube\.com$/.test(location.hostname)) return;
      const observer = new MutationObserver(() => {
        const reject = document.querySelector("ytd-consent-bump-v2-lightbox .eom-buttons button");
        if (!reject) return;
        observer.disconnect();
        reject.click();
      });
      observer.observe(document, { childList: true, subtree: true });
      setTimeout(() => observer.disconnect(), 30000);
    })();
    """#
}
