//
//  ViewController.swift
//  xo_ios
//
//  Created by Darian Plumb on 11/13/18.
//  Copyright © 2018 Bitwise IO. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let gameHandler = XORequestHandler()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        registerSettings()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createGameModal = segue.destination as? CreateGameViewController {
            createGameModal.XOGameHandler = self.gameHandler
        }
    }

    func registerSettings() {
        let appDefaults = [String: Any]()
        UserDefaults.standard.register(defaults: appDefaults)
    }
}
