import SwiftUI

/// 連絡先ピン。同一座標に複数の連絡先がある場合は件数バッジを付ける。
struct PlacePinView: View {
    let count: Int

    var body: some View {
        VStack(spacing: -2) {
            ZStack {
                Circle()
                    .fill(.red.gradient)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                Image(systemName: "person.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundStyle(.red)
        }
        .overlay(alignment: .topTrailing) {
            if count > 1 {
                Text("\(count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.blue, in: Circle())
                    .offset(x: 8, y: -6)
            }
        }
        .shadow(radius: 2)
    }
}

/// 長押しで置くピン。連絡先ピンと区別できる色にする。
struct DroppedPinView: View {
    var body: some View {
        VStack(spacing: -2) {
            ZStack {
                Circle()
                    .fill(.green.gradient)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                Image(systemName: "mappin")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundStyle(.green)
        }
        .shadow(radius: 2)
    }
}
