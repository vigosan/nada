import { describe, expect, it } from "vitest";
import { splitKeys } from "./keys";

describe("keys in copy", () => {
  it("separates the shortcuts from the sentence, so each key is drawn as a key and read as one", () => {
    expect(splitKeys("Press [⌘K] and type")).toEqual([{ text: "Press " }, { key: "⌘K" }, { text: " and type" }]);
  });

  it("leaves a sentence without shortcuts untouched", () => {
    expect(splitKeys("Nothing else")).toEqual([{ text: "Nothing else" }]);
  });
});
