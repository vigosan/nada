import type { Metadata } from "next";
import { content, SITE_URL, type Content } from "@/content";

export function metadataFor(c: Content): Metadata {
  return {
    metadataBase: new URL(SITE_URL),
    title: c.meta.title,
    description: c.meta.description,
    icons: { icon: "/icon.svg" },
    alternates: {
      canonical: c.routes.home,
      languages: { en: content.en.routes.home, es: content.es.routes.home },
    },
    openGraph: {
      title: c.meta.title,
      description: c.meta.description,
      url: c.routes.home,
      siteName: "Nada",
      type: "website",
      locale: c.lang === "en" ? "en_US" : "es_ES",
    },
  };
}
