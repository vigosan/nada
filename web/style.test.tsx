import { readFileSync } from "node:fs";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { Home } from "./components/Home";
import { Privacy, Support } from "./components/Legal";
import { content, LANGS } from "./content";

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
