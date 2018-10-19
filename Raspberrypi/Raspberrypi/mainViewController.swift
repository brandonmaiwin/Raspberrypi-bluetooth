//
//  mainViewController.swift
//  Raspberrypi
//
//  Created by Brandon Mai Nguyen on 10/9/18.
//  Copyright © 2018 Brandon Mai Nguyen. All rights reserved.
//

import Foundation
import UIKit
class mainViewController : UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    @IBAction func connectToBluTap(_ sender: Any)
    {
        let navigationViewController = storyboard?.instantiateViewController(withIdentifier: "navigationViewController")as! navigationViewController
        
        present(navigationViewController, animated: true, completion: nil)
        
    }
    
}
