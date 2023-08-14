//
//  BluetoothDevice.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/14.
//

import Foundation

struct BluetoothDevice: Identifiable {
    var id: UUID = UUID()
    var name: String
    var macAddress: String
}

