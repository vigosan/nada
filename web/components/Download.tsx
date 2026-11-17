import type { Content } from "@/content";

const pill = "inline-flex items-center rounded-lg px-5 py-2.5 font-medium";

export function Download({ home, url }: { home: Content["home"]; url: string | null }) {
  return (
    <div className="flex flex-col items-center gap-3">
      {url ? (
        <a
          href={url}
          className={`${pill} bg-ink text-ground transition-[background-color,transform] duration-150 ease-out hover:bg-white active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-desk`}
        >
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
