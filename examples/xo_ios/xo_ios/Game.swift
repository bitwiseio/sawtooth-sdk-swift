//
//  Game.swift
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

import Foundation

class Game {
    // MARK: Properties
    var name: String
    var board: String
    var gameState: GameStateEnum?
    var playerKey1: String
    var playerKey2: String
    // MARK: Initialization
    init(name: String, board: String, gameState: String, playerKey1: String, playerKey2: String) {
        self.name = name
        self.board = board
        self.gameState = GameStateEnum(rawValue: gameState)
        self.playerKey1 = playerKey1
        self.playerKey2 = playerKey2
    }
}

enum GameStateEnum: String {
    case p1Win = "P1-WIN"
    case p2Win = "P2-WIN"
    case tie = "TIE"
    case p1Next = "P1-NEXT"
    case p2Next = "P2-NEXT"
}
