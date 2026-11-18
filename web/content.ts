export const LANGS = ["en", "es"] as const;
export type Lang = (typeof LANGS)[number];

export const SITE_URL = "https://nada.vicent.io";
export const DOWNLOAD: string | null = "https://github.com/vigosan/nada/releases/latest/download/Nada.zip";
export const CONTACT = "hello@vicent.io";
export const REPO = "https://github.com/vigosan/nada";
export const UPDATED = "2026-11-18";
export const CONFIG_SAMPLE = `# ~/.config/nada/config
theme = light:TokyoNight Day,dark:TokyoNight
font-family = MonoLisa
unfocused-split-opacity = 0.7
keybind = ctrl+h=focus_left
keybind = ctrl+shift+v=split_right
keybind = cmd+w=unbind`;

const en = {
  lang: "en" as Lang,
  other: "es" as Lang,
  switchLabel: "Español",
  theme: { system: "Theme: system", light: "Theme: light", dark: "Theme: dark" },
  routes: { home: "/", privacy: "/privacy", support: "/support" },
  meta: {
    title: "Nada: a browser with nothing on it",
    description:
      "A keyboard-driven browser for Mac that shows the page and nothing else: no address bar, no buttons, no ads. Tabs, split panes and a command palette on ⌘K.",
  },
  demo: {
    hint: "Press [⌘K] or click the window to try it",
    placeholder: "URL, search, tab or command…",
    blank: "New tab",
    newTab: "New tab",
    close: "Close pane or tab",
    splitRight: "Split right",
    splitDown: "Split down",
    open: "Open",
    search: "Search",
  },
  home: {
    tagline: "A browser with nothing on it",
    intro:
      "Nada is a Mac browser that shows the page and nothing else. No address bar, no buttons, no ads. Everything happens from the keyboard, starting with [⌘K].",
    download: "Download for Mac",
    soon: "Download coming soon",
    requirements: "macOS 14 or later",
    sections: [
      {
        title: "One box for everything",
        text: "Press [⌘K] and type an address, a search, the name of an open tab or a command. That box is the whole interface. Searches go to DuckDuckGo, Google or Brave Search, whichever you pick in the settings.",
      },
      {
        title: "It remembers where you go",
        text: "As you type, the palette suggests the pages you visit most, with a site's home page first. [⌘B] saves the page in a category of bookmarks and [⌥⌘B] browses them. When you open Nada again, your tabs are where you left them.",
      },
      {
        title: "Split it like your terminal",
        text: "[⌘D] splits the tab to the right and [⇧⌘D] splits it down. Move between panes with [⌥⌘] and the arrow keys, resize them with [⌃⌘] and the arrows, and zoom one with [⇧⌘↩]. The panes without focus dim, so you always know where you are typing.",
      },
      {
        title: "Leave the mouse alone",
        text: "Press [f] and every link and button gets a label: type it to press it. [j] and [k] scroll, [d] and [u] move half a page, and [gg] and [G] jump to the top and the bottom, like in Vim.",
      },
      {
        title: "Ads never load",
        text: "Nada blocks ads and trackers before they download, with the EasyList and EasyPrivacy filter lists compiled by Brave's open-source engine. Turn it off from the settings when a site needs it.",
      },
      {
        title: "Your terminal's colours",
        text: "Nada has a light and a dark theme and follows the system. It also reads Ghostty theme files, so any theme you use in your terminal works here by its name.",
      },
      {
        title: "Developer tools included",
        text: "[⌥⌘I] opens the Web Inspector: elements, console, network and sources.",
      },
      {
        title: "A native Mac app",
        text: "Written in Swift on WebKit, the engine behind Safari. No Electron, and no browser inside a browser.",
      },
    ],
    shortcutsTitle: "Every shortcut",
    shortcuts: [
      {
        title: "Page",
        items: [
          { keys: ["⌘K"], text: "Open the palette" },
          { keys: ["⌘L"], text: "Edit the current address" },
          { keys: ["⌘R"], text: "Reload" },
          { keys: ["⌘←", "⌘→"], text: "Back and forward" },
          { keys: ["⌘F"], text: "Find in the page" },
          { keys: ["⌘G", "⇧⌘G"], text: "Next and previous match" },
          { keys: ["⌘B"], text: "Bookmark the page in a category" },
          { keys: ["⌥⌘B"], text: "Browse your bookmarks" },
          { keys: ["⌘+", "⌘-", "⌘0"], text: "Zoom in, zoom out, actual size" },
        ],
      },
      {
        title: "Tabs",
        items: [
          { keys: ["⌘T"], text: "New tab" },
          { keys: ["⌘W"], text: "Close the pane, or the tab when it is the last one" },
          { keys: ["⌘1 – ⌘9"], text: "Go to a tab by its number" },
          { keys: ["⌃⇥", "⌃⇧⇥", "⇧⌘]", "⇧⌘["], text: "Next and previous tab" },
          { keys: ["⇧⌘T"], text: "Reopen what you just closed" },
        ],
      },
      {
        title: "Panes",
        items: [
          { keys: ["⌘D"], text: "Split right" },
          { keys: ["⇧⌘D"], text: "Split down" },
          { keys: ["⌥⌘←", "⌥⌘→", "⌥⌘↑", "⌥⌘↓"], text: "Move to the pane on that side" },
          { keys: ["⌘[", "⌘]"], text: "Previous and next pane" },
          { keys: ["⌃⌘←", "⌃⌘→", "⌃⌘↑", "⌃⌘↓"], text: "Move the divider" },
          { keys: ["⌃⌘="], text: "Make the panes equal" },
          { keys: ["⇧⌘↩"], text: "Zoom the pane, or restore it" },
        ],
      },
      {
        title: "Without the mouse",
        items: [
          { keys: ["f"], text: "Label every link and button, then type a label to press it" },
          { keys: ["F"], text: "The same, opening the link in a new tab" },
          { keys: ["j", "k"], text: "Scroll down and up" },
          { keys: ["h", "l"], text: "Scroll left and right" },
          { keys: ["d", "u"], text: "Half a page down and up" },
          { keys: ["gg", "G"], text: "Top and bottom of the page" },
        ],
      },
      {
        title: "Window",
        items: [
          { keys: ["⌘↩"], text: "Full screen" },
          { keys: ["⌥⌘I"], text: "Developer tools" },
          { keys: ["⌘,"], text: "Settings" },
          { keys: ["⇧⌘,"], text: "Reload the configuration" },
        ],
      },
    ],
    configTitle: "One text file, like Ghostty",
    configText: "The theme, the font, the panes and every shortcut live in a plain text file with Ghostty's syntax. Save it and press [⇧⌘,] to apply it without restarting.",
    closingTitle: "Nothing to learn but [⌘K]",
  },
  privacy: {
    title: "Privacy policy",
    updated: `Last updated ${UPDATED}`,
    sections: [
      {
        heading: "The app",
        body: [
          "Nada does not collect, store or share any personal data. It has no accounts, analytics or telemetry.",
          "Like any browser, Nada connects to the sites you open and to the search engine you choose in the settings. Those sites receive what any browser sends them, such as your IP address.",
          "Your history, bookmarks, cookies and site data stay on your Mac, in the app's own storage. Nada never sends them anywhere.",
          "The ad and tracker filters are lists stored on your Mac. Nada does not report what it blocks or which pages you visit.",
          "To keep itself up to date, Nada checks nada.vicent.io/appcast.xml for a new version from time to time and, when there is one, downloads it from GitHub. Those requests carry the version of Nada you have and, like any request, your IP address, and nothing about what you browse. You can also check by hand from the Nada menu.",
        ],
      },
      {
        heading: "This website",
        body: [
          "This website is hosted on Vercel, which processes technical request data, such as your IP address, to deliver the pages.",
          "It uses no cookies and no analytics. It remembers whether you chose the light or dark page in your browser's local storage, which never leaves your device.",
          `For any question about privacy, write to ${CONTACT}.`,
        ],
      },
    ],
  },
  support: {
    title: "Support",
    email: "Email support",
    body: [
      `For help, bug reports or ideas, write to ${CONTACT}. Please include your macOS version and, if a page misbehaves, its address.`,
      "Every keyboard shortcut is listed on the home page and can be changed in ~/.config/nada/config, along with the theme and the font.",
    ],
  },
  footer: { privacy: "Privacy", support: "Support", github: "GitHub", by: "Made by" },
};

