import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func icon(_ pixels: Int) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let unit = CGFloat(pixels) / 1024
    let body = NSRect(x: 100 * unit, y: 100 * unit, width: 824 * unit, height: 824 * unit)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185 * unit, yRadius: 185 * unit)
    NSColor(srgbRed: 0.106, green: 0.110, blue: 0.153, alpha: 1).setFill()
    shape.fill()
    NSColor(srgbRed: 0.204, green: 0.212, blue: 0.290, alpha: 1).setStroke()
    shape.lineWidth = 8 * unit
    shape.stroke()
    NSColor(srgbRed: 0.424, green: 0.769, blue: 0.949, alpha: 1).setFill()
    NSBezierPath(
        roundedRect: NSRect(x: 220 * unit, y: 730 * unit, width: 340 * unit, height: 44 * unit),
        xRadius: 22 * unit, yRadius: 22 * unit
    ).fill()
    NSGraphicsContext.current = nil
    return bitmap.representation(using: .png, properties: [:])!
}

for (points, scale) in [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)] {
    let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
    try icon(points * scale).write(to: output.appending(path: name))
}
