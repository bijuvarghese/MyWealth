//
//  PillLabel.swift
//  MyWealth
//
//  Created by Biju Varghese on 5/21/26.
//

import DesignSystem
import SwiftUI

typealias PillLabelStyle = StatusBadgeStyle

struct PillLabel: View {
    let title: String
    let style: PillLabelStyle

    init(
        _ title: String,
        style: PillLabelStyle = .accent
    ) {
        self.title = title
        self.style = style
    }

    var body: some View {
        StatusBadge(title, style: style)
    }
}
