//
//  CreateGameViewController.swift
//  xo_ios
//
//  Copyright 2018 Bitwise IO, Inc.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import os

class CreateGameViewController: UIViewController {

    @IBOutlet weak var createGameInputField: UITextField!
    let bottomBorder = CALayer()
    var XOGameHandler: XORequestHandler?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.addTextBorder()
    }

    @IBAction func saveNewGame(_ sender: Any) {
        let alert = UIAlertController(title: "Transaction Submitted",
                                      message: "Transaction Submitted",
                                      preferredStyle: .alert)
        if createGameInputField.text! != "" {
            let newGameName = createGameInputField.text!
            XOGameHandler?.createGame(game: newGameName, completion: {status in
                alert.message = status
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK",
                                                                       comment: "Default action"),
                                              style: .default,
                                              handler: { _ in
                    self.performSegue(withIdentifier: "createGameEndSegue", sender: self)
                }))
                self.present(alert, animated: true, completion: nil)
            })
        } else {
            alert.message = "Game name cannot be an empty string!"
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK",
                                                                   comment: "Default action"),
                                          style: .default,
                                          handler: { _ in
                                            if #available(iOS 10.0, *) {
                                                os_log("The \"OK\" alert occurred.")
                                            }
            }))
            self.present(alert, animated: true, completion: nil)
        }
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
