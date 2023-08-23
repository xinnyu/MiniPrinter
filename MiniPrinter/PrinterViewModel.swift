//
//  PrinterViewModel.swift
//  MiniPrinter
//
//  Created by 潘新宇 on 2023/8/15.
//

import SwiftUI
import Combine

class PrinterViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var uiImage: UIImage? {
        didSet {
            toolBarViewModel.uiImage = uiImage
            printImage = nil
        }
    }
    @Published var showLoading: Bool = false
    @Published var orImage: UIImage?
    @Published var printImage: UIImage?
    @Published var infoModel = PrinterInfoModel(connectionStatus: .error, workingStatus: .error, paperStatus: .error, battery: 0, temperature: 0)
    lazy var toolBarViewModel = makeToolBarViewModel()

    // MARK: - Private Properties
    private var manager = BTSearchManager.default
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        setupBluetoothDataBinding()
    }
    
    // MARK: - Private Methods
    private func makeToolBarViewModel() -> PrintToolBarViewModel {
        let viewModel = PrintToolBarViewModel()
        viewModel.imagePreviewCallback = { [weak self] image in
            self?.uiImage = image
            self?.printImage = image
        }
        viewModel.imagePrintCallback = { [weak self] image in
            self?.showLoading = true
            self?.uiImage = image
            self?.processAndSendImageForPrinting(image)
        }
        return viewModel
    }
    
    private func setupBluetoothDataBinding() {
        manager.dataSubject
            .compactMap { $0 }
            .compactMap { try? PrinterInfoModel(data: $0) }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] newModel in
                self?.infoModel = newModel
            })
            .store(in: &cancellables)
    }

    private func processAndSendImageForPrinting(_ image: UIImage?) {
        if let image = image {
            DispatchQueue.global().async {
                if let datas = ImageHelper.convertImageToBinaryRows(image: image) {
                    self.sendDatas(datas)
                }
                DispatchQueue.main.async {
                    self.showLoading = false
                }
            }
        }
    }
}

// MARK: - Bluetooth Handling
extension PrinterViewModel {
    private func sendDatas(_ datas: [Data]) {
        let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        var delayTime = DispatchTime.now()
        for data in datas {
            dispatchQueue.asyncAfter(deadline: delayTime) {
                BTSearchManager.default.sendData(data: data)
            }
            delayTime = delayTime.advanced(by: .milliseconds(10))
        }
    }
}

