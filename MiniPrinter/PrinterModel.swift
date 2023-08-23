//
//  PrinterModel.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/16.
//

import Foundation

enum Status {
    case good, warning, error, blinking
}

enum PrinterInfoModelError: Error {
    case insufficientData
    case invalidData
}

class PrinterInfoModel: ObservableObject {
    var connectionStatus: Status
    var workingStatus: Status
    var paperStatus: Status
    var battery: Int
    var temperature: Int
    
    // 默认的成员初始化方法
    init(connectionStatus: Status, workingStatus: Status, paperStatus: Status, battery: Int, temperature: Int) {
        self.connectionStatus = connectionStatus
        self.workingStatus = workingStatus
        self.paperStatus = paperStatus
        self.battery = battery
        self.temperature = temperature
    }
    
    // 从Data对象初始化的方法
    init?(data: Data) throws {
        // 确保数据长度足够
        guard data.count >= 4 else {
            throw PrinterInfoModelError.insufficientData
        }
        // 解析电量值（0-100），这里直接解析成Int
        let batteryValue = Int(data[0])
        guard 0...100 ~= batteryValue else {
            throw PrinterInfoModelError.invalidData
        }
        // 解析温度值
        let temperatureValue = Int(data[1])
        // 解析纸张警告状态和工作状态
        let paperWarnValue = data[2]
        let workStatusValue = data[3]
        self.battery = batteryValue
        self.temperature = temperatureValue
        self.paperStatus = paperWarnValue != 0 ? .good : .error
        self.workingStatus = .blinking
        // 这里假设连接成功后，接收通知，所以直接设置为true
        self.connectionStatus = .good
    }
}
