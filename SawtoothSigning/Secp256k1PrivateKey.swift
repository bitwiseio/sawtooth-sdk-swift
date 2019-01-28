//
//  Secp256k1PrivateKey.swift
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

public class Secp256k1PrivateKey: PrivateKey {
    public static var algorithmName = "secp256k1"
    let privKey: [UInt8]

    init(privKey: [UInt8]) {
        self.privKey = privKey
    }

    public static func fromHex(hexPrivKey: String) -> Secp256k1PrivateKey {
        return Secp256k1PrivateKey(privKey: hexPrivKey.toBytes)
    }

    public func hex() -> String {
        return Data(self.privKey).toHex()
    }

    public func getBytes() -> [UInt8] {
        return self.privKey
    }
}
