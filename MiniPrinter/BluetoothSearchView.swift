import SwiftUI

struct BluetoothSearchView: View {
    @ObservedObject var manager = BTSearchManager()
    @State private var scaleEffect: CGFloat = 1.0
    let gradient = LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing)
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)  // 背景
            VStack(spacing: 40) {
                // 标题和副标题
                VStack(spacing: 15) {
                    Text("MINI 打印机")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.black)
                    Text("小智&阿奇联合教学")
                        .font(.headline)
                        .foregroundColor(Color.purple)
                }
                // 蓝牙设备列表
                ScrollView {
                    ForEach(manager.discoveredPeripherals, id: \.identifier) { device in
                        HStack {
                            Text(device.name ?? "未知设备")
                            Spacer()
                            Text(String(format: "%.2f m", manager.distanceDict[device.identifier] ?? -1))
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .shadow(color: Color.gray.opacity(0.2), radius: 5)
                        .padding(.horizontal)
                    }
                }
                
                // 搜索按钮
                let disable = manager.isSearching && manager.remainingSeconds > 0
                Button(action: {
                    self.searchForDevices()
                }) {
                    (disable ? Text("搜索中 \(manager.remainingSeconds)秒") : Text("搜索设备"))
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(disable ?
                                AnyView(Color.gray) :
                                AnyView(gradient.cornerRadius(30)))
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .shadow(radius: 10)
                    .scaleEffect(scaleEffect) // 应用缩放效果
                }
                .disabled(disable)
                .onReceive(manager.$remainingSeconds) { _ in
                    if !manager.isSearching || manager.remainingSeconds == 1 {
                        return
                    }
                    // 当remainingSeconds变化时，触发动画
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
    }
    
    func searchForDevices() {
        do {
            try manager.searchForDevices()
        } catch {
            print("Error: \(error)")
        }
    }
}

struct BluetoothSearchView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothSearchView()
    }
}
