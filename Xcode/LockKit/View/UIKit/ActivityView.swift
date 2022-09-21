//
//  ActivityView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/20/22.
//

#if os(iOS)
import SwiftUI
import UIKit

public struct ActivityView: UIViewControllerRepresentable {
    
    public let activityItems: [Any]
    
    public let applicationActivities: [UIActivity]?
    
    public let excludedActivityTypes: [UIActivity.ActivityType]?
    
    public init(
        activityItems: [Any],
        applicationActivities: [UIActivity]? = nil,
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }
    
    public func updateUIViewController(_ viewController: UIActivityViewController, context: Context) {
        
        
    }
}

// MARK: - Supporting Types

public struct ShareSheetContextMenuModifer: ViewModifier {
    
    @State
    private var showShareSheet: Bool = false
    
    public let activityItems: [Any]
    
    public let applicationActivities: [UIActivity]?
    
    public let excludedActivityTypes: [UIActivity.ActivityType]?
    
    public init(
        activityItems: [Any],
        applicationActivities: [UIActivity]? = nil,
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    public func body(content: Content) -> some View {
        content
            .contextMenu {
                Button(action: {
                    self.showShareSheet.toggle()
                }) {
                    Text("Share")
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .sheet(isPresented: $showShareSheet, content: {
                ActivityView(
                    activityItems: activityItems,
                    applicationActivities: applicationActivities,
                    excludedActivityTypes: excludedActivityTypes
                )
            })
    }
}

public extension View {
    
    func shareSheetContextMenu(
        activityItems: [Any],
        applicationActivities: [UIActivity]? = nil,
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) -> some View {
        self.modifier(
            ShareSheetContextMenuModifer(
                activityItems: activityItems,
                applicationActivities: applicationActivities,
                excludedActivityTypes: excludedActivityTypes
            )
        )
    }
}

// MARK: - Preview

struct ActivityView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            PreviewView(
                activityItems: [URL(string: "http://google.com")! as NSURL]
            )
        }
    }
    
    struct PreviewView: View {
        
        let activityItems: [Any]
        
        let applicationActivities: [UIActivity]? = nil
        
        let excludedActivityTypes: [UIActivity.ActivityType]? = nil
        
        @State
        var showShareSheet = false
        
        var body: some View {
            NavigationView {
                Button("Share") {
                    showShareSheet = true
                }
                .padding(20)
                .navigationTitle("Share Sheet")
                .shareSheetContextMenu(
                    activityItems: activityItems,
                    applicationActivities: applicationActivities,
                    excludedActivityTypes: excludedActivityTypes
                )
                .sheet(isPresented: $showShareSheet, content: {
                    ActivityView(
                        activityItems: activityItems,
                        applicationActivities: applicationActivities,
                        excludedActivityTypes: excludedActivityTypes
                    )
                })
            }
        }
    }
}
#endif
