public indirect enum MenuEntry: Sendable {
    case command(String, symbol: String)
    case system(String)
    case submenu(String, symbol: String, [MenuEntry])
    case separator
}

public struct MenuSection: Sendable {
    public let title: String
    public let entries: [MenuEntry]
}

public enum MenuLayout {
    public static let menus: [MenuSection] = [
        MenuSection(title: "Nada", entries: [
            .system("about"),
            .separator,
            .command("settings", symbol: "gearshape"),
            .separator,
            .system("hide"),
            .system("hideOthers"),
            .system("showAll"),
            .separator,
            .system("quit"),
        ]),
        MenuSection(title: "Archivo", entries: [
            .command("new_tab", symbol: "plus.rectangle"),
            .command("open_location", symbol: "link"),
            .command("reopen_tab", symbol: "arrow.uturn.backward"),
            .separator,
            .command("split_right", symbol: "rectangle.righthalf.inset.filled"),
            .command("split_down", symbol: "rectangle.bottomhalf.inset.filled"),
            .separator,
            .command("bookmark_page", symbol: "star"),
            .separator,
            .command("close", symbol: "xmark"),
        ]),
        MenuSection(title: "Edición", entries: [
            .system("undo"),
            .system("redo"),
            .separator,
            .system("cut"),
            .system("copy"),
            .system("paste"),
            .system("selectAll"),
            .separator,
            .submenu("Buscar", symbol: "text.page.badge.magnifyingglass", [
                .command("find", symbol: "magnifyingglass"),
                .command("find_next", symbol: "chevron.down"),
                .command("find_previous", symbol: "chevron.up"),
            ]),
        ]),
        MenuSection(title: "Ver", entries: [
            .command("reload", symbol: "arrow.clockwise"),
            .separator,
            .command("reset_zoom", symbol: "textformat.size"),
            .command("zoom_in", symbol: "textformat.size.larger"),
            .command("zoom_out", symbol: "textformat.size.smaller"),
            .separator,
            .command("palette", symbol: "filemenu.and.selection"),
            .command("bookmarks", symbol: "book"),
            .separator,
            .command("dev_tools", symbol: "scope"),
        ]),
        MenuSection(title: "Historial", entries: [
            .command("back", symbol: "chevron.left"),
            .command("forward", symbol: "chevron.right"),
            .separator,
            .command("clear_history", symbol: "trash"),
        ]),
        MenuSection(title: "Ventana", entries: [
            .system("minimize"),
            .system("zoom"),
            .command("fullscreen", symbol: "arrow.up.left.and.arrow.down.right"),
            .separator,
            .command("previous_tab", symbol: "chevron.left.square"),
            .command("next_tab", symbol: "chevron.right.square"),
            .submenu("Ir a la pestaña", symbol: "number.square", (1...9).map { .command("goto_tab:\($0)", symbol: "\($0).square") }),
            .separator,
            .command("zoom_pane", symbol: "arrow.up.left.and.arrow.down.right.square"),
            .command("focus_previous", symbol: "chevron.left.2"),
            .command("focus_next", symbol: "chevron.right.2"),
            .submenu("Ir al panel", symbol: "rectangle.split.2x2", [
                .command("focus_up", symbol: "arrow.up"),
                .command("focus_down", symbol: "arrow.down"),
                .command("focus_left", symbol: "arrow.left"),
                .command("focus_right", symbol: "arrow.right"),
            ]),
            .submenu("Mover divisor", symbol: "arrow.left.and.right", [
                .command("equalize_panes", symbol: "equal"),
                .separator,
                .command("resize_up", symbol: "arrow.up.to.line"),
                .command("resize_down", symbol: "arrow.down.to.line"),
                .command("resize_left", symbol: "arrow.left.to.line"),
                .command("resize_right", symbol: "arrow.right.to.line"),
            ]),
        ]),
        MenuSection(title: "Ayuda", entries: [
            .system("support"),
        ]),
    ]
}
