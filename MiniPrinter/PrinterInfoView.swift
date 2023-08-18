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

enum Status {
    case good, warning, error
}

class PrinterInfoViewModel: ObservableObject {
    @Published var printerInfo: PrinterInfoModel = PrinterInfoModel(connectionStatus: true, workingStatus: true, paperStatus: false, battery: 80, temperature: 42)
}

struct PrinterInfoView: View {
    @StateObject var viewModel = PrinterInfoViewModel()

    var body: some View {
        HStack() {
            StatusTextWithIcon(icon: viewModel.printerInfo.connectionStatus.status.icon, text: "连接", color: viewModel.printerInfo.connectionStatus.status.color)
            Spacer()
            StatusTextWithIcon(icon: viewModel.printerInfo.workingStatus.status.icon, text: "工作", color: viewModel.printerInfo.workingStatus.status.color)
            Spacer()
            StatusTextWithIcon(icon: viewModel.printerInfo.paperStatus.status.icon, text: "纸张", color: viewModel.printerInfo.paperStatus.status.color)
            Spacer()
            Text("\(viewModel.printerInfo.battery)%")
                .iconBefore(systemName: "battery.100")
            Spacer()
            Text("\(viewModel.printerInfo.temperature)°C")
                .iconBefore(systemName: "thermometer")
        }
        .font(.callout)
        .padding()
    }
}

extension Status {
    var icon: String {
        switch self {
        case .good:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .good:
            return .green
        case .warning:
            return .yellow
        case .error:
            return .red
        }
    }
}

struct StatusTextWithIcon: View {
    var icon: String
    var text: String
    var color: Color

    var body: some View {
        HStack {
            Text(text)
            Image(systemName: icon)
                .foregroundColor(color)
        }
    }
}

extension Text {
    func iconBefore(systemName: String) -> some View {
        HStack {
            Image(systemName: systemName)
            self
        }
    }
}

