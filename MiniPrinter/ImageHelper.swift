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


class ImageProcessor {

    static func convertToBMW(image: UIImage, threshold: Int) -> (UIImage, [Data]) {
        guard let rImage = ImageHelper.resizeImage(image, toWidth: 384) else {
            return (image, [])
        }
        guard let cgImage = rImage.cgImage else { return (image, []) }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: height * width * 4)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        let context = CGContext(data: &rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var outputData: [Data] = []
        
        for y in 0..<height {
            var rowData: Data = Data()
            var currentByte: UInt8 = 0
            var bitIndex = 7
            
            for x in 0..<width {
                let byteIndex = (bytesPerRow * y) + x * bytesPerPixel
                let red = rawData[byteIndex]
                let green = rawData[byteIndex + 1]
                let blue = rawData[byteIndex + 2]
                
                let isRedAboveThreshold = red <= UInt8(threshold)
                let isGreenAboveThreshold = green <= UInt8(threshold)
                let isBlueAboveThreshold = blue <= UInt8(threshold)
                
                if isRedAboveThreshold { rawData[byteIndex] = 255 } else { rawData[byteIndex] = 0 }
                if isGreenAboveThreshold { rawData[byteIndex + 1] = 255 } else { rawData[byteIndex + 1] = 0 }
                if isBlueAboveThreshold { rawData[byteIndex + 2] = 255 } else { rawData[byteIndex + 2] = 0 }
                
                // Determine if pixel is 'colored' or not
                if isRedAboveThreshold || isGreenAboveThreshold || isBlueAboveThreshold {
                    currentByte |= (1 << bitIndex)
                }
                
                if bitIndex == 0 {
                    rowData.append(currentByte)
                    currentByte = 0
                    bitIndex = 7
                } else {
                    bitIndex -= 1
                }
            }
            
            if bitIndex != 7 {
                rowData.append(currentByte)
            }
            
            outputData.append(rowData)
        }
        
        let outputCGImage = context?.makeImage()
        let outputImage = UIImage(cgImage: outputCGImage!)
        
        return (outputImage, outputData)
    }

    static func convertToBinary(image: UIImage, threshold: Int) -> [Data] {
        guard let rImage = ImageHelper.resizeImage(image, toWidth: 384) else {
            return []
        }
        guard let cgImage = rImage.cgImage else {
            return []
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4

        // 用于存储每一行的Data
        var rowsData: [Data] = []

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: height * width * bytesPerPixel)
        defer {
            rawData.deallocate()
        }
        
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        let context = CGContext(data: rawData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        for y in 0 ..< height {
            var rowData = Data()
            var byte: UInt8 = 0
            var bitIndex = 7

            for x in 0 ..< width {
                let byteIndex = bytesPerRow * y + bytesPerPixel * x

                let red = rawData[byteIndex]
                let green = rawData[byteIndex + 1]
                let blue = rawData[byteIndex + 2]

                let grayValue = (Int(red) + Int(green) + Int(blue)) / 3

                if grayValue <= threshold {
                    byte |= (1 << bitIndex)
                }

                if bitIndex == 0 {
                    rowData.append(byte)
                    byte = 0
                    bitIndex = 7
                } else {
                    bitIndex -= 1
                }
            }


            if bitIndex != 7 {
                rowData.append(byte)
            }

            rowsData.append(rowData)
        }

        return rowsData
    }
}

class ImageSuperHelper {

    static func convertToPrinterFormat(image: UIImage) -> (UIImage, [Data])? {
        guard let resizedImage = resizeImage(image: image, newWidth: 384) else {
            return nil
        }

        guard let bwImage = floydSteinbergDithering(source: resizedImage) else {
            return nil
        }

        let dataRows = convertToDataRows(bwImage: bwImage)

        return (bwImage, dataRows)
    }

    static func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        if newWidth == image.size.width {
            return image
        }
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    static func floydSteinbergDithering(source: UIImage, threshold: Int = 127) -> UIImage? {
        guard let inputCGImage = source.cgImage else { return nil }
        let width = inputCGImage.width
        let height = inputCGImage.height

        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 0, count: width * height)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = Int(pixels[index])
                let newPixel = oldPixel > threshold ? 255 : 0
                pixels[index] = UInt8(newPixel)
                let quantError = oldPixel - newPixel

                if x < width - 1 {
                    pixels[index + 1] = UInt8(clamping: Int(pixels[index + 1]) + quantError * 7 / 16)
                }
                if y < height - 1 {
                    if x > 0 {
                        pixels[index + width - 1] = UInt8(clamping: Int(pixels[index + width - 1]) + quantError * 3 / 16)
                    }
                    pixels[index + width] = UInt8(clamping: Int(pixels[index + width]) + quantError * 5 / 16)
                    if x < width - 1 {
                        pixels[index + width + 1] = UInt8(clamping: Int(pixels[index + width + 1]) + quantError * 1 / 16)
                    }
                }
            }
        }

        guard let outputCGImage = context?.makeImage() else { return nil }
        return UIImage(cgImage: outputCGImage)
    }

    static func convertToDataRows(bwImage: UIImage) -> [Data] {
        guard let cgImage = bwImage.cgImage else { return [] }

        let width = cgImage.width
        let height = cgImage.height

        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 0, count: width * height)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var rows: [Data] = []
        for y in 0..<height {
            var rowData = Data(count: width / 8)
            for x in 0..<width {
                let byteIndex = x / 8
                let bitIndex = 7 - (x % 8)
                if pixels[y * width + x] == 0 { // if pixel is black
                    let mask = UInt8(1 << bitIndex)
                    rowData[byteIndex] |= mask
                }
            }
            rows.append(rowData)
        }

        return rows
    }

}
