public enum VimKeys {
    public static let script = #"""
    (() => {
      if (window.__nadaVimKeys) return;
      window.__nadaVimKeys = true;

      const chars = "sadfjklewcmpgh";
      const selector = [
        "a[href]", "button", "input:not([type=hidden])", "textarea", "select", "summary",
        "[role=button]", "[role=link]", "[role=tab]", "[role=menuitem]", "[role=checkbox]",
        "[onclick]", "[contenteditable=true]", "[tabindex]:not([tabindex='-1'])",
      ].join(",");
      const modifiers = ["Shift", "Meta", "Control", "Alt", "CapsLock"];
      let hints = null;
      let lastG = 0;

      const takesText = (el) =>
        el.isContentEditable || el.tagName === "TEXTAREA" || el.tagName === "SELECT" ||
        (el.tagName === "INPUT" && !/^(button|submit|reset|checkbox|radio|file|image)$/.test(el.type));

      const typing = () => {
        let el = document.activeElement;
        while (el && el.shadowRoot && el.shadowRoot.activeElement) el = el.shadowRoot.activeElement;
        return !!el && takesText(el);
      };

      const scroller = () => {
        const root = document.scrollingElement || document.documentElement;
        if (root.scrollHeight > root.clientHeight + 1 || root.scrollWidth > root.clientWidth + 1) return root;
        for (let el = document.elementFromPoint(innerWidth / 2, innerHeight / 2); el; el = el.parentElement) {
          if (el.scrollHeight > el.clientHeight + 1 && /auto|scroll/.test(getComputedStyle(el).overflowY)) return el;
        }
        return root;
      };

      const scroll = (left, top, smooth) => scroller().scrollBy({ left, top, behavior: smooth ? "smooth" : "instant" });

      const jump = (toTop) => {
        const el = scroller();
        el.scrollTo({ top: toTop ? 0 : el.scrollHeight, behavior: "instant" });
      };

      const labels = (count) => {
        let length = 1;
        while (chars.length ** length < count) length++;
        return Array.from({ length: count }, (_, index) => {
          let label = "";
          for (let digit = 0, rest = index; digit < length; digit++, rest = Math.floor(rest / chars.length)) {
            label = chars[rest % chars.length] + label;
          }
          return label;
        });
      };

      const visible = (el) => {
        const rect = el.getBoundingClientRect();
        if (rect.width < 3 || rect.height < 3) return false;
        if (rect.bottom <= 0 || rect.right <= 0 || rect.top >= innerHeight || rect.left >= innerWidth) return false;
        const style = getComputedStyle(el);
        return style.visibility !== "hidden" && style.opacity !== "0";
      };

      const showHints = (newTab) => {
        const targets = [...document.querySelectorAll(selector)].filter(visible);
        if (!targets.length) return;
        const host = document.createElement("div");
        host.id = "nada-hints";
        host.style.cssText = "position:fixed;inset:0;z-index:2147483647;pointer-events:none";
        const root = host.attachShadow({ mode: "open" });
        const style = document.createElement("style");
        style.textContent =
          "span{position:fixed;font:700 11px/1.2 ui-monospace,Menlo,monospace;text-transform:uppercase;" +
          "color:#13141c;background:#6cc4f2;border-radius:3px;padding:1px 4px;box-shadow:0 1px 3px rgba(0,0,0,.45)}" +
          "span[hidden]{display:none}";
        root.append(style);
        const names = labels(targets.length);
        const items = targets.map((el, index) => {
          const rect = el.getBoundingClientRect();
          const tag = document.createElement("span");
          tag.textContent = names[index];
          tag.style.left = Math.max(0, rect.left) + "px";
          tag.style.top = Math.max(0, rect.top) + "px";
          root.append(tag);
          return { el, tag, label: names[index] };
        });
        document.documentElement.append(host);
        hints = { host, items, typed: "", newTab };
      };

      const hideHints = () => {
        hints.host.remove();
        hints = null;
      };

      const activate = (el, newTab) => {
        if (newTab && el.href) {
          if (!window.open(el.href, "_blank")) location.href = el.href;
        } else if (takesText(el)) {
          el.focus();
        } else {
          el.click();
        }
      };

      const onHintKey = (event) => {
        if (modifiers.includes(event.key)) return;
        const key = event.key.toLowerCase();
        if (event.key === "Backspace") hints.typed = hints.typed.slice(0, -1);
        else if (key.length === 1 && chars.includes(key)) hints.typed += key;
        else return hideHints();
        const matching = hints.items.filter((item) => item.label.startsWith(hints.typed));
        hints.items.forEach((item) => (item.tag.hidden = !item.label.startsWith(hints.typed)));
        if (!matching.length) return hideHints();
        if (matching.length === 1 && matching[0].label === hints.typed) {
          const { el } = matching[0];
          const newTab = hints.newTab;
          hideHints();
          activate(el, newTab);
        }
      };

      window.addEventListener("scroll", () => hints && hideHints(), true);

      window.addEventListener("keydown", (event) => {
        if (event.metaKey || event.ctrlKey || event.altKey) return;
        if (hints) {
          event.preventDefault();
          event.stopImmediatePropagation();
          onHintKey(event);
          return;
        }
        if (typing()) return;
        const smooth = !event.repeat;
        const actions = {
          j: () => scroll(0, 80, smooth),
          k: () => scroll(0, -80, smooth),
          h: () => scroll(-80, 0, smooth),
          l: () => scroll(80, 0, smooth),
          d: () => scroll(0, innerHeight / 2, true),
          u: () => scroll(0, -innerHeight / 2, true),
          G: () => jump(false),
          f: () => showHints(false),
          F: () => showHints(true),
          g: () => {
            if (Date.now() - lastG < 600) jump(true);
            lastG = Date.now() - lastG < 600 ? 0 : Date.now();
          },
        };
        if (!Object.hasOwn(actions, event.key)) return;
        actions[event.key]();
        event.preventDefault();
        event.stopImmediatePropagation();
      }, true);
    })();
    """#
}
