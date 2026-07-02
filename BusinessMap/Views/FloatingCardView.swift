import SwiftUI

/// レギュラー幅 (iPad など) でシートの代わりに使うフローティングカード。
/// コンパクト幅のシートと同じコンテンツを、地図を隠さないサイズで
/// 左下に重ねて表示する。
struct FloatingCardView<Content: View>: View {
    /// カードの最大高さ。画面が低い場合はそれ以下に縮む
    let height: CGFloat
    /// コンテンツ自身が閉じるボタンを持たない場合に ✕ ボタンを重ねる
    let showsCloseButton: Bool
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .scrollContentBackground(.hidden)
            .overlay(alignment: .topTrailing) {
                if showsCloseButton {
                    closeButton
                }
            }
            .frame(width: 380)
            .frame(maxHeight: height)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            .padding(12)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 26))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                // HIG の最小タップターゲット 44pt を確保する
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(4)
        .accessibilityLabel(Text("common.close"))
    }
}
