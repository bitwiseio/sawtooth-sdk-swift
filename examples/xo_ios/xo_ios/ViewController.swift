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

class ViewController: UITableViewController {

    // MARK: Properties
    var games = [Game]()
    let gameHandler = XORequestHandler()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        registerSettings()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.settingsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
        settingsChanged()
        loadGames()
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

    @objc func settingsChanged() {
        if let url = UserDefaults.standard.string(forKey: "restApiUrl") {
            gameHandler.setUrl(url: url)
        } else {
            gameHandler.setUrl(url: "http://localhost:8080")
        }
    }

    private func loadGames() {
        var games: [[String: Any]] = []
        var gameList: [Game] = []
        self.games.append(Game(name: "String",
                               board: "String",
                               gameState: "P1-NEXT",
                               playerKey1: "String",
                               playerKey2: "String"))
        gameHandler.listGames(completion: {response in
            games = response["data"] as? [[String: Any]] ?? []
            for game in games {
                // swiftlint:disable force_cast
                let base64Encoded = game["data"]! as! String
                gameList.append(self.parseGames(data: base64Encoded))
            }
            self.games = gameList
            self.games.sort(by: { (game1, game2) -> Bool in
                game1.name < game2.name
            })
            self.tableView.reloadData()
        })
    }

    private func parseGames(data: String) -> Game {
        let decodedData = Data(base64Encoded: data)!
        let split = String(data: decodedData, encoding: .utf8)!.components(separatedBy: ",")
        return Game(name: split[0], board: split[1], gameState: split[2], playerKey1: split[3], playerKey2: split[4])
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "GameTableViewCell"
        guard let cell =
            tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? GameTableViewCell  else {
                fatalError("The dequeued cell is not an instance of GameTableViewCell.")
        }

        let game = games[indexPath.row]
        cell.gameNameLabel.text = game.name
        cell.gameStateLabel.text = game.gameState?.rawValue
        return cell
    }
}
