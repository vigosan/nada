import { GeistMono } from "geist/font/mono";
import { GeistSans } from "geist/font/sans";
import type { Lang } from "@/content";

import "@/app/globals.css";

export function Root({ lang, children }: { lang: Lang; children: React.ReactNode }) {
  return (
    <html lang={lang}>
      <body className={`${GeistSans.variable} ${GeistMono.variable} bg-desk`}>{children}</body>
    </html>
  );
}
