import { describe, expect, it } from "vitest";
import { CONFIG_SAMPLE, content, LANGS } from "./content";

const keys = (value: unknown): string[] =>
  value && typeof value === "object"
    ? Object.entries(value).flatMap(([k, v]) => [k, ...keys(v).map((sub) => `${k}.${sub}`)])
    : [];

describe("site content", () => {
  it("has the same sections in English and Spanish, so no page is left half translated", () => {
    expect(keys(content.es)).toEqual(keys(content.en));
  });

  it("lists the same shortcuts in both languages, so nobody learns a key that the other page hides", () => {
    const shortcuts = (lang: (typeof LANGS)[number]) =>
      content[lang].home.shortcuts.map((group) => group.items.map((item) => item.keys));
    expect(shortcuts("es")).toEqual(shortcuts("en"));
    expect(shortcuts("en").flat().length).toBeGreaterThan(15);
  });

  it("configures more than keys in the sample, so nobody thinks the file is only for shortcuts", () => {
    expect(CONFIG_SAMPLE).toContain("theme = ");
    expect(CONFIG_SAMPLE).toContain("keybind = ");
  });
});
