//
//  PrinterInfoView.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/15.
//

import SwiftUI

extension Bool {
    var status: Status {
        if self {
            return .good
        } else {
            return .error
        }
    }
}

class PrinterInfoViewModel: ObservableObject {
    @Published var printerInfo: PrinterInfoModel = PrinterInfoModel(connectionStatus: true, workingStatus: true, paperStatus: true, battery: 0, temperature: 0)
}

struct PrinterInfoView: View {
    @StateObject var viewModel = PrinterInfoViewModel()
    
    var body: some View {
        // 打印机状态信息
        HStack {
            CircleStatusIndicator(label: "连接", status: viewModel.printerInfo.connectionStatus.status)
            Spacer()
            CircleStatusIndicator(label: "工作", status: viewModel.printerInfo.workingStatus.status)
            Spacer()
            CircleStatusIndicator(label: "缺纸", status: viewModel.printerInfo.paperStatus.status)
            Spacer()
            StatusIndicator(label: "电量", value: "\(viewModel.printerInfo.battery)%")
            Spacer()
            StatusIndicator(label: "温度", value: "\(viewModel.printerInfo.temperature)°C")
        }.padding()
    }
}

struct StatusIndicator: View {
    var label: String
    var value: String?
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value ?? "")
                .font(.headline)
                .padding(.horizontal, 4)
        }
    }
}

enum Status {
    case good, warning, error
}

struct CircleStatusIndicator: View {
    var label: String
    var status: Status
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Circle()
                .fill(color(for: status))
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                .shadow(color: color(for: status).opacity(0.4), radius: 3, x: 0, y: 2)
        }
    }
    
    private func color(for status: Status) -> Color {
        switch status {
        case .good:
            return .green
        case .warning:
            return .yellow
        case .error:
            return .red
        }
    }
}

struct ModernPrinterInfoView_Previews: PreviewProvider {
    static var previews: some View {
        PrinterInfoView()
    }
}

