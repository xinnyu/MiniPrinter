//
//  ImageExtensions.swift
//  MiniPrinter
//
//  Created by PAN XINYU on 2023/8/26.
//

import UIKit


extension UIImage {
    // 调整图片大小
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // 将图片转换为灰度图片
    func grayscale() -> UIImage? {
        let context = CIContext()
        let currentFilter = CIFilter(name: "CIColorControls")
        let beginImage = CIImage(image: self)
        currentFilter?.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter?.setValue(0, forKey: kCIInputSaturationKey)
        guard let output = currentFilter?.outputImage else { return nil }
        if let cgimg = context.createCGImage(output, from: output.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            return processedImage
        }
        return nil
    }
    
    // 对图片进行二值化处理
    func binary(dithered: Bool = true) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let bitsPerComponent = 8
        let bytesPerRow = width
        var pixelValues = [UInt8](repeating: 0, count: width * height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: &pixelValues, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * width + x
                let pixelValue = pixelValues[pixelIndex]
                pixelValues[pixelIndex] = pixelValue > 127 ? 255 : 0
            }
        }

        let outputContext = CGContext(data: &pixelValues, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        guard let outputCGImage = outputContext?.makeImage() else { return nil }
        return UIImage(cgImage: outputCGImage)
    }
    
    // 将图片转换为每一行的二值化 Data 数组
    func toBinaryDataArray() -> [Data]? {
        guard let cgImage = self.cgImage else { return nil }
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let bitsPerComponent = 8
        let bytesPerRow = width
        var pixelValues = [UInt8](repeating: 0, count: width * height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: &pixelValues, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var dataArray: [Data] = []

        for y in 0..<height {
            var rowData: Data = Data()
            for x in 0..<width where x % 8 == 0 {
                var byte: UInt8 = 0
                for i in 0..<8 {
                    let pixelIndex = y * width + x + i
                    let pixelValue = pixelValues[pixelIndex]
                    if pixelValue > 127 {
                        byte |= (0x01 << (7 - i))
                    }
                }
                rowData.append(byte)
            }
            dataArray.append(rowData)
        }

        return dataArray
    }
    
    // 使用Floyd-Steinberg抖动进行二值化
    func dithered() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        var pixelValues = [UInt8](repeating: 0, count: width * height)

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: &pixelValues, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var quantError: Int

        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let oldPixel = Int(pixelValues[index])
                let newPixel = oldPixel > 127 ? 255 : 0
                pixelValues[index] = UInt8(newPixel)

                quantError = oldPixel - newPixel
                
                if x < width - 1 {
                    pixelValues[index + 1] = UInt8(clamp(Int(pixelValues[index + 1]) + quantError * 7 / 16))
                }
                if y < height - 1 {
                    pixelValues[index + width] = UInt8(clamp(Int(pixelValues[index + width]) + quantError * 5 / 16))
                    if x > 0 {
                        pixelValues[index + width - 1] = UInt8(clamp(Int(pixelValues[index + width - 1]) + quantError * 3 / 16))
                    }
                    if x < width - 1 {
                        pixelValues[index + width + 1] = UInt8(clamp(Int(pixelValues[index + width + 1]) + quantError * 1 / 16))
                    }
                }
            }
        }

        let ditheredContext = CGContext(data: &pixelValues, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        guard let ditheredCGImage = ditheredContext?.makeImage() else { return nil }

        return UIImage(cgImage: ditheredCGImage)
    }

    private func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T {
        return min(max(value, lower), upper)
    }

    private func clamp(_ value: Int) -> Int {
        return clamp(value, lower: 0, upper: 255)
    }
}
