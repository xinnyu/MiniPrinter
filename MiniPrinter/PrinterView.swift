//
//  PrinterView.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/15.
//

import SwiftUI
import AlertToast
import LBJImagePreviewer

struct PrinterView: View {
    // Image states
    @State private var uiImage: UIImage? = nil
    @State private var isActionSheetShown = false
    @State private var imagePickerType: ImagePickerType? = nil
    @State private var isImagePickerShown: Bool = false
    @State private var orImage: UIImage?

    @State private var isImageEditorShown: Bool = false
    @State private var editModel: ZLEditImageModel? = nil

    // View model
    @ObservedObject var viewModel = PrinterViewModel()

    var body: some View {
        ZStack {
            // Main Content
            VStack {
                printerInfo
                Spacer()
                imageDisplayArea
                Spacer()
                printToolBar
            }
            .fullScreenCover(isPresented: $isImagePickerShown, content: {
                if let type = imagePickerType {
                    imagePickerView(type: type)
                }
            })
            .fullScreenCover(isPresented: $isImageEditorShown, content: {
                ImageEditor(orImage:orImage, uiImage: $uiImage, editModel: $editModel, isShown: $isImageEditorShown)
                    .ignoresSafeArea()
            })
        }
    }
}

// MARK: - Subviews
private extension PrinterView {
    var printerInfo: some View {
        PrinterInfoView(viewModel: viewModel.infoModel)
    }
    
    var imageDisplayArea: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(Color.gray.opacity(0.1))
                if let img = uiImage {
                    ZoomableImageView(uiImage: .constant(img)).onTapGesture {
                        isImageEditorShown = true
                    }
                } else {
                    Text("请选择或拍摄一张图片")
                        .foregroundColor(.gray)
                }
                addImageButton(geometry: CGSize(width: geometry.size.width, height: geometry.size.width * 2))
            }
        }
    }
    
    func addImageButton(geometry: CGSize) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { isActionSheetShown = true }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
                .actionSheet(isPresented: $isActionSheetShown) {
                    ActionSheet(title: Text("选择图片来源"), buttons: [
                        .default(Text("拍照"), action: {
                            imagePickerType = .camera
                            isImagePickerShown = true
                        }),
                        .default(Text("从相册选择"), action: {
                            imagePickerType = .photoLibrary
                            isImagePickerShown = true
                        }),
                        .default(Text("开始空白图片"), action: {
                            orImage = UIImage.whiteImage(size: geometry)
                            isImageEditorShown = true
                        }),
                        .cancel()
                    ])
                }
            }
        }
    }
    
    var printToolBar: some View {
        PrintToolBarView(viewModel: viewModel.toolBarViewModel).frame(height: 70)
    }
    
    func imagePickerView(type: ImagePickerType) -> some View {
        ImagePicker(selectedImage: $uiImage, isShown: $isImagePickerShown, sourceType: type.uiImagePickerType())
            .ignoresSafeArea()
            .onDisappear {
                if let image = uiImage {
                    orImage = image
//                    isImageEditorShown = true
                }
            }
    }
}
