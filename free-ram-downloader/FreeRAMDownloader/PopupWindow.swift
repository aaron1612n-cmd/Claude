import SwiftUI

struct PopupWindow: View {
    let popup: FakePopup
    let onClose: () -> Void

    var body: some View {
        WindowFrame(title: popup.title, onClose: onClose) {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Text("!")
                        .font(Scam.times(26, bold: true))
                        .foregroundColor(Scam.navy)
                        .frame(width: 34, height: 34)
                        .background(Scam.yellow)
                        .border(Color.black, width: 2)
                    Text(popup.message)
                        .font(Scam.times(15))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 10) {
                    Button(action: onClose) { Text("OK").font(Scam.arial(14)).foregroundColor(.black).frame(width: 60) }
                        .buttonStyle(Win98ButtonStyle())
                    Button(action: onClose) { Text("Cancel").font(Scam.arial(14)).foregroundColor(.black).frame(width: 60) }
                        .buttonStyle(Win98ButtonStyle())
                }
            }
            .padding(.top, 6)
        }
        .frame(width: 280)
        .shadow(color: .black, radius: 0, x: 4, y: 4)
    }
}
