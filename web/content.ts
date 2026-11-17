export const LANGS = ["en", "es"] as const;
export type Lang = (typeof LANGS)[number];

export const SITE_URL = "https://nada.vicent.io";
export const DOWNLOAD: string | null = null;
export const CONFIG_SAMPLE = `# ~/.config/nada/config
keybind = ctrl+h=focus_left
keybind = ctrl+shift+v=split_right
keybind = cmd+w=unbind`;

const en = {
  lang: "en" as Lang,
  other: "es" as Lang,
  switchLabel: "Español",
  routes: { home: "/" },
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
        text: "Press [⌘K] and type an address, a search, the name of an open tab or a command. That box is the whole interface.",
      },
      {
        title: "Split it like your terminal",
        text: "[⌘D] splits the tab to the right and [⇧⌘D] splits it down. Move between panes with [⌥⌘] and the arrow keys, resize them with [⌃⌘] and the arrows, and zoom one with [⇧⌘↩].",
      },
      {
        title: "Ads never load",
        text: "Nada blocks ads and trackers before they download, with the EasyList and EasyPrivacy filter lists compiled by Brave's open-source engine. Turn it off from the settings when a site needs it.",
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
          { keys: ["⌘[", "⌘]"], text: "Back and forward" },
          { keys: ["⌘F"], text: "Find in the page" },
          { keys: ["⌘+", "⌘-", "⌘0"], text: "Zoom in, zoom out, actual size" },
        ],
      },
      {
        title: "Tabs",
        items: [
          { keys: ["⌘T"], text: "New tab" },
          { keys: ["⌘W"], text: "Close the pane, or the tab when it is the last one" },
          { keys: ["⌘1 – ⌘9"], text: "Go to a tab by its number" },
          { keys: ["⌃⇥", "⌃⇧⇥"], text: "Next and previous tab" },
          { keys: ["⇧⌘T"], text: "Reopen what you just closed" },
        ],
      },
      {
        title: "Panes",
        items: [
          { keys: ["⌘D"], text: "Split right" },
          { keys: ["⇧⌘D"], text: "Split down" },
          { keys: ["⌥⌘←", "⌥⌘→", "⌥⌘↑", "⌥⌘↓"], text: "Move to the pane on that side" },
          { keys: ["⌃⌘←", "⌃⌘→", "⌃⌘↑", "⌃⌘↓"], text: "Move the divider" },
          { keys: ["⌃⌘="], text: "Make the panes equal" },
          { keys: ["⇧⌘↩"], text: "Zoom the pane, or restore it" },
        ],
      },
      {
        title: "Window",
        items: [
          { keys: ["⌘↩"], text: "Full screen" },
          { keys: ["⌥⌘I"], text: "Developer tools" },
          { keys: ["⌘,"], text: "Settings" },
        ],
      },
    ],
    configTitle: "Make the keys yours",
    configText: "Every shortcut can be changed, added or removed from a plain text file.",
    closingTitle: "Nothing to learn but [⌘K]",
  },
  footer: { by: "Made by" },
};

export type Content = typeof en;

const es: Content = {
  lang: "es",
  other: "en",
  switchLabel: "English",
  routes: { home: "/es" },
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
        text: "Pulsa [⌘K] y escribe una dirección, una búsqueda, el nombre de una pestaña abierta o una orden. Esa caja es toda la interfaz.",
      },
      {
        title: "Divídelo como tu terminal",
        text: "[⌘D] divide la pestaña a la derecha y [⇧⌘D] la divide hacia abajo. Muévete entre paneles con [⌥⌘] y las flechas, cambia su tamaño con [⌃⌘] y las flechas, y amplía uno con [⇧⌘↩].",
      },
      {
        title: "Los anuncios no llegan a cargar",
        text: "Nada bloquea anuncios y rastreadores antes de que se descarguen, con las listas EasyList y EasyPrivacy compiladas por el motor de código abierto de Brave. Desactívalo desde los ajustes cuando una web lo necesite.",
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
          { keys: ["⌘[", "⌘]"], text: "Atrás y adelante" },
          { keys: ["⌘F"], text: "Buscar en la página" },
          { keys: ["⌘+", "⌘-", "⌘0"], text: "Acercar, alejar y tamaño real" },
        ],
      },
      {
        title: "Pestañas",
        items: [
          { keys: ["⌘T"], text: "Pestaña nueva" },
          { keys: ["⌘W"], text: "Cerrar el panel, o la pestaña si es el último" },
          { keys: ["⌘1 – ⌘9"], text: "Ir a una pestaña por su número" },
          { keys: ["⌃⇥", "⌃⇧⇥"], text: "Pestaña siguiente y anterior" },
          { keys: ["⇧⌘T"], text: "Reabrir lo que acabas de cerrar" },
        ],
      },
      {
        title: "Paneles",
        items: [
          { keys: ["⌘D"], text: "Dividir a la derecha" },
          { keys: ["⇧⌘D"], text: "Dividir abajo" },
          { keys: ["⌥⌘←", "⌥⌘→", "⌥⌘↑", "⌥⌘↓"], text: "Ir al panel de ese lado" },
          { keys: ["⌃⌘←", "⌃⌘→", "⌃⌘↑", "⌃⌘↓"], text: "Mover el divisor" },
          { keys: ["⌃⌘="], text: "Igualar los paneles" },
          { keys: ["⇧⌘↩"], text: "Ampliar el panel o restaurarlo" },
        ],
      },
      {
        title: "Ventana",
        items: [
          { keys: ["⌘↩"], text: "Pantalla completa" },
          { keys: ["⌥⌘I"], text: "Herramientas de desarrollador" },
          { keys: ["⌘,"], text: "Ajustes" },
        ],
      },
    ],
    configTitle: "Haz tuyas las teclas",
    configText: "Cada atajo se puede cambiar, añadir o quitar desde un archivo de texto.",
    closingTitle: "Nada que aprender salvo [⌘K]",
  },
  footer: { by: "Hecho por" },
};

export const content: Record<Lang, Content> = { en, es };
