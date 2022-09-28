//
//  MessagesHostingViewController.swift
//  LockMessage
//
//  Created by Alsey Coleman Miller on 9/28/22.
//

import Foundation
import UIKit
import SwiftUI

final class MessagesHostingViewController: UIHostingController<MessagesHostedView> {
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder, rootView: MessagesHostedView())
    }
}

struct MessagesHostedView: View {
    
    var body: some View {
        NavigationView {
            NavigationLink("Push", destination: { Text("2") })
        }
    }
}
