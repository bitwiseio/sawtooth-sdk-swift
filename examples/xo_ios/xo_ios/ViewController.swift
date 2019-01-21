//
//  ViewController.swift
//  xo_ios
//
//  //  Copyright 2018 Bitwise IO, Inc.
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

class ViewController: UITabBarController {

    // MARK: Properties
    let gameHandler = XORequestHandler()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "XO"
        registerSettings()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.settingsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
        settingsChanged()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "createGameSegue":
            let destViewController = segue.destination as? UINavigationController
            let createGameModal = destViewController?.topViewController as? CreateGameViewController
            createGameModal?.XOGameHandler = self.gameHandler
        case _:
            if #available(iOS 10.0, *) {
                os_log("Unknown segue")
            }
        }
    }

    func registerSettings() {
        let appDefaults = [String: Any]()
        UserDefaults.standard.register(defaults: appDefaults)
    }

    @objc func settingsChanged() {
        if let url = UserDefaults.standard.string(forKey: "restApiUrl") {
            gameHandler.setUrl(url: url)
        } else {
            gameHandler.setUrl(url: "http://localhost:8080")
        }
    }
}
