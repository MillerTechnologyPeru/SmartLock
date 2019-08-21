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
    
    // MARK: - Class Properties
    
    public static let reuseIdentifier = "LockTableViewCell"
    
    public static let nib = UINib(nibName: "LockTableViewCell", bundle: .lockKit)
    
    // MARK: - IB Outlets
    
    @IBOutlet public private(set) weak var lockImageView: UIImageView!
    
    @IBOutlet public private(set) weak var lockTitleLabel: UILabel!
    
    @IBOutlet public private(set) weak var lockDetailLabel: UILabel!
    
    @IBOutlet public private(set) weak var activityIndicatorView: UIActivityIndicatorView!
}
