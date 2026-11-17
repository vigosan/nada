import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { Download } from "./components/Download";
import { Home } from "./components/Home";
import { content } from "./content";

describe("home", () => {
  it("shows the demo before the explanations, so the browser is seen before it is described", () => {
    const html = renderToStaticMarkup(<Home c={content.en} />);
    expect(html.indexOf('data-testid="demo"')).toBeGreaterThan(-1);
    expect(html.indexOf('data-testid="demo"')).toBeLessThan(html.indexOf(content.en.home.sections[0].title));
  });

  it("links the Spanish page from the English one, so nobody is stuck in the wrong language", () => {
    const html = renderToStaticMarkup(<Home c={content.en} />);
    expect(html).toContain('href="/es"');
  });
});

describe("download", () => {
  it("says the download is coming instead of offering a dead link while there is no release", () => {
    const html = renderToStaticMarkup(<Download home={content.en.home} url={null} />);
    expect(html).toContain('data-testid="download-soon"');
    expect(html).not.toContain("<a ");
  });

  it("offers the download once a release exists", () => {
    const html = renderToStaticMarkup(<Download home={content.en.home} url="https://example.com/Nada.dmg" />);
    expect(html).toContain('href="https://example.com/Nada.dmg"');
    expect(html).toContain(content.en.home.download);
  });
});
