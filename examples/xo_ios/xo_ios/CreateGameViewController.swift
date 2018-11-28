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
                NSLog("The \"OK\" alert occurred.")
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
