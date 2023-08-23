//
//  ImageHelper.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/23.
//

import UIKit

extension UIImage {
    func oriented() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let orientedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return orientedImage
    }
}


class ImageHelper {
    
    static func convertToGrayScaleAndDither(image: UIImage, pixelWidth: CGFloat) -> UIImage? {
        let orientedImage = image.oriented()
        let scale = orientedImage.size.width / pixelWidth
        let newHeight = round(orientedImage.size.height / scale)
        let newSize = CGSize(width: pixelWidth, height: newHeight)
        // Convert to grayscale
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: nil, width: Int(pixelWidth), height: Int(newHeight), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).rawValue)
        context?.draw(orientedImage.cgImage!, in: CGRect(origin: .zero, size: newSize))
        guard let grayImage = context?.makeImage() else { return nil }
        // Apply threshold dithering
        let data = CFDataCreateMutable(nil, 0)!
        let length = Int(newSize.width * newSize.height)
        var rawData = [UInt8](repeating: 0, count: length)
        let pixelData = grayImage.dataProvider?.data
        let dataPtr: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        for i in 0..<length {
            let pixel = dataPtr[i]
            rawData[i] = pixel > 127 ? 255 : 0
        }
        CFDataAppendBytes(data, rawData, length)
        guard let ditheredImage = context?.makeImage() else { return nil }
        return UIImage(cgImage: ditheredImage)
    }
    
    static func convertImageToBinaryRows(image: UIImage) -> [Data]? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = cgImage.bytesPerRow
        
        guard let pixelData = cgImage.dataProvider?.data else { return nil }
        let pixelPointer: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        var dataArray: [Data] = []
        
        for row in 0..<height {
            var rowData: Data = Data(capacity: width / 8) // 384/8 = 48 bytes per row
            for byteIndex in 0..<(width / 8) {
                var byte: UInt8 = 0
                for bitIndex in 0..<8 {
                    let pixelIndex = row * bytesPerRow + (byteIndex * 8 + bitIndex) * 4 // assuming 4 bytes per pixel (RGBA)
                    let grayValue = pixelPointer[pixelIndex]
                    if grayValue > 127 {
                        byte |= (1 << (7 - bitIndex))
                    }
                }
                rowData.append(byte)
            }
            dataArray.append(rowData)
        }
        return dataArray
    }

}



