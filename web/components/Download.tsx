import type { Content } from "@/content";
import { link } from "./Page";

export function Download({ home, url }: { home: Content["home"]; url: string | null }) {
  return (
    <div className="flex flex-col gap-1 border-l-2 border-accent pl-4 sm:pl-6">
      {url ? (
        <p>
          <span aria-hidden className="mr-3 text-accent">
            →
          </span>
          <a href={url} className={link}>
            {home.download}
          </a>
        </p>
      ) : (
        <p data-testid="download-soon" className="font-medium text-ink">
          {home.soon}
        </p>
      )}
      <p className="text-sm text-faint">{home.requirements}</p>
    </div>
  );
}
