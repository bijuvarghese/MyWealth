//
//  InitalLoadingView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/15/25.
//

import SwiftUI

struct InitalLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            Image("launchImage")
            Spacer()
            ProgressView() {
                Text("Loading...")
            }
            .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.launch)
    }
}
