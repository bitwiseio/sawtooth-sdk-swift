//
//  Signer.swift
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

/// Convenience class that wraps the PrivateKey and Context
public class Signer {
    var context: Context
    var privateKey: PrivateKey

    public init(context: Context, privateKey: PrivateKey) {
        self.context = context
        self.privateKey = privateKey
    }

    /**
        Produce a hex encoded signature from the data and the private key.

         - Parameters:
            - data: The bytes being signed.

         - Returns: Hex encoded signature.
    */
    public func sign(data: [UInt8]) throws -> String {
        return try self.context.sign(data: data, privateKey: self.privateKey)
    }

    /**
        Get the public key associated with the private key.

        - Returns: Public key associated with the signer's private key.
     */
    public func getPublicKey() throws -> PublicKey {
        return try self.context.getPublicKey(privateKey: self.privateKey)
    }
}
