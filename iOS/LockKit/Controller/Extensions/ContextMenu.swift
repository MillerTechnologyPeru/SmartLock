//
//  ContextMenu.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import IntentsUI
import SFSafeSymbols

@available(iOSApplicationExtension 13.0, *)
public extension UIViewController {
    
    func menu(forLock lock: UUID) -> UIMenu {
        
        guard let cache = Store.shared[lock: lock] else {
            assertionFailure()
            return UIMenu(
                title: "",
                image: nil,
                identifier: nil,
                options: [],
                children: []
            )
        }
                
        var actions = [UIAction]()
        
        if cache.key.permission.isAdministrator {
            
            let share = UIAction(title: R.string.contextMenu.itemShareKey(), image: UIImage(systemSymbol: .squareAndArrowUp)) { [weak self] (action) in
                let viewController = NewKeySelectPermissionViewController.fromStoryboard(with: lock)
                viewController.completion = {
                    guard let (invitation, sender) = $0 else {
                        return
                    }
                    // show share sheet
                    viewController.share(invitation: invitation, sender: sender) { }
                }
                let navigationController = UINavigationController(rootViewController: viewController)
                self?.present(navigationController, animated: true, completion: nil)
            }
            
            actions.append(share)
            
            let manageKeys = UIAction(title: R.string.contextMenu.itemManage(), image: UIImage(systemSymbol: .listBullet)) { [weak self] (action) in
                let viewController = LockPermissionsViewController.fromStoryboard(
                    with: lock,
                    completion: { self?.dismiss(animated: true, completion: nil) }
                )
                let navigationController = UINavigationController(rootViewController: viewController)
                self?.present(navigationController, animated: true, completion: nil)
            }
            
            actions.append(manageKeys)
        }
        
        #if canImport(IntentsUI) && !targetEnvironment(macCatalyst)
        if let delegate = self as? INUIAddVoiceShortcutViewControllerDelegate {
            
            let siri = UIAction(title: R.string.contextMenu.itemSiriShortcut(), image: UIImage(systemSymbol: .micFill)) { [weak self] (action) in
                let siriViewController = INUIAddVoiceShortcutViewController(
                    unlock: lock,
                    cache: cache,
                    delegate: delegate
                )
                self?.present(siriViewController, animated: true, completion: nil)
            }
            
            actions.append(siri)
        }
        #endif
        
        let rename = UIAction(title: R.string.contextMenu.itemRename(), image: UIImage(systemSymbol: .squareAndPencil)) { [weak self] (action) in
            let alert = RenameActivity.viewController(for: lock) { _ in }
            self?.present(alert, animated: true, completion: nil)
        }
        
        actions.append(rename)
        
        if cache.key.permission.isAdministrator,
            let viewController = self as? (UIViewController & ActivityIndicatorViewController) {
            
            let update = UIAction(title: R.string.activity.updateActivityTitle(), image: UIImage(systemSymbol: .squareAndArrowDown)) { (action) in
                viewController.update(lock: lock)
            }
            
            actions.append(update)
        }
        
        let delete = UIAction(title: R.string.contextMenu.itemDelete(), image: UIImage(systemSymbol: .trash), attributes: .destructive) { [weak self] (action) in
            let alert = DeleteLockActivity.viewController(for: lock) { _ in }
            self?.present(alert, animated: true, completion: nil)
        }
        
        actions.append(delete)
        
        return UIMenu(
            title: "",
            image: nil,
            identifier: nil,
            options: [],
            children: actions
        )
    }
}
