//
//  ActivityIndicatorView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

struct ActivityIndicatorView: View, UIViewRepresentable {
    
    let style: UIActivityIndicatorView.Style
    
    public func makeUIView(context: Context) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: style)
        view.startAnimating()
        return view
    }
    
    public func updateUIView(_ view: UIActivityIndicatorView, context: Context) {
        view.style = style
        if view.isAnimating == false {
            view.startAnimating()
        }
    }
}

struct ActivityIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActivityIndicatorView(style: .large)
            ActivityIndicatorView(style: .medium)
        }
    }
}

#endif
