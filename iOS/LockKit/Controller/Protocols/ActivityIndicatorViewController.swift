//
//  ActivityIndicatorViewController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

public protocol ActivityIndicatorViewController: class {
    
    var view: UIView! { get }
    
    var navigationItem: UINavigationItem { get }
    
    var navigationController: UINavigationController? { get }
        
    func showActivity()
    
    func hideActivity(animated: Bool)
}

public extension ActivityIndicatorViewController {
    
    func performActivity <T> (showActivity: Bool = true,
                              queue: DispatchQueue? = nil,
                              _ asyncOperation: @escaping () throws -> T,
                              completion: ((Self, T) -> ())? = nil) {
        
        let queue = queue ?? appQueue
        if showActivity { self.showActivity() }
        queue.async {
            mainQueue { if showActivity { self.showActivity() } }
            do {
                let value = try asyncOperation()
                mainQueue { [weak self] in
                    guard let self = self else { return }
                    if showActivity { self.hideActivity(animated: true) }
                    completion?(self, value)
                }
            }
            catch {
                mainQueue { [weak self] in
                    guard let self = self else { return }
                    if showActivity { self.hideActivity(animated: false) }
                    // show error
                    log("⚠️ Error: \(error)")
                    (self as? UIViewController)?.showErrorAlert(error.localizedDescription)
                }
            }
        }
    }
}

public protocol TableViewActivityIndicatorViewController: ActivityIndicatorViewController {
    
    var tableView: UITableView! { get }
    var refreshControl: UIRefreshControl? { get }
    var activityIndicator: UIActivityIndicatorView { get }
}

public extension TableViewActivityIndicatorViewController {
    
    func showActivity() {
        self.view.isUserInteractionEnabled = false
        if refreshControl?.isRefreshing ?? false {
            // refresh control animating
        } else {
            activityIndicator.startAnimating()
        }
    }
    
    func hideActivity(animated: Bool = true) {
        self.view.isUserInteractionEnabled = true
        if let refreshControl = self.refreshControl,
            refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}

internal extension ActivityIndicatorViewController {
    
    func loadActivityIndicatorView() -> UIActivityIndicatorView {
        
        let activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.frame.origin = CGPoint(x: 6.5, y: 15)
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 33, height: 44))
        view.backgroundColor = .clear
        view.addSubview(activityIndicator)
        
        let barButtonItem = UIBarButtonItem(customView: view)
        self.navigationItem.rightBarButtonItem = barButtonItem
        return activityIndicator
    }
}

#if canImport(JGProgressHUD)
import JGProgressHUD

public protocol ProgressHUDViewController: ActivityIndicatorViewController {
    
    /// Progress HUD
    var progressHUD: JGProgressHUD { get }
}

public extension ProgressHUDViewController {
    
    func showActivity() {
        
        view.isUserInteractionEnabled = false
        view.endEditing(true)
        
        //progressHUD.style = .currentStyle(for: self)
        progressHUD.interactionType = .blockTouchesOnHUDView
        progressHUD.show(in: self.navigationController?.view ?? self.view)
    }
    
    func hideActivity(animated: Bool = true) {
        view.isUserInteractionEnabled = true
        progressHUD.dismiss(animated: animated)
    }
}

#endif
