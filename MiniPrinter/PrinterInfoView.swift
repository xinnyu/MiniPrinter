//
//  PrinterInfoView.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/15.
//

import SwiftUI

struct PrinterInfoView: View {
    
    @ObservedObject var viewModel = PrinterInfoModel(connectionStatus: .error, workingStatus: .error, paperStatus: .error, battery: 0, temperature: 0)

    var body: some View {
        HStack() {
            StatusTextWithIcon(status: viewModel.connectionStatus, text: "连接")
            Spacer()
            StatusTextWithIcon(status: viewModel.workingStatus, text: "工作")
            Spacer()
            StatusTextWithIcon(status: viewModel.paperStatus, text: "纸张")
            Spacer()
            Text("\(viewModel.battery)%")
                .iconBefore(systemName: "battery.100")
            Spacer()
            Text("\(viewModel.temperature)°C")
                .iconBefore(systemName: "thermometer")
        }
        .font(.callout)
        .padding()
    }
}

struct StatusTextWithIcon: View {
    var status: Status
    var text: String

    @State private var blinkingOpacity: Double = 1.0

    var color: Color {
        switch status {
        case .good, .blinking:
            return .green
        case .warning:
            return .yellow
        case .error:
            return .red
        }
    }

    var icon: String {
        switch status {
        case .good:
            return "checkmark.circle.fill"
        case .warning, .blinking:
            return "exclamationmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }

    var body: some View {
        HStack {
            Text(text)
            Image(systemName: icon)
                .foregroundColor(color)
                .opacity(status == .blinking ? blinkingOpacity : 1.0)
        }
        .onChange(of: status) { newStatus in
            if newStatus == .blinking {
                startBlinking()
            } else {
                blinkingOpacity = 1.0
            }
        }
    }
    
    func startBlinking() {
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            blinkingOpacity = 0.2
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

