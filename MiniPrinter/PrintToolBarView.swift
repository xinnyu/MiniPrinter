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
    
    var uiImage: UIImage?
    
    var imagePreviewCallback: ((UIImage?) -> Void)?
    var imagePrintCallback: ((UIImage?) -> Void)?

    func handlePreview() {
        // 预览的处理
        if let image = uiImage {
            let changedImage = ImageHelper.convertToGrayScaleAndDither(image: image, pixelWidth: 384)
            self.imagePreviewCallback?(changedImage)
        }
    }
    
    func handlePrint() {
        // 打印的处理
        if let image = uiImage {
            let changedImage = ImageHelper.convertToGrayScaleAndDither(image: image, pixelWidth: 384)
            self.imagePrintCallback?(changedImage)
        }
    }
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
                    self.viewModel.handlePreview()
                }) {
                    Image(systemName: "eye")
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                }
                .foregroundColor(.black)
                
                // Print Button
                Button(action: {
                    self.viewModel.handlePrint()
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
