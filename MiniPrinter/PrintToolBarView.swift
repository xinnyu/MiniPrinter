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

    var imagePreviewCallback: ((UIImage?) -> Void)?
    var imagePrintCallback: ((Bool) -> Void)?

    func handlePreview() {
        // 预览的处理
        if let image = uiImage {
            if previewImage == nil {
                previewImage = ImageHelper.convertToBlackAndWhite(image: image, pixelWidth: 384)
            }
            isPreview.toggle()
        } else {
            Toast.showWarning("请选择或拍摄一张图片再开始预览")
        }
    }
    
    func handlePrint() {
        // 打印的处理
        if let image = uiImage {
            if previewImage == nil {
                previewImage = ImageHelper.convertToBlackAndWhite(image: image, pixelWidth: 384)
            }
            self.imagePrintCallback?(isOneTimePrint)
        } else {
            Toast.showWarning("请选择或拍摄一张图片再开始打印")
        }
    }
    
    func sendPrintDensity(_ density: String) {
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
        BTSearchManager.default.sendDatasWithoutResponse([data]) {}
    }
}

struct PrintToolBarView: View {
    @EnvironmentObject private var hudCoordinator: JGProgressHUDCoordinator
    @ObservedObject var viewModel: PrintToolBarViewModel

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
                    Text("密度")
                    Image(systemName: "slider.horizontal.3")
                }
                .foregroundColor(.black)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
            }
            Text("兼容")
                .foregroundColor(.black)
            .toggleStyle(SwitchToggleStyle(tint: .gray))
            Toggle(isOn: $viewModel.isOneTimePrint) {
            }.frame(width: 50)
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
