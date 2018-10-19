//
//  File.swift
//  Raspberrypi
//
//  Created by Brandon Mai Nguyen on 10/9/18.
//  Copyright © 2018 Brandon Mai Nguyen. All rights reserved.
//

import Foundation
import UIKit

class peripheralView: UITableViewCell
{
    @IBOutlet weak var peripheralLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }


}
