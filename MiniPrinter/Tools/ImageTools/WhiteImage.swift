//
//  WhiteImage.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/17.
//

import UIKit

extension UIImage {
    static func whiteImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        UIColor.white.setFill()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
