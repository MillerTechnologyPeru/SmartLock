//
//  UIAlertAction.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

public extension UIAlertController {
    
    enum DefaultAction {
        
        case cancel
    }
    
    func addAction(_ action: DefaultAction) {
        
        let alertAction: UIAlertAction
        
        switch action {
            
        case .cancel:
            
            alertAction = UIAlertAction(title: R.string.localizable.alertCancel(), style: .cancel) { [unowned self] _ in
                
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        addAction(alertAction)
    }
}
