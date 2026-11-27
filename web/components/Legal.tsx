import { CONTACT, type Content } from "@/content";
import { button, Page, Paragraph } from "./Page";

export function Privacy({ c }: { c: Content }) {
  return (
    <Page c={c} current="privacy">
      <article className="flex flex-col gap-6">
        <h1 className="text-2xl font-medium text-ink">{c.privacy.title}</h1>
        <p className="text-sm text-dim">{c.privacy.updated}</p>
        {c.privacy.sections.map((section) => (
          <section key={section.heading} className="flex flex-col gap-4">
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
        <h1 className="text-2xl font-medium text-ink">{c.support.title}</h1>
        {c.support.body.map((text) => (
          <Paragraph key={text} text={text} />
        ))}
        <a data-testid="support-email" href={`mailto:${CONTACT}`} className={`${button} self-start`}>
          {c.support.email}
        </a>
      </article>
    </Page>
  );
}
