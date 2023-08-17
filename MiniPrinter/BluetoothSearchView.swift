import SwiftUI
import CoreBluetooth
import JGProgressHUD_SwiftUI
import Combine
import PopupView

struct BluetoothSearchView: View {
    @ObservedObject var manager = BTSearchManager.default
    @State private var scaleEffect: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack(spacing: 40) {
                SearchHeaderView()
                DeviceListView(manager: manager)
                SearchButtonView(manager: manager, scaleEffect: $scaleEffect, action: searchForDevices)
            }
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                searchForDevices()
            }
        }
    }
    
    func searchForDevices() {
        do {
            try manager.searchForDevices()
        } catch {
            print("Error: \(error)")
        }
    }
}

struct SearchHeaderView: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("MINI 打印机")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.black)
            Text("小智&阿奇联合教学")
                .font(.headline)
                .foregroundColor(Color.purple)
        }
    }
}

struct DeviceListView: View {
    @ObservedObject var manager: BTSearchManager
    @EnvironmentObject private var hudCoordinator: JGProgressHUDCoordinator
        
    init(manager: BTSearchManager) {
        self.manager = manager
    }
    
    var body: some View {
        ScrollView {
            ForEach(manager.discoveredPeripherals, id: \.identifier) { device in
                Button(action: {
                    self.connectToDevice(device)
                }) {
                    HStack {
                        Text(device.name ?? "未知设备")
                        Spacer()
                        Text(String(format: "%.2f m", manager.distanceDict[device.identifier] ?? -1))
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .shadow(color: Color.gray.opacity(0.2), radius: 5)
                .padding(.horizontal)
            }
        }
        .onReceive(manager.$connectionStatus) { newValue in
            print("xy-log onReceive connectionStatus \(newValue)")
            switch newValue {
            case .connecting:
                hudCoordinator.showLoading(msg: "正在连接")
            case .connected:
                hudCoordinator.hideLoading()
            case .failed:
                hudCoordinator.showMsg("连接失败", isError: true)
            case .timedOut:
                hudCoordinator.showMsg("连接超时", isError: true)
            default:
                hudCoordinator.hideLoading()
            }
        }
    }

    func connectToDevice(_ device: CBPeripheral) {
        do {
            try manager.connectToDevice(device)
        } catch {
            print("Error: \(error)")
        }
    }
}


struct SearchButtonView: View {
    @ObservedObject var manager: BTSearchManager
    @Binding var scaleEffect: CGFloat
    let action: () -> Void
    
    var body: some View {
        let disable = manager.isSearching && manager.remainingSeconds > 0
        return Button(action: action) {
            (disable ? Text("搜索中 \(manager.remainingSeconds)秒") : Text("搜索设备"))
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(disable ?
                            AnyView(Color.gray) :
                            AnyView(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing).cornerRadius(30)))
                .foregroundColor(.white)
                .cornerRadius(30)
                .shadow(radius: 10)
                .scaleEffect(scaleEffect)
        }
        .disabled(disable)
        .onReceive(manager.$remainingSeconds) { _ in
            if !manager.isSearching || manager.remainingSeconds == 1 {
                return
            }
            withAnimation(Animation.easeInOut(duration: 0.5)) {
                scaleEffect = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(Animation.easeInOut(duration: 0.5)) {
                    scaleEffect = 1.0
                }
            }
        }
    }
}

