//
//  CryptoFactory.swift
//  SawtoothSigning
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

public class CryptoFactory {
    /// Private constructor for Factory class.
    init() {}

    static func createContext(algorithmName: String) -> Context {
        if algorithmName == "secp256k1" {
            return Secp256k1Context()
        }
        fatalError(String(format: "Algorithm %@ is not implemented", algorithmName))
    }
}
