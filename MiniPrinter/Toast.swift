//
//  Toast.swift
//  MiniPrinter
//
//  Created by PAN XINYU on 2023/8/26.
//

import SwiftUI
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
        showToast = true
    }
    
    static func show(_ title: String) {
        Toast.shared.showToast(title: title)
    }
    
    func showWarning(title: String) {
        toastText = title
//        toast = AlertToast(displayMode: .hud, type: .regular, title: toastText, style: .style(backgroundColor: .yellow.opacity(0.5)))
        toast = AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.triangle.fill", .yellow), title: toastText)
        showToast = true
    }
    
    static func showWarning(_ title: String) {
        Toast.shared.showWarning(title: title)
    }
    
    func showError(title: String) {
        toastText = title
        toast = AlertToast(displayMode: .hud, type: .error(.red), title: toastText)
//        toast = AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.triangle", .yellow), title: toastText)
        showToast = true
    }
    
    static func showError(_ title: String) {
        Toast.shared.showError(title: title)
    }
    
    func showComplete(title: String) {
        toastText = title
        toast = AlertToast(displayMode: .hud, type: .complete(.green), title: toastText)
//        toast = AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.triangle", .yellow), title: toastText)
        showToast = true
    }
    
    static func showComplete(_ title: String) {
        Toast.shared.showComplete(title: title)
    }
    
    func showLoading(title: String) {
        toastText = title
        toast = AlertToast(displayMode: .alert, type: .loading, title: toastText)
        showToast = true
    }
    
    static func showLoading(_ title: String) {
        Toast.shared.showLoading(title: title)
    }
    
    static func hideLoading() {
        Toast.shared.showToast = false
    }
    
}
