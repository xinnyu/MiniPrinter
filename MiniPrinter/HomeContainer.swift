//
//  HomeContainer.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/15.
//

import SwiftUI
import AlertToast
import JGProgressHUD_SwiftUI
import AlertToast

class Toast: ObservableObject {
    static let shared = Toast()
    private init () {}
        
    @Published var toastText = ""
    @Published var showToast = false
    @Published var toast: AlertToast?
    
    func showToast(title: String) {
        toastText = title
        toast = AlertToast(displayMode: .hud, type: .regular, title: toastText)
        showToast.toggle()
    }
    
    static func show(_ title: String) {
        Toast.shared.showToast(title: title)
    }
    
    func showWarning(title: String) {
        toastText = title
//        toast = AlertToast(displayMode: .hud, type: .regular, title: toastText, style: .style(backgroundColor: .yellow.opacity(0.5)))
        toast = AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.triangle.fill", .yellow), title: toastText)
        showToast.toggle()
    }
    
    static func showWarning(_ title: String) {
        Toast.shared.showWarning(title: title)
    }
    
    func showError(title: String) {
        toastText = title
        toast = AlertToast(displayMode: .hud, type: .error(.red), title: toastText)
//        toast = AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.triangle", .yellow), title: toastText)
        showToast.toggle()
    }
    
    static func showError(_ title: String) {
        Toast.shared.showError(title: title)
    }
    
    func showComplete(title: String) {
        toastText = title
        toast = AlertToast(displayMode: .hud, type: .complete(.green), title: toastText)
//        toast = AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.triangle", .yellow), title: toastText)
        showToast.toggle()
    }
    
    static func showComplete(_ title: String) {
        Toast.shared.showComplete(title: title)
    }
    
}

struct HomeContainer: View {
    @ObservedObject var btManager = BTSearchManager.default
    @ObservedObject var toast = Toast.shared

    @State var showPrinter = false
            
    var body: some View {
        JGProgressHUDPresenter(userInteractionOnHUD: true) {
            NavigationView {
                showPrinter ? AnyView(PrinterView()) : AnyView(BluetoothSearchView())
            }.navigationViewStyle(StackNavigationViewStyle())
        }
        .ignoresSafeArea()
        .onReceive(btManager.$connectionStatus) { value in
            if value == .connected && showPrinter == false {
                showPrinter = true
            }
        }
        .toast(isPresenting: $toast.showToast) {
            toast.toast ?? AlertToast(displayMode: .hud, type: .regular, title: toast.toastText)
        }
    }
    
}

extension JGProgressHUDCoordinator {
    func showLoading(msg: String? = nil) {
        self.presentedHUD?.dismiss(animated: false)
        self.showHUD {
            let hud = JGProgressHUD()
            hud.backgroundColor = UIColor(white: 0, alpha: 0.4)
            hud.shadow = JGProgressHUDShadow(color: .black, offset: .zero, radius: 4, opacity: 0.3)
            hud.vibrancyEnabled = true
            hud.textLabel.text = msg ?? "加载中..."
            return hud
        }
    }
    
    func hideLoading() {
        self.presentedHUD?.dismiss()
    }
    
    func showMsg(_ msg: String, isError: Bool = false) {
        self.presentedHUD?.dismiss(animated: false)
        self.showHUD {
            let hud = JGProgressHUD()
            hud.backgroundColor = UIColor(white: 0, alpha: 0.4)
            hud.indicatorView = isError ? JGProgressHUDErrorIndicatorView() : JGProgressHUDSuccessIndicatorView()
            hud.shadow = JGProgressHUDShadow(color: .black, offset: .zero, radius: 4, opacity: 0.3)
            hud.vibrancyEnabled = true
            hud.textLabel.text = msg
            hud.dismiss(afterDelay: 2)
            return hud
        }
    }
}
