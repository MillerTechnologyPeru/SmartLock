//
//  TVContentView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/28/22.
//

#if os(tvOS)
import SwiftUI
import LockKit

struct TVContentView: View {
    
    @EnvironmentObject
    var store: Store
    
    @State
    var state: ViewState = .loading
    
    var body: some View {
        NavigationView {
            content
        }
        .onAppear {
            if state != .fetched || store.applicationData.locks.isEmpty {
                reload()
            }
        }
    }
}

private extension TVContentView {
    
    func reload() {
        state = .loading
        #if targetEnvironment(simulator)
        Task {
            try await Task.sleep(timeInterval: 0.5)
            state = .fetched
        }
        #else
        Task {
            do {
                guard try await store.cloud.accountStatus() == .available else {
                    state = .error("Enable iCloud")
                    return
                }
                try await store.forceDownloadCloudApplicationData()
                state = .fetched
            } catch {
                try await Task.sleep(timeInterval: 0.5)
                state = .error(error.localizedDescription)
            }
        }
        #endif
    }
    
    var content: some View {
        switch state {
        case .loading:
            return AnyView(
                VStack(alignment: .center, spacing: 20) {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            )
        case let .error(error):
            return AnyView(
                VStack(alignment: .center, spacing: 20) {
                    Image(systemSymbol: .exclamationmarkCircleFill)
                        .font(.largeTitle)
                        .symbolRenderingMode(.multicolor)
                        .frame(width: 150, height: 150, alignment: .center)
                    Text("Error")
                        .font(.largeTitle)
                    Text(verbatim: error)
                    Button(action: {
                        Task {
                            try? await Task.sleep(timeInterval: 0.3)
                            reload()
                        }
                    }, label: {
                        Text("Retry")
                    })
                }
            )
        case .fetched:
            return AnyView(
                KeysView()
            )
        }
    }
}

// MARK: - Supporting Types

extension TVContentView {
    
    enum ViewState: Equatable {
        
        case loading
        case error(String)
        case fetched
    }
}

// MARK: - Preview

#if DEBUG
struct TVContentView_Previews: PreviewProvider {
    static var previews: some View {
        TVContentView()
    }
}
#endif
#endif
