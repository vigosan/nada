import Link from "next/link";
import { content, type Content } from "@/content";

const quiet =
  "rounded transition-colors duration-150 hover:text-ink focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-accent";

export function Page({ c, children }: { c: Content; children: React.ReactNode }) {
  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-3xl flex-col gap-10 px-6 py-12 font-sans text-body antialiased lg:gap-16 lg:py-16">
      <header className="flex items-center justify-between">
        <Link href={c.routes.home} className={`flex items-center gap-3 ${quiet}`}>
          <img src="/icon.svg" alt="" width={32} height={32} />
          <span className="font-semibold text-ink">Nada</span>
        </Link>
        <a href={content[c.other].routes.home} hrefLang={c.other} className={quiet}>
          {c.switchLabel}
        </a>
      </header>
      <main className="flex flex-1 flex-col gap-20 lg:gap-28">{children}</main>
      <footer className="text-sm text-dim">
        {c.footer.by}{" "}
        <a href="https://vicent.io" className={quiet}>
          Vicent Gozalbes
        </a>
      </footer>
    </div>
  );
}
