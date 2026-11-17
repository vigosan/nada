import { describe, expect, it } from "vitest";
import { content } from "./content";
import { apply, INITIAL, paletteItems } from "./demo";

const labels = content.en.demo;

describe("demo palette", () => {
  it("lists every command when empty, so a visitor discovers what the browser does without typing", () => {
    expect(paletteItems("", labels).map((item) => item.action.kind)).toEqual(["newTab", "close", "splitRight", "splitDown"]);
  });

  it("opens an address with enter even when a command also matches, like the real palette", () => {
    const items = paletteItems("split.example", labels);
    expect(items[0].action).toEqual({ kind: "open", title: "split.example" });
  });

  it("runs a matching command before searching the web for its name", () => {
    const items = paletteItems("split", labels);
    expect(items.map((item) => item.action.kind)).toEqual(["splitRight", "splitDown", "open"]);
    expect(items.at(-1)?.title).toBe("Search “split”");
  });
});

describe("demo window", () => {
  it("opens a page in the current tab and names the tab after it", () => {
    expect(apply(INITIAL, { kind: "open", title: "example.com" }).tabs).toEqual([{ title: "example.com", split: null }]);
  });

  it("closes the split first and the tab after, like the real shortcut", () => {
    const split = apply(apply(INITIAL, { kind: "newTab" }), { kind: "splitRight" });
    expect(split.tabs[1].split).toBe("right");
    const unsplit = apply(split, { kind: "close" });
    expect(unsplit.tabs).toHaveLength(2);
    expect(unsplit.tabs[1].split).toBeNull();
    const closed = apply(unsplit, { kind: "close" });
    expect(closed.tabs).toHaveLength(1);
    expect(closed.active).toBe(0);
  });

  it("never closes the last tab, so the demo cannot be emptied", () => {
    const opened = apply(INITIAL, { kind: "open", title: "example.com" });
    expect(apply(opened, { kind: "close" })).toEqual(INITIAL);
  });
});
