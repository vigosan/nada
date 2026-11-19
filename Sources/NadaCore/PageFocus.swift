public enum PageFocus {
    public static let isTyping = #"""
    (() => {
      let el = document.activeElement;
      while (el && el.shadowRoot && el.shadowRoot.activeElement) el = el.shadowRoot.activeElement;
      return !!el && (el.isContentEditable || el.tagName === "TEXTAREA" ||
        (el.tagName === "INPUT" && !/^(button|submit|reset|checkbox|radio|file|image|range|color)$/.test(el.type)));
    })()
    """#
}
