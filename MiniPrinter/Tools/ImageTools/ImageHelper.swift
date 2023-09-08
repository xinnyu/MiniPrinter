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

    static func floydSteinbergDithering(source: UIImage, threshold: Int = 127, isTextModel: Bool = false) -> UIImage? {
        guard let inputCGImage = source.cgImage else { return nil }
        let width = inputCGImage.width
        let height = inputCGImage.height

        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 0, count: width * height)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var isTextPixel: [Bool] = Array(repeating: false, count: width * height)
        
        if isTextModel {
            // Simple Edge Detection
            let edgeThreshold = 10
            for y in 1..<height-1 {
                for x in 1..<width-1 {
                    let index = y * width + x
                    let pixelValue = Int(pixels[index])
                    let leftValue = Int(pixels[index - 1])
                    let rightValue = Int(pixels[index + 1])
                    let topValue = Int(pixels[index - width])
                    let bottomValue = Int(pixels[index + width])
                    
                    if abs(pixelValue - leftValue) > edgeThreshold ||
                       abs(pixelValue - rightValue) > edgeThreshold ||
                       abs(pixelValue - topValue) > edgeThreshold ||
                       abs(pixelValue - bottomValue) > edgeThreshold {
                        isTextPixel[index] = true
                    }
                }
            }
        }

        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x

                if isTextModel && isTextPixel[index] {
                    pixels[index] = pixels[index] > threshold ? 255 : 0
                    continue
                }

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

    static func stuckiDithering(source: UIImage, threshold: Int = 127, isTextModel: Bool = false) -> UIImage? {
        guard let inputCGImage = source.cgImage else { return nil }
        let width = inputCGImage.width
        let height = inputCGImage.height

        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 0, count: width * height)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var isTextPixel: [Bool] = Array(repeating: false, count: width * height)
        
        if isTextModel {
            // Simple Edge Detection
            let edgeThreshold = 10
            for y in 1..<height-1 {
                for x in 1..<width-1 {
                    let index = y * width + x
                    let pixelValue = Int(pixels[index])
                    let leftValue = Int(pixels[index - 1])
                    let rightValue = Int(pixels[index + 1])
                    let topValue = Int(pixels[index - width])
                    let bottomValue = Int(pixels[index + width])
                    
                    if abs(pixelValue - leftValue) > edgeThreshold ||
                       abs(pixelValue - rightValue) > edgeThreshold ||
                       abs(pixelValue - topValue) > edgeThreshold ||
                       abs(pixelValue - bottomValue) > edgeThreshold {
                        isTextPixel[index] = true
                    }
                }
            }
        }
        
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                
                if isTextModel && isTextPixel[index] {
                    pixels[index] = pixels[index] > threshold ? 255 : 0
                    continue
                }
                
                let oldPixel = Int(pixels[index])
                let newPixel = oldPixel > threshold ? 255 : 0
                pixels[index] = UInt8(newPixel)
                let quantError = oldPixel - newPixel

                // Stucki dithering error diffusion
                let offsets: [(Int, Int, Int)] = [
                    (1, 0, 8), (2, 0, 4),
                    (-2, 1, 2), (-1, 1, 4), (0, 1, 8), (1, 1, 4), (2, 1, 2),
                    (-2, 2, 1), (-1, 2, 2), (0, 2, 4), (1, 2, 2), (2, 2, 1)
                ]

                for offset in offsets {
                    let (dx, dy, factor) = offset
                    let destX = x + dx
                    let destY = y + dy
                    if destX >= 0 && destX < width && destY >= 0 && destY < height {
                        let destIndex = destY * width + destX
                        let adjustedValue = Int(pixels[destIndex]) + quantError * factor / 42
                        pixels[destIndex] = UInt8(clamping: adjustedValue)
                    }
                }
            }
        }

        guard let outputCGImage = context?.makeImage() else { return nil }
        return UIImage(cgImage: outputCGImage)
    }

    static func jarvisJudiceNinkeDithering(source: UIImage, threshold: Int = 127) -> UIImage? {
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

                // JJN dithering error diffusion
                let offsets: [(Int, Int, Int)] = [
                    (1, 0, 7), (2, 0, 5),
                    (-2, 1, 3), (-1, 1, 5), (0, 1, 7), (1, 1, 5), (2, 1, 3),
                    (-2, 2, 1), (-1, 2, 3), (0, 2, 5), (1, 2, 3), (2, 2, 1)
                ]

                for offset in offsets {
                    let (dx, dy, factor) = offset
                    let destX = x + dx
                    let destY = y + dy
                    if destX >= 0 && destX < width && destY >= 0 && destY < height {
                        let destIndex = destY * width + destX
                        let adjustedValue = Int(pixels[destIndex]) + quantError * factor / 48
                        pixels[destIndex] = UInt8(clamping: adjustedValue)
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
