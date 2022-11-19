//
//  SetupLockView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/21/22.
//

import Foundation
import SwiftUI
import CoreLock
import SFSafeSymbols
#if os(iOS)
import CodeScanner
#endif

/// View for lock setup.
public struct SetupLockView: View {
    
    @EnvironmentObject
    public var store: Store
    
    private let success: ((UUID) -> ())?
    
    @State
    private var state: SetupState = .camera
    
    public init(
        success: ((UUID) -> ())? = nil
    ) {
        self.success = success
        self.state = .camera
    }
    
    public init(
        lock: UUID,
        sharedSecret: KeyData,
        success: ((UUID) -> ())? = nil
    ) {
        self.success = success
        self.state = .confirm(lock, sharedSecret)
    }
    
    public var body: some View {
        stateView
            .navigationTitle("Setup")
    }
}

private extension SetupLockView {
    
    #if os(iOS)
    func scanResult(_ result: Result<ScanResult, ScanError>) {
        switch result {
        case let .success(scanResult):
            guard let url = URL(string: scanResult.string),
                  let lockURL = LockURL(rawValue: url),
                  case let .setup(lock, secret) = lockURL
            else { self.state = .error(LockError.invalidQRCode); return }
            self.state = .confirm(lock, secret)
        case let .failure(error):
            self.state = .error(error)
        }
    }
    #endif
    
    func setup(lock: UUID, using sharedSecret: KeyData, name: String) {
        let name = name.isEmpty ? "My Lock" : name
        self.state = .loading(lock, name)
        Task {
            do {
                guard store.state == .poweredOn else {
                    throw LockError.bluetoothUnavailable
                }
                guard let peripheral = try await store.device(for: lock) else {
                    throw LockError.notInRange(lock: lock)
                }
                try await store.setup(
                    for: peripheral,
                    using: sharedSecret,
                    name: name
                )
                self.state = .success(lock, name)
            } catch {
                self.state = .error(error)
            }
        }
    }
    
    func retry() {
        self.state = .camera
    }
    
    var stateView: some View {
        switch state {
        case .camera:
            #if os(iOS) && !targetEnvironment(simulator)
            return AnyView(CameraView(completion: scanResult))
            #else
            return AnyView(Text("Setup this lock on your iOS device."))
            #endif
        case let .confirm(lock, sharedSecret):
            return AnyView(
                ConfirmView(lock: lock) { name in
                    setup(lock: lock, using: sharedSecret, name: name)
                }
            )
        case let .loading(lock, name):
            return AnyView(
                LoadingView(
                    lock: lock,
                    name: name
                )
            )
        case let .error(error):
            return AnyView(
                ErrorView(
                    error: error,
                    retry: retry
                )
            )
        case let .success(lock, name):
            return AnyView(
                SuccessView(
                    lock: lock,
                    name: name,
                    completion: success
                )
            )
        }
    }
}

internal extension SetupLockView {
    
    enum SetupState {
        
        case camera
        case confirm(UUID, KeyData)
        case loading(UUID, String)
        case success(UUID, String)
        case error(Error)
    }
}

internal extension SetupLockView {
    
    #if os(iOS)
    struct CameraView: View {
        
        let completion: ((Result<ScanResult, ScanError>) -> ())
        
        var body: some View {
            AnyView(
                CodeScannerView(codeTypes: [.qr], completion: completion)
            )
        }
    }
    #endif
    
    struct ConfirmView: View {
        
        let lock: UUID
        
        let confirm: (String) -> ()
        
        @State
        private var name: String = ""
        
        var body: some View {
            VStack(alignment: .center, spacing: 16) {
                TextField("Lock Name", text: $name, prompt: Text("My Lock"))
                Button("Configure") {
                    confirm(name)
                }
            }
            .padding(30)
        }
    }
    
    struct LoadingView: View {
        
        let lock: UUID
        
        let name: String
        
        var body: some View {
            VStack(alignment: .center, spacing: 16) {
                Text("Configuring lock...")
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }
    
    struct SuccessView: View {
        
        let lock: UUID
        
        let name: String
        
        let completion: ((UUID) -> ())?
        
        var body: some View {
            VStack(alignment: .center, spacing: 16) {
                Image(systemSymbol: .checkmarkCircleFill)
                    .symbolRenderingMode(.palette)
                    .accentColor(.green)
                Text("Successfully setup \(name).")
                ProgressView()
                    .progressViewStyle(.circular)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if let completion = self.completion {
                        Button("Done") {
                            completion(lock)
                        }
                    }
                }
            }
        }
    }
    
    struct ErrorView: View {
        
        let error: Error
        
        let retry: () -> ()
        
        var body: some View {
            VStack(alignment: .center, spacing: 16) {
                Image(systemSymbol: .exclamationmarkOctagonFill)
                    .symbolRenderingMode(.multicolor)
                Text("Error")
                Text(verbatim: error.localizedDescription)
                Button(action: retry) {
                    Text("Retry")
                }
            }
        }
    }
}

#if DEBUG
struct SetupLockView_Previews: PreviewProvider {
    static var previews: some View {
        SetupLockView()
    }
}
#endif
