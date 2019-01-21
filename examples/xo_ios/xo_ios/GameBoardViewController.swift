//
//  GameBoardViewController.swift
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

class GameBoardViewController: UIViewController {

    var XOGameHandler: XORequestHandler?
    var game: Game?

    @IBOutlet var gameBoardButtons: [UIButton]?
    @IBOutlet weak var gameNameLabel: UILabel?
    @IBOutlet weak var gameStateLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.gameNameLabel?.text = game?.name
        updateBoard()
    }

    @IBAction func gameBoardRefresh(_ sender: UIBarButtonItem) {
        if #available(iOS 10.0, *) {
            os_log("Refresh Button")
        }
        updateBoard()
    }

    @IBAction func gameBoardInfo(_ sender: UIButton) {
        if #available(iOS 10.0, *) {
            os_log("Info Button")
        }
        let playersString = "Player 1: \(game?.playerKey1 ?? "")\nPlayer 2: \(game?.playerKey2 ?? "")"
        let alert = UIAlertController(title: "Players",
                                      message: playersString,
                                      preferredStyle: .alert)
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

    @IBAction func takeSpaceListener(_ sender: Any) {
        guard let button = sender as? UIButton else {
            return
        }
        let alert = UIAlertController(title: "Transaction Submitted",
                                      message: "Transaction Submitted",
                                      preferredStyle: .alert)
        XOGameHandler?.takeSpace(game: (self.game?.name)!, space: String(button.tag), completion: {status in
            alert.message = status
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK",
                                                                   comment: "Default action"),
                                          style: .default,
                                          handler: {_ in
                                            if #available(iOS 10.0, *) {
                                                os_log("The \"OK\" alert occurred.")
                                            }
                                            self.updateBoard()
            }))
            self.present(alert, animated: true, completion: nil)
            self.updateGame()
        })
    }

    private func updateBoard() {
        updateGame()
        self.gameStateLabel?.text = (game?.gameState)?.rawValue
        let gameBoardStringArray = Array((game?.board)!)
        for button in gameBoardButtons! {
            button.setTitle(String(gameBoardStringArray[button.tag - 1]), for: .normal)
        }
    }

    private func updateGame() {
        XOGameHandler?.getGame(game: (game?.name)!, completion: {response in
        let games = response["data"] as? [[String: Any]] ?? []
        for game in games {
            // swiftlint:disable force_cast
            let base64Encoded = game["data"]! as! String
            let fetchedGame = self.parseGame(data: base64Encoded)
            self.game = fetchedGame
            }
        })

    }

    private func parseGame(data: String) -> Game {
        let decodedData = Data(base64Encoded: data)!
        let split = String(data: decodedData, encoding: .utf8)!.components(separatedBy: ",")
        return Game(name: split[0], board: split[1], gameState: split[2], playerKey1: split[3], playerKey2: split[4])
    }
}
