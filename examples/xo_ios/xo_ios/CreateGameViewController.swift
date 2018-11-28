//
//  CreateGameViewController.swift
//  xo_ios
//
//  Created by Shannyn Telander on 11/23/18.
//  Copyright © 2018 Bitwise IO. All rights reserved.
//

import UIKit

class CreateGameViewController: UIViewController {

    @IBOutlet weak var createGameInputField: UITextField!
    let bottomBorder = CALayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.addTextBorder()
    }

    private func addTextBorder() {
        bottomBorder.frame = CGRect(x: 0.0,
                                    y: createGameInputField.frame.size.height - 2.0,
                                    width: createGameInputField.frame.size.width,
                                    height: 2.0)
        bottomBorder.backgroundColor = UIColor.lightGray.cgColor
        createGameInputField.layer.addSublayer(bottomBorder)
    }
}
