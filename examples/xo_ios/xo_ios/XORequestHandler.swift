//
//  XORequestHandler.swift
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
import os
import CommonCrypto
import SawtoothSigning

class XORequestHandler {
    var url: String = "http://localhost:8080"
    private var signer: Signer
    private var api: XOApi
    var privateKey: PrivateKey

    init() {
        self.privateKey = XORequestHandler.getPrivateKey()
        let context = Secp256k1Context()
        self.signer = Signer(context: context, privateKey: self.privateKey)
        self.api = XOApi()
    }

    func setUrl(url: String) {
        self.url = url
    }

    static func getPrivateKey() -> PrivateKey {
        if let privateKey = UserDefaults.standard.string(forKey: "privateKey") {
            return Secp256k1PrivateKey.fromHex(hexPrivKey: privateKey)
        } else {
            let context = Secp256k1Context()
            let privateKey = context.newRandomPrivateKey()
            UserDefaults.standard.set(privateKey.hex(), forKey: "privateKey" )
            do {
                let pubKey = try context.getPublicKey(privateKey: privateKey)
                UserDefaults.standard.set(pubKey.hex(), forKey: "publicKey" )
            } catch {
                if #available(iOS 10.0, *) {
                    os_log("Error creating public key")
                }
            }
            return privateKey
        }
    }

    func listGames(completion: @escaping (([String: Any]) -> Void)) {
        let xoPrefix = String(hash(item: "xo").prefix(6))
        DispatchQueue.main.async {
            self.api.getState(url: self.url, address: xoPrefix, completion: {response in
                completion(response)
            })
        }
    }

    func getGame(game: String, completion: @escaping (([String: Any]) -> Void)) {
        let gameAddress = makeAddress(name: game)
        DispatchQueue.main.async {
            self.api.getState(url: self.url, address: gameAddress, completion: {response in
                completion(response)
            })
        }
    }

    func createGame(game: String, completion: @escaping ((String) -> Void)) {
        let createGameTransaction = makeTransaction(game: game, action: "create", space: "")
        let (batchList, batchID) = makeBatchList(transactions: [createGameTransaction])
        DispatchQueue.main.async {
            self.api.postRequest(url: self.url, batchList: batchList, batchId: batchID, completion: {statusMessage in
                completion(statusMessage)
            })
        }
    }

    func takeSpace(game: String, space: String, completion: @escaping ((String) -> Void)) {
        let takeSpaceTransaction = makeTransaction(game: game, action: "take", space: space)
        let (batchList, batchID) = makeBatchList(transactions: [takeSpaceTransaction])
        DispatchQueue.main.async {
            self.api.postRequest(url: self.url, batchList: batchList, batchId: batchID, completion: {statusMessage in
                completion(statusMessage)
            })
        }
    }

    func makeTransaction(game: String, action: String, space: String) -> Transaction {
        let transactionAddress = makeAddress(name: game)
        let payloadString = "\(game),\(action),\(space)"
        let payloadData: Data? = payloadString.data(using: .utf8)
        var transactionHeader = TransactionHeader()
        do {
            transactionHeader.signerPublicKey = try signer.getPublicKey().hex()
            transactionHeader.batcherPublicKey = try signer.getPublicKey().hex()
        } catch {
            if #available(iOS 10.0, *) {
                os_log("Failed to get signer public key")
            }
        }
        transactionHeader.familyName = "xo"
        transactionHeader.familyVersion = "1.0"
        transactionHeader.inputs = [transactionAddress]
        transactionHeader.outputs = [transactionAddress]
        transactionHeader.payloadSha512 = hash(item: payloadString)
        transactionHeader.nonce = UUID().uuidString

        var transaction = Transaction()
        do {
            let transactionHeaderData = try transactionHeader.serializedData()
            transaction.header = transactionHeaderData
            let signatureData = transactionHeaderData.map {UInt8 (littleEndian: $0)}
            do {
                let signature = try signer.sign(data: signatureData)
                transaction.headerSignature = signature
            } catch {
                if #available(iOS 10.0, *) {
                    os_log("Unexpected error signing batch ")
                }
            }
        } catch {
            if #available(iOS 10.0, *) {
                os_log("Unable to serialize data")
            }
        }
        transaction.payload = payloadData!
        return transaction
    }

    func makeBatchList(transactions: [Transaction]) -> (BatchList, String) {
        var batchHeader = BatchHeader()
        do {
            batchHeader.signerPublicKey = try signer.getPublicKey().hex()
        } catch {
            if #available(iOS 10.0, *) {
                os_log("Failed to get signer public key")
            }
        }

        batchHeader.transactionIds = transactions.map({ $0.headerSignature })

        var batch = Batch()
        do {
            let batchHeaderData = try batchHeader.serializedData()
            batch.header = batchHeaderData
            let signatureData = batchHeaderData.map {UInt8 (littleEndian: $0)}
            do {
                let signature = try signer.sign(data: signatureData)
                batch.headerSignature = signature
            } catch {
                if #available(iOS 10.0, *) {
                    os_log("Unexpected error signing batch")
                }
            }
        } catch {
            if #available(iOS 10.0, *) {
                os_log("Unable to serialize data")
            }
        }
        batch.transactions = transactions
        var batchList = BatchList()
        batchList.batches = [batch]
        return (batchList, batch.headerSignature)
    }

    private func makeAddress(name: String) -> String {
        let xoPrefix = hash(item: "xo").prefix(6)
        let game = hash(item: name).prefix(64)
        return "\(xoPrefix)\(game)"
    }

    private func hash(item: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        if let data = item.data(using: String.Encoding.utf8) {
            let value = data as NSData
            CC_SHA512(value.bytes, CC_LONG(data.count), &digest)
        }
        let digestHex = digest.map { String(format: "%02hhx", $0) }.joined()
        return digestHex
    }
}
