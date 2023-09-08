//
//  LongPressModifier.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/25.
//

import SwiftUI

struct LongPressModifier: ViewModifier {
    var isEnabled: Bool
    // Add any other properties or callbacks needed for the long press gesture here
    var action: (() -> Void)?

    func body(content: Content) -> some View {
        if isEnabled {
            return content
                .onLongPressGesture {
                    // Handle long press gesture here
                    print("Long pressed!")
                    self.action?()
                }
                .eraseToAnyView()
        } else {
            return content.eraseToAnyView()
        }
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

