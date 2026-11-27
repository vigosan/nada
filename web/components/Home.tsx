import { CONFIG_SAMPLE, DOWNLOAD, type Content } from "@/content";
import { Demo } from "./Demo";
import { Download } from "./Download";
import { key, Keys } from "./Keys";
import { Page } from "./Page";

const heading = "text-lg font-medium text-ink";

export function Home({ c }: { c: Content }) {
  return (
    <Page c={c} current="home">
      <section className="flex flex-col gap-6">
        <p className="max-w-2xl text-pretty">
          <Keys text={c.home.intro} />
        </p>
        <Download home={c.home} url={DOWNLOAD} />
        <Demo labels={c.demo} />
      </section>
      {c.home.sections.map((section) => (
        <article key={section.title} className="flex flex-col gap-6">
          <h2 className={heading}>{section.title}</h2>
          <p className="max-w-2xl text-pretty">
            <Keys text={section.text} />
          </p>
          {"shot" in section && (
            <img
              data-testid="panes-shot"
              src="/panes.webp"
              alt={section.shot}
              width={2400}
              height={1500}
              loading="lazy"
              className="h-auto w-full border border-line"
            />
          )}
        </article>
      ))}
      <article className="flex flex-col gap-6">
        <h2 className={heading}>{c.home.shortcutsTitle}</h2>
        <ul className="flex flex-col gap-8">
          {c.home.shortcuts.map((group) => (
            <li
              key={group.title}
              data-testid="shortcut-group"
              className="flex flex-col gap-4 border-l-2 border-line pl-4 hover:border-line-strong sm:pl-6"
            >
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
            </li>
          ))}
        </ul>
      </article>
      <article className="flex flex-col gap-6">
        <h2 className={heading}>{c.home.configTitle}</h2>
        <p className="max-w-2xl text-pretty">
          <Keys text={c.home.configText} />
        </p>
        <pre className="overflow-x-auto border border-line p-4 text-sm leading-relaxed text-ink">{CONFIG_SAMPLE}</pre>
      </article>
      <section data-testid="closing" className="flex flex-col gap-6">
        <h2 className={heading}>
          <Keys text={c.home.closingTitle} />
        </h2>
        <Download home={c.home} url={DOWNLOAD} />
      </section>
    </Page>
  );
}
