//
//  Context.swift
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

/// Protocol to be implemented by different signing backends.
public protocol Context {

    /// The algorithm name associated with the type of Context.
    static var algorithmName: String { get }

    /**
        Create a signature by signing the bytes.
     
        - Parameters:
            - data: The bytes being signed.
            - privateKey: Private key of the signer.

        - Returns: Hex encoded signature.
    */
    func sign(data: [UInt8], privateKey: PrivateKey) throws -> String

    /**
        Verify that the private key associated with the public key
        produced the signature by signing the bytes.
     
        - Parameters:
            - signature: The signature being verified.
            - data: The signed data.
            - publicKey: The public key claimed to be associated with the signature.
     
        - Returns: Whether the signer is verified.
    */
    func verify(signature: String, data: [UInt8], publicKey: PublicKey) throws -> Bool

    /**
        Get the public key associated with the private key.
    
        - Parameters:
            - privateKey: Private key associated with the requested public key.
    
        - Returns: Public key associated with the given private key.
     */
    func getPublicKey(privateKey: PrivateKey) throws -> PublicKey

    /**
        Generate a random private key.
     
        - Returns: New private key.
     */
    func newRandomPrivateKey() -> PrivateKey
}
