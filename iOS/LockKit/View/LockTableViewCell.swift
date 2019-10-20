//
//  LockTableViewCell.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 7/1/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

public final class LockTableViewCell: UITableViewCell {
    
    // MARK: - IB Outlets
    
    @IBOutlet public private(set) weak var permissionView: PermissionIconView!
    
    @IBOutlet public private(set) weak var lockTitleLabel: UILabel!
    
    @IBOutlet public private(set) weak var lockDetailLabel: UILabel!
    
    @IBOutlet public private(set) weak var activityIndicatorView: UIActivityIndicatorView!
}

// MARK: - Convenience Extensions

public extension UITableView {
    
    /**
     Registers a nib object containing a cell with the table view under a specified identifier.
     */
    func register(_ type: LockTableViewCell.Type) {
        register(R.nib.lockTableViewCell)
    }
    
    /**
     Returns a typed reusable table-view cell object for the specified reuse identifier and adds it to the table.
     */
    func dequeueReusableCell(_ type: LockTableViewCell.Type, for indexPath: IndexPath) -> LockTableViewCell? {
        return dequeueReusableCell(withIdentifier: R.reuseIdentifier.lockTableViewCell, for: indexPath)
    }
}
