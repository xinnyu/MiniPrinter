//
//  PrintToolBarView.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/15.
//

import SwiftUI
import JGProgressHUD_SwiftUI


class PrintToolBarViewModel: ObservableObject {
    let densities = ["高", "中", "低"]
    @Published var printDensity: String = "中"
    
}

struct PrintToolBarView: View {
    @EnvironmentObject private var hudCoordinator: JGProgressHUDCoordinator
    @StateObject var viewModel = PrintToolBarViewModel()

    var body: some View {
        HStack(spacing: 15) {
            // Print Density Menu
            Menu {
                ForEach(viewModel.densities, id: \.self) { density in
                    Button(density) {
                        viewModel.printDensity = density
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("密度: \(viewModel.printDensity)")
                    Image(systemName: "slider.horizontal.3")
                }
                .foregroundColor(.black)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
            }
            
            Spacer()

            // Buttons on the right
            HStack(spacing: 12) {
                // Print Preview Button
                Button(action: {
                    // Handle print preview action
                }) {
                    Image(systemName: "eye")
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                }
                .foregroundColor(.black)
                
                // Print Button
                Button(action: {
                    self.hudCoordinator.showLoading()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        hudCoordinator.hideLoading()
                    }
                }) {
                    Image(systemName: "printer")
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                }
                .foregroundColor(.black)
            }
        }
        .padding(.horizontal)
    }
}

struct PrintToolBarView_Previews: PreviewProvider {
    static var previews: some View {
        PrintToolBarView()
    }
}
