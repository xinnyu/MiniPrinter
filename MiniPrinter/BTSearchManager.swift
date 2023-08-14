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

class BTSearchManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    
    static let searchSeconds = 5
    
    private var centralManager: CBCentralManager!
    private var timer: Timer?
    
    @Published private(set) var discoveredPeripherals: [CBPeripheral] = []
    @Published var isSearching = false
    @Published var remainingSeconds = searchSeconds
    @Published var distanceDict = [UUID : Double]()

    static let connectionStateDidChangeNotification = Notification.Name("connectionStateDidChange")

    override init() {
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
            self.remainingSeconds = BTSearchManager.searchSeconds
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
    func connectToDevice(_ peripheral: CBPeripheral) async throws {
        guard centralManager.state == .poweredOn else {
            throw BTError.bluetoothOff
        }
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
            // 根据距离找到正确的插入位置
            if let insertIndex = discoveredPeripherals.firstIndex(where: { distanceDict[$0.identifier] ?? .infinity > distance }) {
                discoveredPeripherals.insert(peripheral, at: insertIndex)
            } else {
                discoveredPeripherals.append(peripheral)
            }
        }
    }


    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NotificationCenter.default.post(name: BTSearchManager.connectionStateDidChangeNotification, object: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NotificationCenter.default.post(name: BTSearchManager.connectionStateDidChangeNotification, object: peripheral)
    }
    
    // MARK: ------- CBPeripheralDelegate -------
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        let distance = peripheral.estimateDistance(rssi: RSSI.doubleValue)
        self.distanceDict[peripheral.identifier] = distance
    }

    // MARK: - Error Handling

    enum BTError: Error {
        case bluetoothOff
    }
}
