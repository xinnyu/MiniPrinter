//
//  ImageEditor.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/16.
//

import SwiftUI

struct ImageEditor: UIViewControllerRepresentable {
    
    var orImage: UIImage?
    @Binding var uiImage: UIImage?
    @Binding var editModel: ZLEditImageModel?
    @Binding var isShown: Bool
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImageEditor>) -> UINavigationController {
        ZLImageEditorConfiguration.default()
            // Provide a image sticker container view
            .imageStickerContainerView(ImageStickerContainerView())
            .fontChooserContainerView(FontChooserContainerView())
            // Custom filter
//            .filters = [.normal]
            .canRedo(true)
//        ZLImageEditorConfiguration.default().tools = [.clip, .mosaic, .imageSticker, .textSticker]
        let image = orImage ?? uiImage ?? UIImage()
        let vc = ZLEditImageViewController(image: image, editModel: editModel)
        vc.editFinishBlock = { ei, editImageModel in
            self.uiImage = ei
            editModel = editImageModel
            self.isShown = false
        }
        vc.dismissBlock = {
            self.isShown = false
        }
        let navController = UINavigationController(rootViewController: vc)
        navController.navigationBar.isHidden = true
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: UIViewControllerRepresentableContext<ImageEditor>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject,  UIAdaptivePresentationControllerDelegate {
        var parent: ImageEditor

        init(_ parent: ImageEditor) {
            self.parent = parent
            
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            parent.isShown = false
        }
    }
}
