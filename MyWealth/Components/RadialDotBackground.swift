//
//  Untitled.swift
//  MyWealth
//
//  Created by Biju Varghese on 5/19/26.
//

import SwiftUI

struct RadialDotBackground: View {
    var dotColor: Color = Color(red: 166/255, green: 23/255, blue: 142/255)
    var dotRadius: CGFloat = 1
    var spacing: CGFloat = 16
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Canvas { context, _ in
                let step = spacing
                let circle = Path(ellipseIn: CGRect(x: 0, y: 0, width: dotRadius * 2, height: dotRadius * 2))
                for y in stride(from: 0.0, through: size.height, by: step) {
                    for x in stride(from: 0.0, through: size.width, by: step) {
                        var t = context
                        t.translateBy(x: x, y: y)
                        t.fill(circle, with: .color(dotColor))
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}
