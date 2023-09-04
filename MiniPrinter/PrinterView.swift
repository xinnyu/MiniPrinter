//
//  PrinterView.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/15.
//

import SwiftUI
import AlertToast
import LBJImagePreviewer
import JGProgressHUD_SwiftUI

enum PresentingState {
    case none
    case imagePicker
    case actionSheet
    case imageEditor
}

extension Binding where Value == PresentingState {
    func binding(for state: PresentingState) -> Binding<Bool> {
        Binding<Bool>(
            get: { self.wrappedValue == state },
            set: { newValue in
                self.wrappedValue = newValue ? state : .none
            }
        )
    }
}

struct PrinterView: View {
    
    @State private var imagePickerType: ImagePickerType? = nil
    @EnvironmentObject private var hudCoordinator: JGProgressHUDCoordinator

    private var isImagePickerShown: Binding<Bool> {
        $presentingState.binding(for: .imagePicker)
    }
    
    private var isActionSheetShown: Binding<Bool> {
        $presentingState.binding(for: .actionSheet)
    }
    
    private var isImageEditorShown: Binding<Bool> {
        $presentingState.binding(for: .imageEditor)
    }
    
    @State private var presentingState: PresentingState = .none
    
    @State private var editModel: ZLEditImageModel? = nil

    // View model
    @StateObject var viewModel = PrinterViewModel()

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
            .fullScreenCover(isPresented: isImagePickerShown, content: {
                if let type = imagePickerType {
                    imagePickerView(type: type)
                }
            })
            .fullScreenCover(isPresented: isImageEditorShown, content: {
                ImageEditor(orImage:viewModel.orImage, uiImage: $viewModel.uiImage, editModel: $editModel, isShown: isImageEditorShown)
                    .ignoresSafeArea()
            })
        }.onChange(of: viewModel.showLoading) { newValue in
            if (newValue) {
                hudCoordinator.showLoading(msg: "下发中")
            } else {
                hudCoordinator.hideLoading()
            }
        }
    }
}

// MARK: - Subviews
private extension PrinterView {
    var printerInfo: some View {
        PrinterInfoView(viewModel: $viewModel.infoModel)
    }
    
    var imageDisplayArea: some View {
        ZStack {
            Rectangle().fill(Color.gray.opacity(0.1))
            if let image = viewModel.isPreview ? viewModel.toolBarViewModel.previewImage : viewModel.uiImage {
                ZoomableImageView(uiImage:Binding.constant(image)).onTapGesture {
                    presentingState = .imageEditor
                }
            } else {
                Text("请选择或拍摄一张图片")
                    .foregroundColor(.gray)
            }
            addImageButton(geometry: CGSize(width: 384, height: 384 * 1.41))
        }
    }
    
    func addImageButton(geometry: CGSize) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        presentingState = .actionSheet
                    }
                }) {
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
                .actionSheet(isPresented: isActionSheetShown) {
                    ActionSheet(title: Text("选择图片来源"), buttons: [
                        .default(Text("拍照"), action: {
                            imagePickerType = .camera
                            presentingState = .imagePicker
                        }),
                        .default(Text("从相册选择"), action: {
                            imagePickerType = .photoLibrary
                            presentingState = .imagePicker
                        }),
                        .default(Text("开始空白图片"), action: {
                            viewModel.orImage = UIImage.whiteImage(size: geometry)
                            presentingState = .imageEditor
                        }),
                        .cancel()
                    ])
                }
            }
        }
    }
    
    var printToolBar: some View {
        PrintToolBarView(viewModel: viewModel.toolBarViewModel).frame(height: 90)
    }
    
    func imagePickerView(type: ImagePickerType) -> some View {
        ImagePicker(selectedImage: $viewModel.uiImage, isShown: isImagePickerShown, sourceType: type.uiImagePickerType())
            .ignoresSafeArea()
            .onDisappear {
                if let image = viewModel.uiImage {
                    viewModel.orImage = image
//                    isImageEditorShown = true
                }
            }
    }
}
