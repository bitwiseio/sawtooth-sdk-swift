//
//  ViewController.swift
//  xo_ios
//
//  Created by Darian Plumb on 11/13/18.
//  Copyright © 2018 Bitwise IO. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let XO = XORequestHandler()

        XO.createGame(game: UUID().uuidString)
    }


}

