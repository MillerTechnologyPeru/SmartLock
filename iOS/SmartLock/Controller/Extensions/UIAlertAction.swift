//
//  UIAlertAction.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController {
    
    enum DefaultAction {
        
        case cancel
    }
    
    func addAction(_ action: DefaultAction) {
        
        let alertAction: UIAlertAction
        
        switch action {
            
        case .cancel:
            
            alertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel) { [unowned self] _ in
                
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        addAction(alertAction)
    }
}