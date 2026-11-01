import Foundation

struct RamPack: Identifiable, Equatable {
    let id: Int
    let label: String
    let tagline: String

    static let all: [RamPack] = [
        RamPack(id: 0, label: "8 GB",       tagline: "DDR4 - FREE"),
        RamPack(id: 1, label: "32 GB",      tagline: "DDR5 - FREE!!"),
        RamPack(id: 2, label: "128 GB",     tagline: "DDR6 - FREE!!!"),
        RamPack(id: 3, label: "1 TB",       tagline: "DDR7 ULTRA - FREE!!!!!"),
        RamPack(id: 4, label: "UNLIMITED",  tagline: "FREE* (*terms apply)")
    ]
}

struct PopupScript {
    let title: String
    let message: String

    static let all: [PopupScript] = [
        PopupScript(title: "Congratulations!!!", message: "You are the 1,000,000th visitor! Click OK to claim your FREE RAM."),
        PopupScript(title: "System Alert", message: "Your RAM is lonely. Download a friend for it."),
        PopupScript(title: "WAIT!", message: "Are you sure you want to leave? Your free RAM expires in 00:59."),
        PopupScript(title: "Error", message: "Error: Success. Please try again."),
        PopupScript(title: "Hot Singles", message: "Hot single RAM sticks in your area want to meet you!"),
        PopupScript(title: "Warning", message: "Your phone has 0 viruses. This is suspicious. Click OK to investigate.")
    ]
}

struct FakePopup: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dx: Double
    let dy: Double
}
