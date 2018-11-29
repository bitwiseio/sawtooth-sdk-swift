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
import CommonCrypto
import SawtoothSigning

class XORequestHandler {
    let url: String = "http://localhost:8080"
    var gameName: String
    private var signer: Signer
    private var api: XOApi

    init() {
        self.gameName = ""
        let context = Secp256k1Context()
        let privateKey = context.newRandomPrivateKey()
        self.signer = Signer(context: context, privateKey: privateKey)
        self.api = XOApi(url: url)
    }

    func createGame(game: String, completion: @escaping ((String) -> Void)) {
        self.gameName = game
        let createGameTransaction = makeTransaction(game: game, action: "create", space: "")
        let (batchList, batchID) = makeBatchList(transactions: [createGameTransaction])
        DispatchQueue.main.async {
            self.api.postRequest(batchList: batchList, batchId: batchID, completion: {statusMessage in
                completion(statusMessage)
            })
        }
    }

    func makeTransaction(game: String, action: String, space: String) -> Transaction {
        let transactionAddress = makeAddress(name: game)
        let payloadString = "\(game),\(action),\(space)"
        let payloadData: Data? = payloadString.data(using: .utf8)
        var transactionHeader = TransactionHeader()
        transactionHeader.signerPublicKey = signer.getPublicKey().hex()
        transactionHeader.batcherPublicKey = signer.getPublicKey().hex()
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
            let signature = signer.sign(data: signatureData)
            transaction.headerSignature = signature
        } catch {
            print("Unable to serialize data")
        }
        transaction.payload = payloadData!
        return transaction
    }

    func makeBatchList(transactions: [Transaction]) -> (BatchList, String) {
        var batchHeader = BatchHeader()
        batchHeader.signerPublicKey = signer.getPublicKey().hex()
        batchHeader.transactionIds = transactions.map({ $0.headerSignature })

        var batch = Batch()
        do {
            let batchHeaderData = try batchHeader.serializedData()
            batch.header = batchHeaderData
            let signatureData = batchHeaderData.map {UInt8 (littleEndian: $0)}
            let signature = signer.sign(data: signatureData)
            batch.headerSignature = signature
        } catch {
            print("Unable to serialize data")
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
