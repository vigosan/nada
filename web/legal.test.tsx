import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { Privacy, Support } from "./components/Legal";
import { CONTACT, content, LANGS } from "./content";

describe("support", () => {
  it("offers a button to write to support, since writing is the one thing people come to this page to do", () => {
    const html = renderToStaticMarkup(<Support c={content.es} />);
    expect(html).toContain(`data-testid="support-email" href="mailto:${CONTACT}"`);
    expect(html).toContain(content.es.support.email);
  });
});

describe("privacy", () => {
  it("covers both the app and this website, so neither is left unexplained", () => {
    for (const lang of LANGS) {
      const html = renderToStaticMarkup(<Privacy c={content[lang]} />);
      expect(content[lang].privacy.sections).toHaveLength(2);
      for (const section of content[lang].privacy.sections) expect(html).toContain(section.heading);
    }
  });

  it("says where the app looks for updates, since that is the one connection nobody asked it to make", () => {
    for (const lang of LANGS) {
      const html = renderToStaticMarkup(<Privacy c={content[lang]} />);
      expect(html).toContain("nada.vicent.io/appcast.xml");
      expect(html).toContain("GitHub");
    }
  });
});
