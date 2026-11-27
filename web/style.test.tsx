import { readFileSync } from "node:fs";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { Home } from "./components/Home";
import { Privacy, Support } from "./components/Legal";
import { content, DOWNLOAD, LANGS } from "./content";

const css = readFileSync(new URL("./app/globals.css", import.meta.url), "utf8");

const TOKENS = ["canvas", "ink", "body", "muted", "faint", "line", "line-strong", "wash", "press", "ring", "accent"];

const block = (selector: string) => {
  const start = css.indexOf(`${selector} {`);
  return start === -1 ? "" : css.slice(start, css.indexOf("}", start));
};

const pages = LANGS.flatMap((lang) => [<Home key="home" c={content[lang]} />, <Privacy key="privacy" c={content[lang]} />, <Support key="support" c={content[lang]} />]).map(
  (page) => renderToStaticMarkup(page),
);

describe("colors", () => {
  it("gives every color token a dark value, so nothing is left light on light when the page turns dark", () => {
    for (const token of TOKENS) {
      expect(block("@theme")).toContain(`--color-${token}:`);
      expect(block('[data-theme="dark"]')).toContain(`--color-${token}:`);
    }
  });

  it("keeps Nada's blue as the one accent, so the site still reads as the same product", () => {
    expect(block("@theme")).toContain("--color-accent: #1583bd");
    expect(block('[data-theme="dark"]')).toContain("--color-accent: #6cc4f2");
  });
});

describe("frame", () => {
  it("names the product and says what it is at the top of every page, so someone landing on support knows where they are", () => {
    for (const lang of LANGS) {
      for (const page of [<Home key="home" c={content[lang]} />, <Privacy key="privacy" c={content[lang]} />, <Support key="support" c={content[lang]} />]) {
        const html = renderToStaticMarkup(page);
        const header = html.slice(html.indexOf("<header"), html.indexOf("</header>"));
        expect(header).toContain(">Nada<");
        expect(header).toContain(content[lang].home.tagline);
      }
    }
  });

  it("gives the home page one top heading, the product's name, so search engines and screen readers know what the page is about", () => {
    for (const lang of LANGS) {
      const html = renderToStaticMarkup(<Home c={content[lang]} />);
      expect(html.match(/<h1[^>]*>.*?<\/h1>/g)).toHaveLength(1);
      expect(html).toMatch(/<h1[^>]*>Nada<\/h1>/);
    }
  });

  it("never spreads headings apart, since Geist Mono is already wide", () => {
    for (const html of pages) expect(html).not.toMatch(/tracking-(wide|wider|widest)/);
  });
});

describe("surfaces", () => {
  it("draws the demo, the screenshot and the keys flat with a 1px line, so the product is shown plainly and nothing floats above the text", () => {
    for (const html of pages) expect(html).not.toMatch(/\bshadow-/);
  });
});

describe("selection", () => {
  it("tints selected text with Nada's blue, so copying a shortcut feels like the product and not the browser default", () => {
    expect(css).toMatch(/::selection\s*{[^}]*var\(--color-accent\)/);
  });
});

describe("type", () => {
  it("sets every page in one monospace, so the site reads like the terminal tools Nada sits beside", () => {
    expect(css).toContain("--font-mono: var(--font-geist-mono)");
    expect(css).not.toContain("--font-sans");
    for (const html of pages) {
      expect(html).not.toContain("font-sans");
      expect(html).not.toMatch(/style="[^"]*font-family/);
    }
  });
});

describe("links", () => {
  it("gives every link the shared link style, so they all answer hover, press and keyboard focus the same way", () => {
    for (const html of pages) {
      for (const anchor of html.match(/<a [^>]*>/g)!) expect(anchor).toMatch(/class="[^"]*\blink\b/);
    }
  });

  it("marks links that leave the site with ↗, so nobody is surprised to land on GitHub", () => {
    for (const html of pages) {
      const external = [...html.matchAll(/<a [^>]*href="(https?:[^"]+)"[^>]*>(.*?)<\/a>/g)].filter(([, href]) => href !== DOWNLOAD);
      expect(external.length).toBeGreaterThan(0);
      for (const [, , text] of external) expect(text).toContain("↗");
    }
  });

  it("only paints hover backgrounds on devices that can hover, so a tap on a phone does not leave a link highlighted", () => {
    expect(css).toMatch(/@media \(hover: hover\) and \(pointer: fine\)\s*{\s*\.link:hover/);
  });

  it("acknowledges a press at once, so a link feels like it heard the click", () => {
    expect(css).toMatch(/\.link:active\s*{[^}]*transition-duration: 0ms/);
  });

  it("rings links for keyboard users only, so clicking with a mouse does not flash an outline", () => {
    expect(css).toContain(".link:focus-visible");
    expect(css).not.toMatch(/\.link:focus\s*{/);
  });
});

describe("motion", () => {
  it("shows the content on the first frame, so nobody waits for words to slide in before reading them", () => {
    for (const html of pages) {
      const main = html.slice(html.indexOf("<main"), html.indexOf("</main>"));
      expect(main).not.toContain("starting:");
    }
  });

  it("does not tie decoration to scrolling, so the page stays still while it is read", () => {
    expect(css).not.toContain("animation-timeline");
  });
});

describe("lists", () => {
  it("lists the shortcut groups as one list, so a screen reader announces how many groups there are", () => {
    for (const lang of LANGS) {
      const html = renderToStaticMarkup(<Home c={content[lang]} />);
      expect(html.match(/<li[^>]*data-testid="shortcut-group"/g)).toHaveLength(content[lang].home.shortcuts.length);
    }
  });

  it("keeps the accent bar for the download alone, so the blue points at the one thing to do", () => {
    for (const lang of LANGS) {
      expect(renderToStaticMarkup(<Home c={content[lang]} />).match(/\bborder-accent\b/g)).toHaveLength(2);
      expect(renderToStaticMarkup(<Support c={content[lang]} />)).not.toMatch(/\bborder-accent\b/);
    }
  });
});
