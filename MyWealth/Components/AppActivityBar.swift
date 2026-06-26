import SwiftUI

struct AppActivityBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { proxy in
            let segmentWidth = max(proxy.size.width * 0.34, 88)

            ZStack(alignment: .leading) {
                WealthMapDesignTokens.ColorToken.brandPrimary.opacity(0.16)

                Capsule(style: .continuous)
                    .fill(WealthMapDesignTokens.ColorToken.brandPrimary)
                    .frame(width: segmentWidth)
                    .offset(
                        x: reduceMotion
                            ? (proxy.size.width - segmentWidth) / 2
                            : (isAnimating ? proxy.size.width : -segmentWidth)
                    )
                    .opacity(reduceMotion ? 0.78 : 1)
            }
            .clipped()
        }
        .frame(height: 3)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.05).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Loading and syncing data")
        .allowsHitTesting(false)
    }
}
