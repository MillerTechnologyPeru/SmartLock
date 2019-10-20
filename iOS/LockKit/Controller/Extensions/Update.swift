//
//  Update.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 10/20/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock

public extension ActivityIndicatorViewController where Self: UIViewController {
    
    func update(lock identifier: UUID) {
        
        guard let key = Store.shared.credentials(for: identifier)
            else { assertionFailure(); return }
        
        let alert = UIAlertController(title: R.string.activity.updateActivityAlertTitle(),
                                      message: R.string.activity.updateActivityAlertMessage(),
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: R.string.activity.updateActivityAlertCancel(), style: .cancel, handler: { _ in
            
            alert.dismiss(animated: true) { }
        }))
        
        alert.addAction(UIAlertAction(title: R.string.activity.updateActivityAlertUpdate(), style: .`default`, handler: { [unowned self] _ in
            
            alert.dismiss(animated: true) { }
            
            self.performActivity(queue: .app, {
                
                let client = Store.shared.netServiceClient
                
                guard let netService = try client.discover(duration: 2.0, timeout: 10.0).first(where: { $0.identifier == identifier })
                    else { throw LockError.notInRange(lock: identifier) }
                
                try client.update(for: netService, with: key, timeout: 30.0)
            })
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}
