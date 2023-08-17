//
//  ZoomableImageView.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/16.
//

import SwiftUI

struct ZoomableImageView: UIViewRepresentable {
    @Binding var uiImage: UIImage?

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0

        let imageView = UIImageView(image: uiImage)
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView  // Keep a reference to the imageView
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Update the image when `uiImage` changes
        context.coordinator.imageView?.image = uiImage
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView? // Store a weak reference to avoid retain cycle
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
    }
}
