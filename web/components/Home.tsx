import { CONFIG_SAMPLE, DOWNLOAD, type Content } from "@/content";
import { Demo } from "./Demo";
import { Download } from "./Download";
import { key, Keys } from "./Keys";
import { Page } from "./Page";

const wide = "lg:-mx-24 xl:-mx-40";

const rise =
  "transition-[opacity,translate] duration-300 ease-out starting:translate-y-2 starting:opacity-0 motion-reduce:starting:translate-y-0";

const heading = "text-2xl font-semibold tracking-tight text-balance text-ink";

export function Home({ c }: { c: Content }) {
  return (
    <Page c={c} current="home">
      <div aria-hidden className="scroll-playhead">
        <div className="scroll-playhead-head" />
      </div>
      <section className="flex flex-col items-center gap-6 text-center lg:pt-4">
        <h1 className={`${rise} max-w-2xl text-4xl font-semibold tracking-tight text-balance text-ink sm:text-5xl`}>{c.home.tagline}</h1>
        <p className={`${rise} max-w-xl text-lg text-pretty delay-50`}>
          <Keys text={c.home.intro} />
        </p>
        <div className={`${rise} delay-90`}>
          <Download home={c.home} url={DOWNLOAD} />
        </div>
        <div className={`${rise} mt-6 self-stretch delay-120 ${wide}`}>
          <Demo labels={c.demo} />
        </div>
      </section>
      {c.home.sections.map((section) => (
        <article key={section.title} className="flex flex-col gap-6">
          <h2 className={heading}>{section.title}</h2>
          <p className="max-w-2xl text-pretty leading-relaxed">
            <Keys text={section.text} />
          </p>
          {"shot" in section && (
            <div className={wide}>
              <img
                data-testid="panes-shot"
                src="/panes.webp"
                alt={section.shot}
                width={2400}
                height={1500}
                loading="lazy"
                className="h-auto w-full rounded-xl border border-line shadow-2xl shadow-black/30"
              />
            </div>
          )}
        </article>
      ))}
      <article className="flex flex-col gap-6">
        <h2 className={heading}>{c.home.shortcutsTitle}</h2>
        <div className="border-b border-line">
          {c.home.shortcuts.map((group) => (
            <section key={group.title} className="grid gap-4 border-t border-line py-6 sm:grid-cols-[9rem_1fr] sm:gap-8">
              <h3 className="font-medium text-ink">{group.title}</h3>
              <ul className="flex flex-col gap-3">
                {group.items.map((item) => (
                  <li key={item.text} className="flex flex-wrap items-baseline justify-between gap-x-6 gap-y-1">
                    <span>{item.text}</span>
                    <span className="flex flex-wrap gap-1.5">
                      {item.keys.map((keys) => (
                        <kbd key={keys} className={key}>
                          {keys}
                        </kbd>
                      ))}
                    </span>
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      </article>
      <article className="flex flex-col gap-6">
        <h2 className={heading}>{c.home.configTitle}</h2>
        <p className="max-w-2xl text-pretty">
          <Keys text={c.home.configText} />
        </p>
        <pre className="overflow-x-auto rounded-xl border border-line bg-ground p-5 font-mono text-sm leading-relaxed text-ink">{CONFIG_SAMPLE}</pre>
      </article>
      <section data-testid="closing" className="flex flex-col items-center gap-6 border-t border-line pt-16 text-center">
        <h2 className={heading}>
          <Keys text={c.home.closingTitle} />
        </h2>
        <Download home={c.home} url={DOWNLOAD} />
      </section>
    </Page>
  );
}
