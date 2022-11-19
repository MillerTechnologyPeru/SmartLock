//
//  ProgressIndicatorView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

#if canImport(AppKit)
import SwiftUI
import AppKit

public struct ProgressIndicatorView: View, NSViewRepresentable {
    
    public let style: NSProgressIndicator.Style
    
    public let controlSize: NSControl.ControlSize
    
    public func makeNSView(context: Context) -> NSProgressIndicator {
        let view = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 48, height: 48))
        configure(view)
        view.startAnimation(nil)
        return view
    }
    
    public func updateNSView(_ view: NSProgressIndicator, context: Context) {
        configure(view)
    }
    
    private func configure(_ view: NSProgressIndicator) {
        view.style = self.style
        view.controlSize = self.controlSize
    }
    
    public init(style: NSProgressIndicator.Style, controlSize: NSControl.ControlSize) {
        self.style = style
        self.controlSize = controlSize
    }
}

struct ProgressIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressIndicatorView(style: .bar, controlSize: .regular)
            ProgressIndicatorView(style: .bar, controlSize: .mini)
                .frame(width: 150, height: 32, alignment: .center)
            ProgressIndicatorView(style: .spinning, controlSize: .large)
            ProgressIndicatorView(style: .spinning, controlSize: .regular)
            ProgressIndicatorView(style: .spinning, controlSize: .small)
            ProgressIndicatorView(style: .spinning, controlSize: .mini)
        }
        .padding(20)
    }
}
#endif
