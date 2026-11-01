import SwiftUI

// Palette: the 16 classic Windows colours, nothing else. No gradients, no rounded corners, no glow.
extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

enum Scam {
    static let silver = Color(hex: 0xC0C0C0)
    static let dkGray = Color(hex: 0x404040)
    static let navy   = Color(hex: 0x000080)
    static let blue   = Color(hex: 0x0000FF)
    static let red    = Color(hex: 0xFF0000)
    static let maroon = Color(hex: 0x800000)
    static let yellow = Color(hex: 0xFFFF00)
    static let green  = Color(hex: 0x008000)
    static let lime   = Color(hex: 0x00FF00)
    static let cream  = Color(hex: 0xFFFFCC)

    static func times(_ size: CGFloat, bold: Bool = false, italic: Bool = false) -> Font {
        switch (bold, italic) {
        case (true, true):  return .custom("TimesNewRomanPS-BoldItalicMT", size: size)
        case (true, false): return .custom("TimesNewRomanPS-BoldMT", size: size)
        case (false, true): return .custom("TimesNewRomanPS-ItalicMT", size: size)
        default:            return .custom("TimesNewRomanPSMT", size: size)
        }
    }
    static func arial(_ size: CGFloat, bold: Bool = true) -> Font {
        .custom(bold ? "Arial-BoldMT" : "ArialMT", size: size)
    }
    static func courier(_ size: CGFloat) -> Font { .custom("CourierNewPS-BoldMT", size: size) }
}

// MARK: - Bevels, windows, buttons

/// 2px Win98 bevel drawn on top of whatever it overlays.
struct BevelBorder: View {
    var raised = true
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let hi: Color = raised ? .white : Scam.dkGray
            let lo: Color = raised ? Scam.dkGray : .white
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: w, y: 0))
                }.stroke(hi, lineWidth: 4)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: w, y: 0))
                }.stroke(lo, lineWidth: 4)
                Rectangle().stroke(Color.black, lineWidth: 2)
            }
            .clipped()
        }
        .allowsHitTesting(false)
    }
}

struct Win98ButtonStyle: ButtonStyle {
    var fill: Color = Scam.silver
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(fill)
            .overlay(BevelBorder(raised: !configuration.isPressed))
            .offset(x: configuration.isPressed ? 1 : 0, y: configuration.isPressed ? 1 : 0)
    }
}

struct WindowFrame<Content: View>: View {
    let title: String
    var onClose: (() -> Void)?
    private let content: Content

    init(title: String, onClose: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(title)
                    .font(Scam.arial(13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Button { onClose?() } label: {
                    Text("X")
                        .font(Scam.arial(11))
                        .foregroundColor(.black)
                        .frame(width: 20, height: 18)
                        .background(Scam.silver)
                        .overlay(BevelBorder())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(Scam.navy)
            .padding(3)

            content
                .padding(.horizontal, 8)
                .padding(.bottom, 10)
                .padding(.top, 4)
        }
        .background(Scam.silver)
        .overlay(BevelBorder())
    }
}

// MARK: - Old-web furniture

struct TiledBackground: View {
    var body: some View {
        Canvas { ctx, size in
            let s: CGFloat = 8
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Scam.navy))
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = row % 2 == 0 ? 0 : s
                while x < size.width {
                    ctx.fill(Path(CGRect(x: x, y: y, width: s, height: s)), with: .color(Scam.blue))
                    x += s * 2
                }
                y += s
                row += 1
            }
        }
    }
}

struct HazardStripe: View {
    var height: CGFloat = 12
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Scam.yellow))
            var x = -size.height
            while x < size.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + 10, y: size.height))
                p.addLine(to: CGPoint(x: x + 10 + size.height, y: 0))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                p.closeSubpath()
                ctx.fill(p, with: .color(.black))
                x += 20
            }
        }
        .frame(height: height)
        .border(Color.black, width: 1)
    }
}

struct Marquee: View {
    let text: String
    var font: Font = Scam.arial(15)
    var color: Color = Scam.red
    @State private var textWidth: CGFloat = 1

    private var label: some View {
        Text(text + "      ")
            .font(font)
            .foregroundColor(color)
            .fixedSize()
            .background(GeometryReader { g in
                Color.clear.onAppear { textWidth = max(g.size.width, 1) }
            })
    }

    // The scrolling copies live in an overlay so their (wide) natural size can never
    // push the page wider than the screen.
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 26)
            .overlay(alignment: .leading) {
                TimelineView(.animation) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    let x = -CGFloat(t * 80).truncatingRemainder(dividingBy: textWidth)
                    HStack(spacing: 0) { label; label; label; label }
                        .offset(x: x)
                }
            }
            .clipped()
            .background(Scam.yellow)
            .border(Color.black, width: 2)
    }
}

struct BlinkText: View {
    let text: String
    var a: Color = Scam.red
    var b: Color = Scam.yellow
    var size: CGFloat = 18
    var body: some View {
        TimelineView(.periodic(from: Date(), by: 0.5)) { tl in
            let on = Int(tl.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            Text(text)
                .font(Scam.arial(size))
                .foregroundColor(on ? a : b)
                .shadow(color: .black, radius: 0, x: 1, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}

/// Segmented Win98 progress bar.
struct BlockBar: View {
    var value: Double
    var blocks = 22
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<blocks, id: \.self) { i in
                Rectangle()
                    .fill(Double(i) < value * Double(blocks) ? Scam.navy : Color.clear)
            }
        }
        .padding(4)
        .frame(height: 28)
        .background(Color.white)
        .overlay(BevelBorder(raised: false))
    }
}

struct HitCounter: View {
    let value: Int
    var body: some View {
        let digits = Array(String(format: "%07d", value))
        HStack(spacing: 2) {
            ForEach(Array(digits.enumerated()), id: \.offset) { _, c in
                Text(String(c))
                    .font(Scam.courier(18))
                    .foregroundColor(Scam.lime)
                    .frame(width: 18, height: 26)
                    .background(Color.black)
                    .overlay(Rectangle().stroke(Scam.dkGray, lineWidth: 1))
            }
        }
    }
}

/// Sunken white panel, like a text area on a 1999 form.
struct Sunken<Content: View>: View {
    var fill: Color = .white
    private let content: Content
    init(fill: Color = .white, @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.content = content()
    }
    var body: some View {
        content
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill)
            .overlay(BevelBorder(raised: false))
    }
}
