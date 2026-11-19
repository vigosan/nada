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
}
