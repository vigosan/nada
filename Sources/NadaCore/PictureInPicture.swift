public enum PictureInPicture {
    public static let toggle = #"""
    (() => {
      const videos = [...document.querySelectorAll("video")];
      const floating = videos.filter(v => v.webkitPresentationMode === "picture-in-picture");
      if (floating.length) {
        floating.forEach(v => v.webkitSetPresentationMode("inline"));
        return "off";
      }
      const area = el => { const r = el.getBoundingClientRect(); return r.width * r.height; };
      const video = videos.filter(v => area(v) > 0).sort((a, b) => area(b) - area(a))[0];
      if (!video) return "none";
      video.webkitSetPresentationMode("picture-in-picture");
      return "on";
    })()
    """#
}
