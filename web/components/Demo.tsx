"use client";

import { useEffect, useRef, useState } from "react";
import type { Content } from "@/content";
import { apply, INITIAL, paletteItems, type Item } from "@/demo";
import { Keys } from "./Keys";

function Pane({ title }: { title: string | null }) {
  return (
    <div className="flex min-w-0 flex-1 flex-col gap-3 bg-ground p-5 text-left">
      {title && (
        <>
          <span className="truncate font-sans text-lg font-semibold text-ink">{title}</span>
          {[92, 97, 80, 60].map((width) => (
            <span key={width} className="h-2 rounded-full bg-raised" style={{ width: `${width}%` }} />
          ))}
        </>
      )}
    </div>
  );
}

export function Demo({ labels }: { labels: Content["demo"] }) {
  const [state, setState] = useState(INITIAL);
  const [open, setOpen] = useState(true);
  const [touched, setTouched] = useState(false);
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState(0);
  const input = useRef<HTMLInputElement>(null);
  const items = paletteItems(query, labels);
  const tab = state.tabs[state.active];

  const show = (visible: boolean) => {
    setTouched(true);
    setOpen(visible);
    setQuery("");
    setSelected(0);
  };

  const run = (item: Item) => {
    setState(apply(state, item.action));
    show(false);
  };

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        setTouched(true);
        if (input.current && document.activeElement !== input.current) return input.current.focus();
        setOpen((visible) => !visible);
        setQuery("");
        setSelected(0);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  useEffect(() => {
    if (open && touched) input.current?.focus();
  }, [open, touched]);

  const onInputKey = (event: React.KeyboardEvent) => {
    if (event.key === "Escape") show(false);
    if (event.key === "ArrowDown") setSelected((selected + 1) % items.length);
    if (event.key === "ArrowUp") setSelected((selected - 1 + items.length) % items.length);
    if (event.key === "Enter" && items[selected]) run(items[selected]);
    if (["ArrowDown", "ArrowUp"].includes(event.key)) event.preventDefault();
  };

  return (
    <div data-testid="demo" className="flex flex-col gap-4">
      <div
        data-testid="demo-window"
        className="relative overflow-hidden rounded-xl border border-line bg-ground font-mono text-sm shadow-2xl shadow-black/30"
      >
        <div className="flex items-center gap-3 px-3 py-2">
          <div aria-hidden className="flex gap-2">
            <span className="size-3 rounded-full bg-[#ff5f57]" />
            <span className="size-3 rounded-full bg-[#febc2e]" />
            <span className="size-3 rounded-full bg-[#28c840]" />
          </div>
          <div className="flex min-w-0 flex-1 gap-0.5 rounded-lg bg-bar p-0.5 font-sans text-xs">
            {state.tabs.map((item, index) => (
              <div
                key={index}
                className={`flex min-w-0 flex-1 items-center justify-between gap-2 rounded-md px-2.5 py-1 ${index === state.active ? "bg-raised text-ink" : "text-dim"}`}
              >
                <span className="truncate">{item.title ?? labels.blank}</span>
                <span className="hidden sm:inline">⌘{index + 1}</span>
              </div>
            ))}
          </div>
        </div>
        <button
          type="button"
          onClick={() => show(true)}
          className={`flex h-72 w-full gap-px bg-raised sm:h-96 ${tab.split === "down" ? "flex-col" : ""} focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-accent`}
        >
          <Pane title={tab.title} />
          {tab.split && <Pane title={null} />}
        </button>
        {open && (
          <div className="absolute inset-x-0 top-16 mx-auto w-[min(28rem,calc(100%-2rem))] overflow-hidden rounded-xl border border-line bg-bar shadow-2xl shadow-black/60">
            <input
              ref={input}
              value={query}
              onChange={(event) => {
                setQuery(event.target.value);
                setSelected(0);
              }}
              onKeyDown={onInputKey}
              onBlur={() => show(false)}
              placeholder={labels.placeholder}
              aria-label={labels.placeholder}
              autoComplete="off"
              spellCheck={false}
              className="w-full border-b border-line bg-transparent px-4 py-3 text-ink caret-accent outline-none placeholder:text-dim"
            />
            <ul className="p-1.5 text-left" onMouseDown={(event) => event.preventDefault()}>
              {items.map((item, index) => (
                <li key={item.title}>
                  <button
                    type="button"
                    data-testid="demo-item"
                    tabIndex={-1}
                    onClick={() => run(item)}
                    className={`flex w-full cursor-pointer justify-between gap-3 rounded-md px-2.5 py-1.5 ${index === selected ? "bg-raised text-ink" : "text-dim"}`}
                  >
                    <span className="truncate">{item.title}</span>
                    <span>{item.keys}</span>
                  </button>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
      <p className="text-center text-sm text-dim">
        <Keys text={labels.hint} />
      </p>
    </div>
  );
}
