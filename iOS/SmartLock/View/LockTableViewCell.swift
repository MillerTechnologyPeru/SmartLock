//
//  LockTableViewCell.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 7/1/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

final class LockTableViewCell: UITableViewCell {
    
    // MARK: - Class Properties
    
    static let reuseIdentifier = "LockTableViewCell"
    
    static let nib = UINib(nibName: "LockTableViewCell", bundle: nil)
    
    // MARK: - IB Outlets
    
    @IBOutlet weak var lockImageView: UIImageView!
    
    @IBOutlet weak var lockTitleLabel: UILabel!
    
    @IBOutlet weak var lockDetailLabel: UILabel!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
}
