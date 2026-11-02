import AppKit

// Renders the ROK wordmark the launch screen shows, at 1x/2x/3x.
// Mirrors the home header: system medium, bone, wide tracking.
let bone = NSColor(srgbRed: 0xf3/255.0, green: 0xee/255.0, blue: 0xe7/255.0, alpha: 1)
let baseSize = CGSize(width: 150, height: 52)
let basePoint: CGFloat = 40
let baseTracking: CGFloat = 8.8

for scale in [1, 2, 3] {
  let s = CGFloat(scale)
  let px = CGSize(width: baseSize.width * s, height: baseSize.height * s)
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
    pixelsWide: Int(px.width), pixelsHigh: Int(px.height),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  NSColor.clear.setFill()
  NSRect(origin: .zero, size: px).fill()

  let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: basePoint * s, weight: .medium),
    .foregroundColor: bone,
    .kern: baseTracking * s,
  ]
  let text = NSAttributedString(string: "ROK", attributes: attrs)
  var size = text.size()
  // .kern adds trailing space after the last glyph; drop it when centring.
  size.width -= baseTracking * s
  text.draw(at: NSPoint(x: (px.width - size.width) / 2,
                        y: (px.height - size.height) / 2))

  NSGraphicsContext.restoreGraphicsState()
  let name = scale == 1 ? "LaunchImage.png" : "LaunchImage@\(scale)x.png"
  let url = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent(name)
  try! rep.representation(using: .png, properties: [:])!.write(to: url)
  print("wrote \(name) \(Int(px.width))x\(Int(px.height))")
}
