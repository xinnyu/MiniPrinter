//
//  File.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/24.
//

import SwiftUI
import AlertToast
import JGProgressHUD_SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ParentViewModel()
    var body: some View {
        VStack {
            Text(viewModel.isPrinting ? "printing" : "NO")
            ChildView(viewModel: viewModel.childViewModel)
        }
        .ignoresSafeArea()
    }
}

class ParentViewModel: ObservableObject {
    
    @Published var childViewModel = ChildViewModel()
    @Published var isPrinting: Bool = false
    
}

class ChildViewModel: ObservableObject {
    @Published var isPrinting: Bool = false
    
    func handlePrint() {
        self.isPrinting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isPrinting = false
        }
    }
}

struct ChildView: View {
    @ObservedObject var viewModel: ChildViewModel
    var body: some View {
        Button(action: {
            self.viewModel.handlePrint()
        }) {
            Image(systemName: "printer")
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(viewModel.isPrinting ? Color.gray : Color.gray.opacity(0.1)))
        }
        .foregroundColor(.black)
    }
}
