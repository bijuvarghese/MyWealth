//
//  PillLabel.swift
//  MyWealth
//
//  Created by Biju Varghese on 5/21/26.
//

import SwiftUI

struct PillLabelStyle {
    let foreground: Color
    let background: Color
    let border: Color
    let borderWidth: CGFloat
    
    let font: Font
    
    init(foreground: Color, background: Color, border: Color, borderWidth: CGFloat = 1.0, font: Font = .footnote.weight(.semibold)) {
        self.foreground = foreground
        self.background = background
        self.border = border
        self.font = font
        self.borderWidth = borderWidth
    }
}

extension PillLabelStyle {
    
    static let accent = PillLabelStyle(
        foreground: .accentColor,
        background: .accentColor.opacity(0.15),
        border: .accentColor.opacity(0.25)
    )

    static let success = PillLabelStyle(
        foreground: .green,
        background: .green.opacity(0.15),
        border: .green.opacity(0.25)
    )

    static let warning = PillLabelStyle(
        foreground: .orange,
        background: .orange.opacity(0.15),
        border: .orange.opacity(0.25)
    )

    static let danger = PillLabelStyle(
        foreground: .red,
        background: .red.opacity(0.15),
        border: .red.opacity(0.25)
    )
}

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
        Text(title)
            .font(style.font)
            .foregroundStyle(style.foreground)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(style.background)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(style.border, lineWidth: style.borderWidth)
            )
    }
}
