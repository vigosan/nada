public enum PlaybackSpeed {
    public static func change(by step: Double) -> String {
        #"""
        (() => {
          const area = el => { const r = el.getBoundingClientRect(); return r.width * r.height; };
          const video = [...document.querySelectorAll("video")].filter(v => area(v) > 0).sort((a, b) => area(b) - area(a))[0];
          if (!video) return "none";
          video.playbackRate = Math.min(4, Math.max(0.25, Math.round((video.playbackRate + \#(step)) * 4) / 4));
          const label = video.playbackRate + "×";
          let badge = document.getElementById("nada-playback-speed");
          if (!badge) {
            badge = document.createElement("div");
            badge.id = "nada-playback-speed";
            badge.style.cssText = "position: fixed; top: 16px; left: 50%; transform: translateX(-50%); z-index: 2147483647;" +
              " padding: 6px 12px; border-radius: 8px; background: rgba(0, 0, 0, 0.75); color: #fff;" +
              " font: 600 15px -apple-system, sans-serif; pointer-events: none;";
          }
          (document.fullscreenElement || document.body).appendChild(badge);
          badge.textContent = label;
          clearTimeout(window.__nadaSpeedTimer);
          window.__nadaSpeedTimer = setTimeout(() => badge.remove(), 1200);
          return label;
        })()
        """#
    }
}
