//
//  ViewController.swift
//  LockMessage
//
//  Created by Alsey Coleman Miller on 9/27/22.
//

import Foundation
import UIKit

extension UIViewController {
    
    func loadChildViewController(_ viewController: UIViewController) {
        
        assert(Thread.isMainThread)
        
        // remove previous
        for childViewController in children {
            childViewController.viewIfLoaded?.removeFromSuperview()
            childViewController.removeFromParent()
        }
        
        viewController.loadViewIfNeeded()
        viewController.view.layoutIfNeeded()
        
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        
        guard let childView = viewController.view else {
            assertionFailure()
            return
        }
        
        childView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.leftAnchor.constraint(equalTo: view.leftAnchor),
            childView.rightAnchor.constraint(equalTo: view.rightAnchor),
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
