import type { Content } from "./content";

export type Action =
  | { kind: "newTab" }
  | { kind: "close" }
  | { kind: "splitRight" }
  | { kind: "splitDown" }
  | { kind: "open"; title: string };

export type Item = { title: string; keys: string; action: Action };
export type Tab = { title: string | null; split: "right" | "down" | null };
export type State = { tabs: Tab[]; active: number };

export const INITIAL: State = { tabs: [{ title: null, split: null }], active: 0 };

export function paletteItems(query: string, labels: Content["demo"]): Item[] {
  const commands: Item[] = [
    { title: labels.newTab, keys: "⌘T", action: { kind: "newTab" } },
    { title: labels.close, keys: "⌘W", action: { kind: "close" } },
    { title: labels.splitRight, keys: "⌘D", action: { kind: "splitRight" } },
    { title: labels.splitDown, keys: "⇧⌘D", action: { kind: "splitDown" } },
  ];
  const text = query.trim();
  if (text === "") return commands;
  const matches = commands.filter((command) => command.title.toLowerCase().includes(text.toLowerCase()));
  const action: Action = { kind: "open", title: text };
  if (!/\s/.test(text) && /^[^.]+\.[^.]/.test(text)) {
    return [{ title: `${labels.open} ${text}`, keys: "↵", action }, ...matches];
  }
  return [...matches, { title: `${labels.search} “${text}”`, keys: "↵", action }];
}

export function apply(state: State, action: Action): State {
  const current = state.tabs[state.active];
  const replace = (tab: Tab): State => ({ ...state, tabs: state.tabs.map((other, index) => (index === state.active ? tab : other)) });
  switch (action.kind) {
    case "open":
      return replace({ ...current, title: action.title });
    case "newTab":
      return { tabs: [...state.tabs, { title: null, split: null }], active: state.tabs.length };
    case "splitRight":
      return replace({ ...current, split: "right" });
    case "splitDown":
      return replace({ ...current, split: "down" });
    case "close": {
      if (current.split) return replace({ ...current, split: null });
      if (state.tabs.length === 1) return INITIAL;
      const tabs = state.tabs.filter((_, index) => index !== state.active);
      return { tabs, active: Math.min(state.active, tabs.length - 1) };
    }
  }
}
