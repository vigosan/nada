import { CONTACT, type Content } from "@/content";
import { link, Page, Paragraph } from "./Page";

export function Privacy({ c }: { c: Content }) {
  return (
    <Page c={c} current="privacy">
      <article className="flex flex-col gap-8 lg:gap-12">
        <div>
          <h1 className="text-lg font-medium text-ink">{c.privacy.title}</h1>
          <p className="text-sm text-faint">{c.privacy.updated}</p>
        </div>
        {c.privacy.sections.map((section) => (
          <section key={section.heading} className="flex flex-col gap-6">
            <h2 className="text-lg font-medium text-ink">{section.heading}</h2>
            {section.body.map((text) => (
              <Paragraph key={text} text={text} />
            ))}
          </section>
        ))}
      </article>
    </Page>
  );
}

export function Support({ c }: { c: Content }) {
  return (
    <Page c={c} current="support">
      <article className="flex flex-col gap-6">
        <h1 className="text-lg font-medium text-ink">{c.support.title}</h1>
        {c.support.body.map((text) => (
          <Paragraph key={text} text={text} />
        ))}
        <p>
          <span aria-hidden className="mr-3 text-accent">
            →
          </span>
          <a data-testid="support-email" href={`mailto:${CONTACT}`} className={link}>
            {c.support.email}
          </a>
        </p>
      </article>
    </Page>
  );
}
