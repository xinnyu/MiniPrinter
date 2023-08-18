//
//  HomeContainer.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/15.
//

import SwiftUI
import AlertToast
import JGProgressHUD_SwiftUI

struct HomeContainer: View {
    @ObservedObject var manager = BTSearchManager.default
    
    @State var showPrinter = true
    
    static let shared = HomeContainer()
    
    private init () {}
            
    var body: some View {
        JGProgressHUDPresenter(userInteractionOnHUD: false) {
            NavigationView {
                showPrinter ? AnyView(PrinterView()) : AnyView(BluetoothSearchView())
            }.navigationViewStyle(StackNavigationViewStyle())
        }.ignoresSafeArea()
            .onReceive(manager.$connectionStatus) { value in
                if value == .connected && showPrinter == false {
                    showPrinter = true
                }
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
            hud.textLabel.text = msg ?? "加载中"
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
