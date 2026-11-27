import { splitKeys } from "@/keys";

export const key =
  "rounded-md border border-line bg-wash px-1.5 py-0.5 text-xs font-medium text-ink shadow-[inset_0_-1px_0_rgba(0,0,0,0.35)]";

export function Keys({ text }: { text: string }) {
  return splitKeys(text).map((part, index) =>
    "key" in part ? (
      <kbd key={index} className={`mx-0.5 ${key}`}>
        {part.key}
      </kbd>
    ) : (
      part.text
    ),
  );
}
