//
//  BTSearchManager.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/14.
//

import Foundation
import CoreBluetooth
import Combine
import SwiftUI

struct BTMacro {
    static let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    static let characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let deviceName = "Mini-Printer"
    static let searchSeconds = 5
}

extension CBPeripheral {
    func estimateDistance(rssi: Double, txPower: Int = -59) -> Double {
        if rssi == 0 {
            return -1.0 // Unknown distance
        }

        let ratio = rssi / Double(txPower)
        if ratio < 1.0 {
            return pow(ratio, 10)
        } else {
            let accuracy = 0.89976 * pow(ratio, 7.7095) + 0.111
            return accuracy
        }
    }
}

enum ConnectionStatus {
    case none
    case connecting
    case connected
    case failed
    case timedOut
}

// MARK: - Error Handling

enum BTError: Error {
    case bluetoothOff
}

class BTSearchManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    
    static let `default` = BTSearchManager()

    private var centralManager: CBCentralManager!
    /// 搜索用的 timer，倒计时
    private var timer: Timer?
    
    let dataSubject = CurrentValueSubject<Data?, Never>(nil)
    
    /// 如果10秒钟没有收到消息，就算已经失去连接
    private var disconnectTimer: DispatchSourceTimer?

    @Published private(set) var discoveredPeripherals: [CBPeripheral] = []
    
    @Published var connectionStatus: ConnectionStatus = .none
    
    @Published var connectedPeripheral: CBPeripheral?
    
    @Published var isSearching = false
    @Published var remainingSeconds = BTMacro.searchSeconds
    @Published var distanceDict = [UUID : Double]()

    static let connectionStateDidChangeNotification = Notification.Name("connectionStateDidChange")

    
    // 假设您已经找到了要写入的特征
    var writeCharacteristic: CBCharacteristic?
    
    // 发送数据到设备
    func sendData(data: Data) {
        if let characteristic = writeCharacteristic {
            // 确保该特征允许写入
            if characteristic.properties.contains(.write) {
                connectedPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
            } else if characteristic.properties.contains(.writeWithoutResponse) {
                connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
            }
        }
    }
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // 搜索附近的蓝牙设备
    func searchForDevices() throws {
        guard centralManager.state == .poweredOn else {
            throw BTError.bluetoothOff
        }
        if !isSearching {
            self.isSearching = true
            self.remainingSeconds = BTMacro.searchSeconds
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.updateCountdown()
            }
            RunLoop.main.add(timer!, forMode: .common)
        }
        DispatchQueue.main.async {
            self.discoveredPeripherals.removeAll()
        }
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    // 连接某个设备
    func connectToDevice(_ peripheral: CBPeripheral) throws {
        resetDisconnectTimer()
        connectionStatus = .connecting
        guard centralManager.state == .poweredOn else {
            connectionStatus = .failed
            throw BTError.bluetoothOff
        }
        self.connectedPeripheral = nil
        centralManager.connect(peripheral, options: nil)
    }
    
    private func updateCountdown() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            isSearching = false
            centralManager.stopScan()
            timer?.invalidate()
            timer = nil
        }
    }

    func handleTimeout() {
        print("Device disconnected due to timeout")
        self.connectedPeripheral = nil
        if connectionStatus != .failed {
            connectionStatus = .timedOut
        }
    }
    
    private func resetDisconnectTimer() {
        disconnectTimer?.cancel()
        disconnectTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        disconnectTimer?.schedule(deadline: .now() + 15)
        disconnectTimer?.setEventHandler { [weak self] in
            self?.handleTimeout()
        }
        disconnectTimer?.resume()
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // 在这里处理蓝牙状态变化
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) && peripheral.name != nil {
            let distance = peripheral.estimateDistance(rssi: RSSI.doubleValue)
            peripheral.delegate = self
            // 存储距离到字典中
            self.distanceDict[peripheral.identifier] = distance
            // 如果设备名称匹配, 直接放在第一位
            if peripheral.name == BTMacro.deviceName {
                discoveredPeripherals.insert(peripheral, at: 0)
            } else {
                // 根据距离找到正确的插入位置
                if let insertIndex = discoveredPeripherals.firstIndex(where: { distanceDict[$0.identifier] ?? .infinity > distance }) {
                    discoveredPeripherals.insert(peripheral, at: insertIndex)
                } else {
                    discoveredPeripherals.append(peripheral)
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // 开始发现指定的服务，如果您不确定要发现的服务的UUID，可以传递nil来发现所有服务
        peripheral.discoverServices([BTMacro.serviceUUID])
        NotificationCenter.default.post(name: BTSearchManager.connectionStateDidChangeNotification, object: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.connectedPeripheral {
            self.connectedPeripheral = nil
            connectionStatus = .failed
        }
        NotificationCenter.default.post(name: BTSearchManager.connectionStateDidChangeNotification, object: peripheral)
    }
    
    // MARK: ------- CBPeripheralDelegate -------
    
    // 发现服务后调用
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!)")
            connectionStatus = .failed
            return
        }
        peripheral.services?.forEach { service in
            print("Found service: \(service)")
            if service.uuid == BTMacro.serviceUUID {
                // 对于每个服务，发现它的特征
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // 发现特征后调用
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print("Found characteristic: \(characteristic)")
            if characteristic.uuid == BTMacro.characteristicUUID {
                self.writeCharacteristic = characteristic
                // 如果这是您想读取的特征，或者您想监听的特征
                if characteristic.properties.contains(.read) {
                    // 读取特征的值
                    peripheral.readValue(for: characteristic)
                }
                if characteristic.properties.contains(.notify) {
                    // 为该特征设置通知以便在值更改时接收更新
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    // 当读取特征值或监听到特征值改变时调用
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, characteristic.uuid == BTMacro.characteristicUUID {
            // 对数据进行处理, 只有读取到了值才算连接成功
            self.connectedPeripheral = peripheral
            connectionStatus = .connected
            resetDisconnectTimer()
            // 发送数据到subject
            dataSubject.send(data)
        }
    }
    
    // 当写操作完成后调用，您可以检查是否有错误
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing characteristic: \(error)")
        } else {
            print("Successfully wrote value for characteristic: \(characteristic)")
        }
    }
    
}
