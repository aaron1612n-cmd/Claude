import SwiftUI

struct HomeView: View {
    @State private var selected = 1
    @State private var activePack: RamPack?
    @State private var showScan = false
    @State private var popups: [FakePopup] = []
    @State private var firstPopupScheduled = false

    var body: some View {
        ZStack {
            TiledBackground().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    Marquee(text: "*** CONGRATULATIONS!!! YOU ARE VISITOR NUMBER 1,000,000 *** CLAIM YOUR FREE RAM NOW ***")

                    WindowFrame(title: "FREE_RAM.EXE - Internet Explorer", onClose: spawnPopup) {
                        VStack(alignment: .leading, spacing: 12) {
                            header
                            HazardStripe()
                            warningBox
                            stepOne
                            stepTwo
                            decoyAds
                            testimonials
                            badges
                        }
                    }

                    footer
                }
                .padding(8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }

            ZStack {
                ForEach(popups) { p in
                    PopupWindow(popup: p) { closePopup(p) }
                        .offset(x: p.dx, y: p.dy)
                }
            }
        }
        .fullScreenCover(item: $activePack) { pack in DownloadView(pack: pack) }
        .fullScreenCover(isPresented: $showScan) { ScanView() }
        .onAppear {
            guard !firstPopupScheduled else { return }
            firstPopupScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { spawnPopup() }
        }
    }

    // MARK: sections

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Image("Logo")
                .interpolation(.none)
                .resizable()
                .frame(width: 96, height: 96)
                .border(Color.black, width: 2)
            VStack(alignment: .leading, spacing: 2) {
                Text("FREE RAM")
                    .font(Scam.times(38, bold: true, italic: true))
                    .foregroundColor(Scam.red)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("DOWNLOADER")
                    .font(Scam.times(22, bold: true))
                    .foregroundColor(Scam.blue)
                    .underline()
                Text("Version 9.9.9 ULTRA PRO (cracked)")
                    .font(Scam.times(13, italic: true))
                    .foregroundColor(.black)
            }
        }
    }

    private var warningBox: some View {
        Sunken(fill: Scam.cream) {
            VStack(alignment: .leading, spacing: 6) {
                BlinkText(text: "WARNING!!! YOUR RAM IS LOW!!!", size: 17)
                HStack {
                    Text("Installed RAM:").font(Scam.times(15)).foregroundColor(.black)
                    Spacer()
                    Text("4 GB").font(Scam.times(15, bold: true)).foregroundColor(Scam.red)
                }
                BlockBar(value: 0.01)
                HStack {
                    Text("Recommended:").font(Scam.times(15)).foregroundColor(.black)
                    Spacer()
                    Text("999 GB").font(Scam.times(15, bold: true)).foregroundColor(Scam.green)
                }
                Text("Your device is SLOW because it does not have enough RAM. Download more RAM below. It is 100% FREE and takes only 3 seconds*.")
                    .font(Scam.times(14))
                    .foregroundColor(.black)
                Text("*3 seconds = approximately 3 days")
                    .font(Scam.times(11, italic: true))
                    .foregroundColor(Scam.dkGray)
            }
        }
    }

    private var stepOne: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STEP 1: Choose your FREE RAM")
                .font(Scam.times(18, bold: true))
                .foregroundColor(Scam.navy)
            ForEach(RamPack.all) { pack in
                Button { selected = pack.id } label: {
                    HStack(spacing: 10) {
                        Text(selected == pack.id ? "X" : " ")
                            .font(Scam.courier(14))
                            .foregroundColor(.black)
                            .frame(width: 20, height: 20)
                            .background(Color.white)
                            .overlay(BevelBorder(raised: false))
                        Text(pack.label)
                            .font(Scam.times(17, bold: true))
                            .foregroundColor(.black)
                        Text(pack.tagline)
                            .font(Scam.times(14))
                            .foregroundColor(Scam.red)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STEP 2: Click the button")
                .font(Scam.times(18, bold: true))
                .foregroundColor(Scam.navy)
            Button {
                activePack = RamPack.all[selected]
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down.to.line")
                    Text("DOWNLOAD NOW!!!")
                    Spacer()
                }
                .font(Scam.arial(22))
                .foregroundColor(.black)
                .padding(.vertical, 6)
            }
            .buttonStyle(Win98ButtonStyle())

            Button { activePack = RamPack.all[selected] } label: {
                Text("Click here if your download does not start")
                    .font(Scam.times(14))
                    .foregroundColor(Scam.blue)
                    .underline()
            }
            .buttonStyle(.plain)

            Button { showScan = true } label: {
                Text("[ FREE virus scan - 7 viruses found on this page ]")
                    .font(Scam.times(14, bold: true))
                    .foregroundColor(Scam.blue)
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }

    /// The classic wall of fake download buttons. Every one of them is an ad.
    private var decoyAds: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Advertisement")
                .font(Scam.arial(9, bold: false))
                .foregroundColor(Scam.dkGray)
            HStack(spacing: 6) {
                decoy("DOWNLOAD", Scam.lime)
                decoy("START", Scam.yellow)
                decoy("DOWNLOAD MORE CPU", Scam.green)
            }
        }
    }

    private func decoy(_ text: String, _ fill: Color) -> some View {
        Button(action: spawnPopup) {
            Text(text)
                .font(Scam.arial(12))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 40)
                .padding(.horizontal, 4)
        }
        .buttonStyle(Win98ButtonStyle(fill: fill))
    }

    private var testimonials: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What our customers say:")
                .font(Scam.times(18, bold: true, italic: true))
                .foregroundColor(Scam.navy)
            quote("My phone now thinks it is a laptop. Thank you!!!", "Karen, Ohio")
            quote("Downloaded 1 TB. Phone got heavier. 5 stars.", "Dave, Texas")
            quote("My doctor HATES this one weird trick.", "Linda, Florida")
        }
    }

    private func quote(_ text: String, _ who: String) -> some View {
        Sunken {
            VStack(alignment: .leading, spacing: 2) {
                Text("\"\(text)\"").font(Scam.times(14, italic: true)).foregroundColor(.black)
                HStack {
                    Text("- \(who)").font(Scam.times(12, bold: true)).foregroundColor(Scam.dkGray)
                    Spacer()
                    Text("*****").font(Scam.courier(14)).foregroundColor(Scam.maroon)
                }
            }
        }
    }

    private var badges: some View {
        HStack(spacing: 6) {
            badge("100%\nSAFE", fill: Scam.green, text: .white)
            badge("NO\nVIRUS", fill: Scam.navy, text: .white)
            badge("AS SEEN\nON TV", fill: Scam.red, text: Scam.yellow)
            badge("VERIFIED\nLEGIT", fill: Scam.yellow, text: .black)
        }
    }

    private func badge(_ text: String, fill: Color, text color: Color) -> some View {
        Text(text)
            .font(Scam.arial(11))
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(fill)
            .border(Color.black, width: 2)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HazardStripe()
            BlinkText(text: "THIS PAGE IS UNDER CONSTRUCTION", a: Scam.yellow, b: .white, size: 14)
            Text("You are visitor number")
                .font(Scam.times(14)).foregroundColor(.white)
            HitCounter(value: 1_000_000)
            Text("Best viewed in Netscape Navigator 4.0 at 800x600")
                .font(Scam.times(12, italic: true)).foregroundColor(.white)
            Text("(c) 1999-2003 FreeRAM Inc. All rights reserved.\nTHIS APP IS A JOKE. No RAM is downloaded. It is physically impossible.")
                .font(Scam.times(11))
                .foregroundColor(Scam.silver)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
        }
        .padding(.top, 6)
    }

    // MARK: popups

    private func spawnPopup() {
        guard popups.count < 4, let s = PopupScript.all.randomElement() else { return }
        popups.append(FakePopup(title: s.title, message: s.message,
                                dx: Double.random(in: -40...40),
                                dy: Double.random(in: -140...100)))
    }

    private func closePopup(_ p: FakePopup) {
        popups.removeAll { $0.id == p.id }
        if Int.random(in: 0..<3) == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { spawnPopup() }
        }
    }
}
