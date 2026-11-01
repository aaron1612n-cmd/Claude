import SwiftUI

struct DownloadView: View {
    let pack: RamPack
    @Environment(\.dismiss) private var dismiss

    private enum Phase { case downloading, stuck, survey, share, done }

    @State private var phase: Phase = .downloading
    @State private var progress = 0.0
    @State private var question = 0
    @State private var shared = 0
    @State private var ticks = 0
    @State private var speed = "13.37"
    @State private var eta = "3 days 4 hrs"
    @State private var confirmCancel = false

    private let ticker = Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()

    private let survey: [(q: String, a: [String])] = [
        ("Are you a robot?", ["Yes", "No", "Beep boop"]),
        ("How many gigabytes are in a gigabyte?", ["1", "A lot", "Yes"]),
        ("Rate your free RAM experience", ["5 stars", "5 stars", "5 stars"])
    ]

    var body: some View {
        ZStack {
            TiledBackground().ignoresSafeArea()
            ScrollView {
                WindowFrame(title: "Downloading RAM...", onClose: { confirmCancel = true }) {
                    VStack(alignment: .leading, spacing: 12) {
                        switch phase {
                        case .downloading, .stuck: downloadBody
                        case .survey: surveyBody
                        case .share: shareBody
                        case .done: doneBody
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
        }
        .onReceive(ticker) { _ in tick() }
        .alert("Are you sure?", isPresented: $confirmCancel) {
            Button("No, go back", role: .cancel) { }
            Button("Yes (lose RAM forever)", role: .destructive) { dismiss() }
        } message: {
            Text("If you cancel now your free RAM will be LOST FOREVER.")
        }
    }

    // MARK: phases

    private var downloadBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("free_ram_\(pack.label.replacingOccurrences(of: " ", with: "_")).zip")
                .font(Scam.courier(15)).foregroundColor(.black)
            Text(stageText).font(Scam.times(15)).foregroundColor(.black)
            BlockBar(value: progress)
            Sunken {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress:  \(Int(progress * 100))%").font(Scam.courier(13)).foregroundColor(.black)
                    Text("Speed:     \(speed) KB/s").font(Scam.courier(13)).foregroundColor(.black)
                    Text("Time left: \(eta)").font(Scam.courier(13)).foregroundColor(.black)
                }
            }
            if phase == .stuck {
                BlinkText(text: "ERROR 0x00000RAM", size: 17)
                Text("The RAM server is full. To continue, please complete 3 quick surveys.")
                    .font(Scam.times(15, bold: true)).foregroundColor(Scam.red)
                Button { phase = .survey } label: {
                    Text("CONTINUE >>").font(Scam.arial(18)).foregroundColor(.black).frame(maxWidth: .infinity)
                }
                .buttonStyle(Win98ButtonStyle())
            } else {
                Button { confirmCancel = true } label: {
                    Text("Cancel").font(Scam.arial(14)).foregroundColor(.black).frame(width: 90)
                }
                .buttonStyle(Win98ButtonStyle())
            }
        }
    }

    private var surveyBody: some View {
        let item = survey[min(question, survey.count - 1)]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Quick survey \(question + 1) of \(survey.count)")
                .font(Scam.times(13, italic: true)).foregroundColor(Scam.dkGray)
            Text(item.q).font(Scam.times(20, bold: true)).foregroundColor(Scam.navy)
            ForEach(Array(item.a.enumerated()), id: \.offset) { _, answer in
                Button { advanceSurvey() } label: {
                    Text(answer).font(Scam.arial(16)).foregroundColor(.black).frame(maxWidth: .infinity)
                }
                .buttonStyle(Win98ButtonStyle())
            }
            Text("Your answers are not recorded. Nothing is.")
                .font(Scam.times(11, italic: true)).foregroundColor(Scam.dkGray)
        }
    }

    private var shareBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Almost there!").font(Scam.times(22, bold: true, italic: true)).foregroundColor(Scam.red)
            Text("Share with 20 friends to unlock your RAM.").font(Scam.times(16)).foregroundColor(.black)
            BlockBar(value: Double(shared) / 20.0)
            Text("Shared: \(shared)/20").font(Scam.courier(15)).foregroundColor(.black)
            Text("(we made up your friends for you)")
                .font(Scam.times(12, italic: true)).foregroundColor(Scam.dkGray)
        }
    }

    private var doneBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            BlinkText(text: "DOWNLOAD COMPLETE!!!", a: Scam.green, b: Scam.lime, size: 22)
            BlockBar(value: 1.0)
            Sunken(fill: Scam.cream) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RAM added:    +0.00 GB").font(Scam.courier(14)).foregroundColor(.black)
                    Text("Total RAM:    unchanged").font(Scam.courier(14)).foregroundColor(.black)
                    Text("Viruses:      0").font(Scam.courier(14)).foregroundColor(.black)
                }
            }
            HazardStripe()
            Text("APRIL FOOLS!")
                .font(Scam.times(26, bold: true, italic: true))
                .foregroundColor(Scam.red)
                .shadow(color: .black, radius: 0, x: 2, y: 2)
            Text("You cannot download RAM. This app is a joke and your phone is perfectly fine. Nothing was downloaded, collected or sent anywhere.")
                .font(Scam.times(15)).foregroundColor(.black)
            HStack(spacing: 8) {
                Button { reset() } label: {
                    Text("Download MORE RAM").font(Scam.arial(14)).foregroundColor(.black).frame(maxWidth: .infinity)
                }
                .buttonStyle(Win98ButtonStyle(fill: Scam.lime))
                Button { dismiss() } label: {
                    Text("Close").font(Scam.arial(14)).foregroundColor(.black).frame(width: 70)
                }
                .buttonStyle(Win98ButtonStyle())
            }
        }
    }

    // MARK: logic

    private var stageText: String {
        switch progress {
        case ..<0.10: return "Connecting to the RAM server..."
        case ..<0.25: return "Finding spare RAM on the internet..."
        case ..<0.45: return "Asking your neighbour for RAM..."
        case ..<0.65: return "Downloading RAM... (do not close this window)"
        case ..<0.85: return "Compressing RAM into a zip file..."
        case ..<0.97: return "Installing RAM driver v2.0 (cracked)..."
        default:      return "Almost done... any second now..."
        }
    }

    private func tick() {
        ticks += 1
        switch phase {
        case .downloading:
            progress = min(0.99, progress + Double.random(in: 0.0005...0.006))
            if ticks % 8 == 0 {
                speed = String(format: "%.2f", Double.random(in: 0.5...99.9))
                eta = ["3 days 4 hrs", "17 hrs", "1 year", "47 min", "NaN"].randomElement() ?? "NaN"
            }
            if progress >= 0.99 { phase = .stuck }
        case .share:
            if ticks % 5 == 0 && shared < 20 { shared += 1 }
            if shared >= 20 { phase = .done }
        default:
            break
        }
    }

    private func advanceSurvey() {
        if question + 1 >= survey.count {
            phase = .share
        } else {
            question += 1
        }
    }

    private func reset() {
        progress = 0; question = 0; shared = 0; ticks = 0
        phase = .downloading
    }
}
