//
//  KeyTableViewCell.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 6/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

final class KeyTableViewCell: UITableViewCell {
    
    // MARK: - Class Properties
    
    static let reuseIdentifier = "KeyTableViewCell"
    
    static let nib = UINib(nibName: "KeyTableViewCell", bundle: nil)
    
    // MARK: - IB Outlets
    
    @IBOutlet weak var lockImageView: UIImageView!
    
    @IBOutlet weak var lockTitleLabel: UILabel!
    
    @IBOutlet weak var lockDetailLabel: UILabel!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
}
