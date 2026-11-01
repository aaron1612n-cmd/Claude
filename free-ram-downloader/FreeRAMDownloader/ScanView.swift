import SwiftUI

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss

    private let threats = [
        "Trojan.Horse.Of.Troy",
        "Win32.Memory.Leech",
        "Cookie.Monster.exe",
        "Your.Ex.Texts.dll",
        "Mom.Found.Your.Browser.History",
        "Clippy.Wants.To.Talk",
        "Worm.Gigabyte.Eater.vbs"
    ]
    private let paths = [
        "C:\\WINDOWS\\SYSTEM32\\RAM.DLL",
        "C:\\Program Files\\Setup Files\\setup.exe",
        "C:\\My Documents\\homework (2).doc",
        "C:\\WINDOWS\\Temp\\~DF0A2B.tmp",
        "C:\\Games\\Minesweeper\\mines.exe",
        "C:\\WINDOWS\\Fonts\\comic.ttf"
    ]

    @State private var found = 0
    @State private var progress = 0.0
    @State private var finished = false
    @State private var showRemoved = false

    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            TiledBackground().ignoresSafeArea()
            ScrollView {
                WindowFrame(title: "VirusScan 2003 - FREE", onClose: { dismiss() }) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(finished ? "Scan complete." : "Scanning: \(paths[Int(progress * 100) % paths.count])")
                            .font(Scam.courier(12)).foregroundColor(.black).lineLimit(2)
                        BlockBar(value: progress)

                        Sunken {
                            VStack(alignment: .leading, spacing: 3) {
                                if found == 0 {
                                    Text("No threats found yet...").font(Scam.courier(13)).foregroundColor(Scam.dkGray)
                                }
                                ForEach(0..<found, id: \.self) { i in
                                    Text("! \(threats[i])").font(Scam.courier(13)).foregroundColor(Scam.red)
                                }
                            }
                            .frame(minHeight: 150, alignment: .topLeading)
                        }

                        if finished {
                            BlinkText(text: "\(threats.count) THREATS FOUND!!!", size: 22)
                            Button { showRemoved = true } label: {
                                Text("REMOVE ALL (FREE!)").font(Scam.arial(18)).foregroundColor(.black).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(Win98ButtonStyle(fill: Scam.lime))
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
        }
        .onReceive(ticker) { _ in
            guard !finished else { return }
            progress = min(1, progress + 0.006)
            found = min(threats.count, Int(progress * Double(threats.count + 1)))
            if progress >= 1 { found = threats.count; finished = true }
        }
        .alert("Threats removed!", isPresented: $showRemoved) {
            Button("Phew", role: .cancel) { dismiss() }
        } message: {
            Text("All 7 threats were removed. Your phone is now 100% protected. Please restart it 7 times.")
        }
    }
}
