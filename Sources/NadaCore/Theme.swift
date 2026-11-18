import Foundation

public struct RGB: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init?(hex text: String) {
        let digits = text.trimmingCharacters(in: .whitespaces).drop { $0 == "#" }
        guard digits.count == 6, let value = Int(digits, radix: 16) else { return nil }
        self.init(value)
    }

    public init(_ value: Int) {
        red = Double(value >> 16 & 0xFF) / 255
        green = Double(value >> 8 & 0xFF) / 255
        blue = Double(value & 0xFF) / 255
    }

    private init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public var hex: String {
        String(format: "#%02x%02x%02x", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }

    public var luminance: Double {
        0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    public func mixed(with other: RGB, _ amount: Double) -> RGB {
        RGB(
            red: red + (other.red - red) * amount,
            green: green + (other.green - green) * amount,
            blue: blue + (other.blue - blue) * amount
        )
    }
}

public struct ThemeColors: Equatable, Sendable {
    public static let builtIn = [
        "nada": "background = #1b1c27\nforeground = #cdd0e6\npalette = 4=#6cc4f2",
        "nada-light": "background = #f5f5f8\nforeground = #1b1c27\npalette = 4=#1583bd",
    ]

    public static let fallback = ThemeColors(background: RGB(0x1B1C27), foreground: RGB(0xCDD0E6), accent: RGB(0x6CC4F2))

    public let background: RGB
    public let foreground: RGB
    public let accent: RGB

    private init(background: RGB, foreground: RGB, accent: RGB) {
        self.background = background
        self.foreground = foreground
        self.accent = accent
    }

    public init?(ghostty text: String) {
        var values: [String: String] = [:]
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            if parts[0] == "palette", parts[1].hasPrefix("4=") {
                values["accent"] = String(parts[1].dropFirst(2))
            } else {
                values[parts[0]] = parts[1]
            }
        }
        guard let background = values["background"].flatMap(RGB.init(hex:)),
              let foreground = values["foreground"].flatMap(RGB.init(hex:)) else { return nil }
        self.background = background
        self.foreground = foreground
        accent = (values["accent"] ?? values["cursor-color"]).flatMap(RGB.init(hex:)) ?? foreground
    }

    public var isDark: Bool {
        background.luminance < 0.5
    }

    public var bar: RGB {
        background.mixed(with: foreground, 0.06)
    }

    public var raised: RGB {
        background.mixed(with: foreground, 0.12)
    }

    public var dim: RGB {
        foreground.mixed(with: background, 0.35)
    }
}

public struct ThemeChoice: Equatable, Sendable {
    private let light: String
    private let dark: String

    public init(config: String) {
        var light = "nada-light"
        var dark = "nada"
        for line in config.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, parts[0] == "theme" else { continue }
            for name in parts[1].split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
                if name.hasPrefix("light:") {
                    light = String(name.dropFirst(6))
                } else if name.hasPrefix("dark:") {
                    dark = String(name.dropFirst(5))
                } else {
                    light = name
                    dark = name
                }
            }
        }
        self.light = light
        self.dark = dark
    }

    public func name(dark isDark: Bool) -> String {
        isDark ? dark : light
    }
}
