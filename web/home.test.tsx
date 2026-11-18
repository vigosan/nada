import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { Download } from "./components/Download";
import { Home } from "./components/Home";
import { content, REPO } from "./content";

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

describe("page frame", () => {
  it("links privacy and support from every page footer, in the page's own language", () => {
    const html = renderToStaticMarkup(<Home c={content.es} />);
    expect(html).toContain('href="/es/privacidad"');
    expect(html).toContain('href="/es/soporte"');
  });

  it("links the source code, since the repository is public and people will want to read it", () => {
    const html = renderToStaticMarkup(<Home c={content.en} />);
    expect(html).toContain(`href="${REPO}"`);
  });

  it("lets the visitor switch between system, light and dark", () => {
    const html = renderToStaticMarkup(<Home c={content.en} />);
    expect(html).toContain(`aria-label="${content.en.theme.system}"`);
  });

  it("lets the demo window follow the page theme, because the app itself follows the system", () => {
    const html = renderToStaticMarkup(<Home c={content.en} />);
    expect(html).toContain('data-testid="demo-window"');
    expect(html).not.toContain('data-testid="demo-window" data-theme');
  });

  it("shows the reload shortcut as a key in the config section, so editing the file does not look like it needs a restart", () => {
    const html = renderToStaticMarkup(<Home c={content.en} />);
    const config = html.slice(html.indexOf(content.en.home.configTitle), html.indexOf('data-testid="closing"'));
    expect(config).toContain(">⇧⌘,</kbd>");
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
