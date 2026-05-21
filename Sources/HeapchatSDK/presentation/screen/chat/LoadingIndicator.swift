//
//  ActivityIndicator.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import SwiftUI
import ExyteActivityIndicator

struct LoadingIndicator: View {
    var body: some View {
        ZStack {
            Color(.gray)
                .frame(width: 100, height: 100)
                .cornerRadius(8)
            
            ActivityIndicatorView(isVisible: .constant(true), type: .flickeringDots())
                .foregroundColor(Color.black)
                .frame(width: 50, height: 50)
        }
    }
}
