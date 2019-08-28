//
//  ErrorAlert.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 7/8/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import WatchKit

extension WKInterfaceController {
    
    func showError(_ error: String) {
                
        let action = WKAlertAction(title: "OK", style: WKAlertActionStyle.`default`) { }
        
        self.presentAlert(withTitle: "Error", message: error, preferredStyle: .actionSheet, actions: [action])
    }
}
