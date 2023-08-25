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
    
    static func convertToBlackAndWhite(image: UIImage, pixelWidth: CGFloat) -> UIImage? {
        if let resizedImage = resizeImage(image, toWidth: pixelWidth) {
            return convertToBMW(image: resizedImage, threshold: 100)
        }
        return nil
        let orientedImage = image.oriented()
        let scale = orientedImage.size.width / pixelWidth
        let newHeight = round(orientedImage.size.height / scale)
        let newSize = CGSize(width: pixelWidth, height: newHeight)
        // Convert to grayscale
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: nil, width: Int(pixelWidth), height: Int(newHeight), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).rawValue)
        context?.draw(orientedImage.cgImage!, in: CGRect(origin: .zero, size: newSize))
        guard let grayImage = context?.makeImage() else { return nil }
        // Convert to black and white using threshold
        let length = Int(newSize.width * newSize.height)
        var rawData = [UInt8](repeating: 0, count: length)
        let pixelData = grayImage.dataProvider?.data
        let dataPtr: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        for i in 0..<length {
            let pixel = dataPtr[i]
            rawData[i] = pixel > 100 ? 255 : 0
        }
        let bwContext = CGContext(data: &rawData, width: Int(pixelWidth), height: Int(newHeight), bitsPerComponent: 8, bytesPerRow: Int(pixelWidth), space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).rawValue)
        guard let bwImage = bwContext?.makeImage() else { return nil }
        return UIImage(cgImage: bwImage)
    }

    
    // Step 1: Resize image
    static func resizeImage(_ image: UIImage, toWidth width: CGFloat) -> UIImage? {
        let height = floor(image.size.height * (width / image.size.width))
        let size = CGSize(width: width, height: height)
        
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }

    // Step 2: Dithering
    static func dithered(image: UIImage) -> UIImage? {
        guard let inputCGImage = image.cgImage else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: nil, width: inputCGImage.width, height: inputCGImage.height, bitsPerComponent: 8, bytesPerRow: inputCGImage.width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        context?.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: inputCGImage.width, height: inputCGImage.height))
        
        guard let outputCGImage = context?.makeImage() else { return nil }
        return UIImage(cgImage: outputCGImage)
    }
    
    static func convertToBinaryDataArray(from image: UIImage) -> [Data]? {
        guard let cgImage = convertToBMW(image: image, threshold: 100)?.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var rowsData: [Data] = []
        
        for y in 0..<height {
            var rowData = Data()
            var currentByte: UInt8 = 0
            var bitIndex = 7
            
            for x in 0..<width {
                let pixelIndex = y * width + x
                let pixel = pixels[pixelIndex]
                
                if pixel < 128 {
                    currentByte |= (1 << bitIndex)
                }
                
                if bitIndex == 0 || x == width - 1 {
                    rowData.append(currentByte)
                    currentByte = 0
                    bitIndex = 7
                } else {
                    bitIndex -= 1
                }
            }
            rowsData.append(rowData)
        }
        
        return rowsData
    }
    
    static func generateBinaryDataArray(from image: UIImage, targetWidth: CGFloat = 384) -> [Data]? {
        if let resizedImage = resizeImage(image, toWidth: targetWidth) {
            return convertToBinaryDataArray(from: resizedImage)
        }
        return nil
    }
    
    static func convertToBMW(image: UIImage, threshold: Int) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = height * bytesPerRow

        var pixels = [UInt32](repeating: 0, count: width * height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let pixel = pixels[index]

                let alpha = UInt8((pixel & 0xFF000000) >> 24)
                var red = UInt8((pixel & 0x00FF0000) >> 16)
                var green = UInt8((pixel & 0x0000FF00) >> 8)
                var blue = UInt8((pixel & 0x000000FF) >> 0)

                // Your logic for threshold
                red = red > threshold ? 255 : 0
                green = green > threshold ? 255 : 0
                blue = blue > threshold ? 255 : 0

                pixels[index] = (UInt32(alpha) << 24) | (UInt32(red) << 16) | (UInt32(green) << 8) | UInt32(blue)
            }
        }

        if let newCgImage = context?.makeImage() {
            return UIImage(cgImage: newCgImage)
        }

        return nil
    }


}