export type Content = typeof en;

const es: Content = {
  lang: "es",
  other: "en",
  switchLabel: "English",
  theme: { system: "Tema: sistema", light: "Tema: claro", dark: "Tema: oscuro" },
  routes: { home: "/es", privacy: "/es/privacidad", support: "/es/soporte" },
  meta: {
    title: "Nada: un navegador sin nada",
    description:
      "Un navegador para Mac manejado con el teclado que enseña la página y nada más: sin barra de direcciones, sin botones, sin anuncios. Pestañas, paneles y una paleta de órdenes en ⌘K.",
  },
  demo: {
    hint: "Pulsa [⌘K] o haz clic en la ventana para probarlo",
    placeholder: "URL, búsqueda, pestaña u orden…",
    blank: "Pestaña nueva",
    newTab: "Pestaña nueva",
    close: "Cerrar panel o pestaña",
    splitRight: "Dividir a la derecha",
    splitDown: "Dividir abajo",
    open: "Abrir",
    search: "Buscar",
  },
  home: {
    tagline: "Un navegador sin nada",
    intro:
      "Nada es un navegador para Mac que enseña la página y nada más. Sin barra de direcciones, sin botones, sin anuncios. Todo se hace con el teclado, empezando por [⌘K].",
    download: "Descargar para Mac",
    soon: "Descarga disponible pronto",
    requirements: "macOS 14 o posterior",
    sections: [
      {
        title: "Una caja para todo",
        text: "Pulsa [⌘K] y escribe una dirección, una búsqueda, el nombre de una pestaña abierta o una orden. Esa caja es toda la interfaz. Las búsquedas van a DuckDuckGo, Google o Brave Search, el que elijas en los ajustes.",
      },
      {
        title: "Recuerda por dónde vas",
        text: "Mientras escribes, la paleta sugiere las páginas que más visitas, con la portada de cada web primero. [⌘B] guarda la página en una categoría de marcadores y [⌥⌘B] los recorre. Al abrir Nada de nuevo, tus pestañas están donde las dejaste.",
      },
      {
        title: "Divídelo como tu terminal",
        text: "[⌘D] divide la pestaña a la derecha y [⇧⌘D] la divide hacia abajo. Muévete entre paneles con [⌥⌘] y las flechas, cambia su tamaño con [⌃⌘] y las flechas, y amplía uno con [⇧⌘↩]. Los paneles sin foco se oscurecen, para que siempre sepas dónde escribes.",
      },
      {
        title: "Deja el ratón quieto",
        text: "Pulsa [f] y cada enlace y botón recibe una etiqueta: escríbela para pulsarlo. [j] y [k] desplazan la página, [d] y [u] mueven media página, y [gg] y [G] saltan al principio y al final, como en Vim.",
      },
      {
        title: "Los anuncios no llegan a cargar",
        text: "Nada bloquea anuncios y rastreadores antes de que se descarguen, con las listas EasyList y EasyPrivacy compiladas por el motor de código abierto de Brave. Desactívalo desde los ajustes cuando una web lo necesite.",
      },
      {
        title: "Los colores de tu terminal",
        text: "Nada tiene un tema claro y uno oscuro y sigue al sistema. También lee los archivos de tema de Ghostty, así que cualquier tema que uses en tu terminal funciona aquí por su nombre.",
      },
      {
        title: "Con herramientas de desarrollador",
        text: "[⌥⌘I] abre el inspector web: elementos, consola, red y fuentes.",
      },
      {
        title: "Una app nativa de Mac",
        text: "Escrita en Swift sobre WebKit, el motor de Safari. Sin Electron y sin un navegador dentro de otro.",
      },
    ],
    shortcutsTitle: "Todos los atajos",
    shortcuts: [
      {
        title: "Página",
        items: [
          { keys: ["⌘K"], text: "Abrir la paleta" },
          { keys: ["⌘L"], text: "Editar la dirección actual" },
          { keys: ["⌘R"], text: "Recargar" },
          { keys: ["⌘←", "⌘→"], text: "Atrás y adelante" },
          { keys: ["⌘F"], text: "Buscar en la página" },
          { keys: ["⌘G", "⇧⌘G"], text: "Coincidencia siguiente y anterior" },
          { keys: ["⌘B"], text: "Guardar la página en una categoría de marcadores" },
          { keys: ["⌥⌘B"], text: "Explorar tus marcadores" },
          { keys: ["⌘+", "⌘-", "⌘0"], text: "Acercar, alejar y tamaño real" },
        ],
      },
      {
        title: "Pestañas",
        items: [
          { keys: ["⌘T"], text: "Pestaña nueva" },
          { keys: ["⌘W"], text: "Cerrar el panel, o la pestaña si es el último" },
          { keys: ["⌘1 – ⌘9"], text: "Ir a una pestaña por su número" },
          { keys: ["⌃⇥", "⌃⇧⇥", "⇧⌘]", "⇧⌘["], text: "Pestaña siguiente y anterior" },
          { keys: ["⇧⌘T"], text: "Reabrir lo que acabas de cerrar" },
        ],
      },
      {
        title: "Paneles",
        items: [
          { keys: ["⌘D"], text: "Dividir a la derecha" },
          { keys: ["⇧⌘D"], text: "Dividir abajo" },
          { keys: ["⌥⌘←", "⌥⌘→", "⌥⌘↑", "⌥⌘↓"], text: "Ir al panel de ese lado" },
          { keys: ["⌘[", "⌘]"], text: "Panel anterior y siguiente" },
          { keys: ["⌃⌘←", "⌃⌘→", "⌃⌘↑", "⌃⌘↓"], text: "Mover el divisor" },
          { keys: ["⌃⌘="], text: "Igualar los paneles" },
          { keys: ["⇧⌘↩"], text: "Ampliar el panel o restaurarlo" },
        ],
      },
      {
        title: "Sin ratón",
        items: [
          { keys: ["f"], text: "Etiquetar cada enlace y botón, y escribir una etiqueta para pulsarlo" },
          { keys: ["F"], text: "Lo mismo, abriendo el enlace en una pestaña nueva" },
          { keys: ["j", "k"], text: "Bajar y subir" },
          { keys: ["h", "l"], text: "Mover a izquierda y derecha" },
          { keys: ["d", "u"], text: "Media página abajo y arriba" },
          { keys: ["gg", "G"], text: "Principio y final de la página" },
        ],
      },
      {
        title: "Ventana",
        items: [
          { keys: ["⌘↩"], text: "Pantalla completa" },
          { keys: ["⌥⌘I"], text: "Herramientas de desarrollador" },
          { keys: ["⌘,"], text: "Ajustes" },
          { keys: ["⇧⌘,"], text: "Recargar la configuración" },
        ],
      },
    ],
    configTitle: "Un archivo de texto, como Ghostty",
    configText: "El tema, la fuente, los paneles y cada atajo viven en un archivo de texto con la sintaxis de Ghostty. Guárdalo y pulsa [⇧⌘,] para aplicarlo sin reiniciar.",
    closingTitle: "Nada que aprender salvo [⌘K]",
  },
  privacy: {
    title: "Política de privacidad",
    updated: `Última actualización: ${UPDATED}`,
    sections: [
      {
        heading: "La app",
        body: [
          "Nada no recoge, guarda ni comparte ningún dato personal. No tiene cuentas, analítica ni telemetría.",
          "Como cualquier navegador, Nada se conecta a las webs que abres y al buscador que eliges en los ajustes. Esas webs reciben lo que les envía cualquier navegador, como tu dirección IP.",
          "Tu historial, tus marcadores, tus cookies y los datos de las webs se quedan en tu Mac, en el almacenamiento propio de la app. Nada nunca los envía a ningún sitio.",
          "Los filtros de anuncios y rastreadores son listas guardadas en tu Mac. Nada no informa de lo que bloquea ni de las páginas que visitas.",
          "Para mantenerse al día, Nada consulta de vez en cuando nada.vicent.io/appcast.xml por si hay una versión nueva y, cuando la hay, la descarga de GitHub. Esas peticiones llevan la versión de Nada que tienes y, como cualquier petición, tu dirección IP, y nada sobre lo que navegas. También puedes buscar actualizaciones a mano desde el menú Nada.",
        ],
      },
      {
        heading: "Esta web",
        body: [
          "Esta web está alojada en Vercel, que procesa datos técnicos de las peticiones, como tu dirección IP, para servir las páginas.",
          "No usa cookies ni analítica. Recuerda si elegiste la página clara u oscura en el almacenamiento local de tu navegador, que nunca sale de tu dispositivo.",
          `Para cualquier duda sobre privacidad, escribe a ${CONTACT}.`,
        ],
      },
    ],
  },
  support: {
    title: "Soporte",
    email: "Escribir a soporte",
    body: [
      `Para pedir ayuda, avisar de un fallo o proponer ideas, escribe a ${CONTACT}. Incluye tu versión de macOS y, si una página falla, su dirección.`,
      "Todos los atajos de teclado están en la página de inicio y se pueden cambiar en ~/.config/nada/config, igual que el tema y la fuente.",
    ],
  },
  footer: { privacy: "Privacidad", support: "Soporte", github: "GitHub", by: "Hecho por" },
};

export const content: Record<Lang, Content> = { en, es };
