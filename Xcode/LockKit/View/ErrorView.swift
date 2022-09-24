//
//  ErrorView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/24/22.
//

import SwiftUI

public extension View {
    
    func alert(error: Binding<Error?>) -> some View {
        return alert(
            isPresented: Binding<Bool>(
                get: { error.wrappedValue != nil },
                set: {
                    if $0 == false {
                        error.wrappedValue = nil
                    }
                }
            ),
            content: {
                Alert(
                    title: Text("Error"),
                    message: Text(verbatim: error.wrappedValue?.localizedDescription ?? "Unknown error"),
                    dismissButton: .cancel(Text("Ok"), action: {
                        error.wrappedValue = nil
                    })
                )
            }
        )
    }
}

#if DEBUG
struct ErrorView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            PreviewView()
        }
    }
    
    struct PreviewView: View {
        
        @State
        private var error: Error?
        
        var body: some View {
            Button("Show Error") {
                error = LockError.notInRange(lock: UUID())
            }
            .alert(error: $error)
        }
    }
}
#endif
