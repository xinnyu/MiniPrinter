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
    @Published var printDensity: String = "中" {
        didSet {
            sendPrintDensity(printDensity)
        }
    }
    @Published var isOneTimePrint: Bool = false
    @Published var previewImage: UIImage?
    @Published var isPreview: Bool = false
    @Published var uiImage: UIImage?
    
    @Published var printImage: UIImage?
    
    @Published var threshold: Double = 127

    var imagePreviewCallback: ((UIImage?) -> Void)?
    var imagePrintCallback: ((Bool) -> Void)?

    func handlePreview() {
        // 预览的处理
        if let image = uiImage {
            if previewImage == nil {
                guard let image = ImageSuperHelper.resizeImage(image: image, newWidth: 384) else { return }
                previewImage = ImageSuperHelper.floydSteinbergDithering(source: image)
            }
            isPreview.toggle()
        } else {
            Toast.showWarning("请选择或拍摄一张图片再开始预览")
        }
    }
    
    func handleSliderChange(value: Double) {
        if let image = uiImage {
            guard let image = ImageSuperHelper.resizeImage(image: image, newWidth: 384) else { return }
            previewImage = ImageSuperHelper.floydSteinbergDithering(source: image, threshold: Int(value))
            isPreview = true
        }
    }
    
    func handlePrint() {
        if BTSearchManager.default.connectionStatus != .connected {
            Toast.showError("请先连接设备")
        }
        // 打印的处理
        if let image = uiImage {
            if previewImage == nil {
                previewImage = ImageHelper.convertToBlackAndWhite(image: image, pixelWidth: 384)
                isPreview = true
            }
            self.imagePrintCallback?(isOneTimePrint)
        } else {
            Toast.showWarning("请选择或拍摄一张图片再开始打印")
        }
    }
    
    func sendPrintDensity(_ density: String) {
        if BTSearchManager.default.connectionStatus != .connected {
            Toast.showError("请先连接设备")
        }
        var data = Data([0xA5, 0xA5, 0xA5, 0xA5])
        switch density {
        case "低":
            data.append(0x01)
        case "中":
            data.append(0x02)
        case "高":
            data.append(0x03)
        default:
            data.append(0x01)
        }
        BTSearchManager.default.sendDatasWithoutResponse([data]) {
            Toast.showComplete("设置打印密度成功：\(density)")
        }
    }
}

struct PrintToolBarView: View {
    @EnvironmentObject private var hudCoordinator: JGProgressHUDCoordinator
    @ObservedObject var viewModel: PrintToolBarViewModel

    var body: some View {
        HStack(spacing: 15) {
            
            if viewModel.isPreview {
                Slider(value: $viewModel.threshold, in: 0...254, step: 1, onEditingChanged: { isEditing in
                        if !isEditing {
                            viewModel.handleSliderChange(value: viewModel.threshold)
                        }
                    })
                    .padding(.horizontal)
                    .accentColor(.blue)
                Text("\(Int(viewModel.threshold))")
                    .foregroundColor(.black)
            } else {
                // Print Density Menu
                Menu {
                    ForEach(viewModel.densities, id: \.self) { density in
                        Button(density) {
                            viewModel.printDensity = density
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("密度")
                        Image(systemName: "slider.horizontal.3")
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                }
            }
            Spacer()
            HStack(spacing: 12) {
                Button(action: {
                    self.viewModel.handlePreview()
                }) {
                    Image(systemName: "eye")
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.isPreview ? Color.gray : Color.gray.opacity(0.1)))
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
