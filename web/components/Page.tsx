import Link from "next/link";
import { CONTACT, content, REPO, type Content } from "@/content";
import { ThemeToggle } from "./ThemeToggle";

export const link = "link px-1 font-medium text-ink underline";

const quiet = "link px-1 underline";

type Route = keyof Content["routes"];

export function Page({ c, current, children }: { c: Content; current: Route; children: React.ReactNode }) {
  const Name = current === "home" ? "h1" : "span";
  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-5xl flex-col gap-6 px-6 py-12 text-body antialiased lg:gap-24 lg:px-24 lg:py-16">
      <header className="flex items-start justify-between gap-6">
        <div className="flex flex-col">
          <Link href={c.routes.home} className="link self-start">
            <Name className="font-medium text-ink">Nada</Name>
          </Link>
          <span className="text-muted">{c.home.tagline}</span>
        </div>
        <div className="flex items-center gap-3">
          <ThemeToggle labels={c.theme} />
          <a href={content[c.other].routes[current]} hrefLang={c.other} className={quiet}>
            {c.switchLabel}
          </a>
        </div>
      </header>
      <main className="flex flex-1 flex-col gap-8 lg:gap-12">{children}</main>
      <footer className="flex flex-wrap gap-x-4 gap-y-2 text-sm text-muted">
        <Link href={c.routes.privacy} className={quiet}>
          {c.footer.privacy}
        </Link>
        <Link href={c.routes.support} className={quiet}>
          {c.footer.support}
        </Link>
        <a href={REPO} className={quiet}>
          {c.footer.github} <span aria-hidden>↗</span>
        </a>
        <span className="sm:ml-auto">
          {c.footer.by}{" "}
          <a href="https://vicent.io" className={quiet}>
            Vicent Gozalbes <span aria-hidden>↗</span>
          </a>
        </span>
      </footer>
    </div>
  );
}

export function Paragraph({ text }: { text: string }) {
  const [before, after] = text.split(CONTACT);
  if (after === undefined) return <p>{text}</p>;
  return (
    <p>
      {before}
      <a href={`mailto:${CONTACT}`} className={link}>
        {CONTACT}
      </a>
      {after}
    </p>
  );
}
