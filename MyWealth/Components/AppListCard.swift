import DesignSystem
import SwiftUI

struct AppListCard<Content: View>: View {
    let content: Content
    let contentPadding: EdgeInsets

    init(
        contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.contentPadding = contentPadding
    }

    var body: some View {
        DesignSystem.Card(contentPadding: contentPadding) {
            content
        }
    }
}

extension View {
    func appListRow(
        insets: EdgeInsets = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
    ) -> some View {
        listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
            .listRowInsets(insets)
    }
}
