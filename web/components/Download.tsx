import type { Content } from "@/content";
import { button } from "./Page";

const pill = "inline-flex items-center rounded-lg px-5 py-2.5 font-medium";

export function Download({ home, url }: { home: Content["home"]; url: string | null }) {
  return (
    <div className="flex flex-col items-center gap-3">
      {url ? (
        <a href={url} className={button}>
          {home.download}
        </a>
      ) : (
        <p data-testid="download-soon" className={`${pill} border border-line text-ink`}>
          {home.soon}
        </p>
      )}
      <p className="text-sm text-dim">{home.requirements}</p>
    </div>
  );
}
