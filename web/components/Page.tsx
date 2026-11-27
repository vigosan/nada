import Link from "next/link";
import { CONTACT, content, REPO, type Content } from "@/content";
import { ThemeToggle } from "./ThemeToggle";

const focus = "rounded focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-accent";

export const link = `${focus} font-medium text-ink underline-offset-4 hover:underline`;

const quiet = `${focus} transition-colors duration-150 hover:text-ink`;

export const button =
  "inline-flex items-center rounded-lg bg-ink px-5 py-2.5 font-medium text-desk transition-[opacity,transform] duration-150 ease-out hover:opacity-85 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-desk";

type Route = keyof Content["routes"];

export function Page({ c, current, children }: { c: Content; current: Route; children: React.ReactNode }) {
  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-3xl flex-col gap-10 px-6 py-12 font-sans text-body antialiased lg:gap-16 lg:py-16">
      <header className="flex items-center justify-between">
        <Link href={c.routes.home} className={`flex items-center gap-3 ${focus}`}>
          <img src="/icon.svg" alt="" width={36} height={36} />
          <span className="font-semibold text-ink">Nada</span>
        </Link>
        <div className="flex items-center gap-3">
          <ThemeToggle labels={c.theme} />
          <a href={content[c.other].routes[current]} hrefLang={c.other} className={quiet}>
            {c.switchLabel}
          </a>
        </div>
      </header>
      <main className="flex flex-1 flex-col gap-20 lg:gap-28">{children}</main>
      <footer className="flex flex-wrap gap-x-4 gap-y-2 text-sm">
        <Link href={c.routes.privacy} className={quiet}>
          {c.footer.privacy}
        </Link>
        <Link href={c.routes.support} className={quiet}>
          {c.footer.support}
        </Link>
        <a href={REPO} className={quiet}>
          {c.footer.github}
        </a>
        <span className="sm:ml-auto">
          {c.footer.by}{" "}
          <a href="https://vicent.io" className={quiet}>
            Vicent Gozalbes
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
