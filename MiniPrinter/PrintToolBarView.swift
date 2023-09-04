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
    let modeOptions: [String] = ["高质量", "高效"]
    @Published var modeSelection: String = "高效" {
        didSet {
            recreatePreviewImage()
        }
    }

    @Published var isOneTimePrint: Bool = false
    @Published var previewImage: UIImage?
    @Published var isPreview: Bool = false
    @Published var uiImage: UIImage?
    
    @Published var printImage: UIImage?
    
    @Published var threshold: Double = 127
    
    @Published var isTextMode: Bool = false {
        didSet {
            self.threshold = isTextMode ? 200 : 127
            recreatePreviewImage()
        }
    }
    
    var isPreviewing = false

    var imagePreviewCallback: ((UIImage?) -> Void)?
    var imagePrintCallback: ((Bool) -> Void)?
    
    func recreatePreviewImage() {
        if let image = uiImage {
            if isPreview {
                guard let image = ImageSuperHelper.resizeImage(image: image, newWidth: 384) else {
                    return
                }
                if modeSelection == "高效" {
                    previewImage = ImageSuperHelper.floydSteinbergDithering(source: image, threshold: Int(threshold), isTextModel: isTextMode)
                } else {
                    previewImage = ImageSuperHelper.stuckiDithering(source: image, threshold: Int(threshold), isTextModel: isTextMode)
                }
                isPreview = true
            }
        }
    }

    func handlePreview() {
        // 预览的处理
        if let _ = uiImage {
            isPreview.toggle()
            recreatePreviewImage()
        } else {
            Toast.showWarning("请选择或拍摄一张图片再开始预览")
        }
    }
    
    func handleSliderChange(value: Double) {
        if let _ = uiImage {
            recreatePreviewImage()
        }
    }
    
    func handlePrint() {
        if BTSearchManager.default.connectionStatus != .connected {
            Toast.showError("请先连接设备")
        }
        // 打印的处理
        if let _ = uiImage {
            isPreview = true
            recreatePreviewImage()
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
        VStack(spacing: 6) {
            HStack(spacing: 15) {
                // Text Mode Checkbox
                Toggle("文本模式", isOn: $viewModel.isTextMode)
                    .frame(width: 82)
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.leading, 8)
                if viewModel.isPreview {
                    Slider(value: $viewModel.threshold, in: 0...240, step: 1, onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.handleSliderChange(value: viewModel.threshold)
                            }
                        })
                        .padding(.horizontal)
                        .accentColor(.blue)
                    Text("\(Int(viewModel.threshold))")
                        .foregroundColor(.black)
                } else {
                    Spacer()
                }
            }.frame(height: 35)
            HStack(spacing: 10) {
                // Print Density Menu
                printModeView
                printDensityView
                Spacer()
                // Print Button
                previewButton
                printButton
            }
        }.padding(.horizontal)
    }
    
    var previewButton: some View {
        Button(action: {
            self.viewModel.handlePreview()
        }) {
            Image(systemName: "eye")
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.isPreview ? Color.gray : Color.gray.opacity(0.1)))
        }
        .foregroundColor(.primary)
    }
    
    var printButton: some View {
        Button(action: {
            self.viewModel.handlePrint()
        }) {
            Image(systemName: "printer")
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
        }
        .foregroundColor(.primary)
    }
    
    var printDensityView: some View {
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
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
        }
    }
    
    var printModeView: some View {
        // Mode Selection Menu
        Menu {
            ForEach(viewModel.modeOptions, id: \.self) { option in
                Button(option) {
                    viewModel.modeSelection = option
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text("\(viewModel.modeSelection)")
                Image(systemName: "slider.horizontal.3")
            }
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
        }
    }
}


struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
