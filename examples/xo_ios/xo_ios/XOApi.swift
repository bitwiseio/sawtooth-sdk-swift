//
//  XOApi.swift
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

class XOApi {
    let url: String
    init(url: String) {
        self.url = url
    }

    enum BatchStatusEnum: String {
        case invalid = "INVALID"
        case committed = "COMMITTED"
        case pending = "PENDING"
        case unknown = "UNKNOWN"
        case unhandled = "UNHANDLED"
    }

    struct InvalidTransaction {
        var id: String
        var message: String
        var extendedData: String
        init(_ dictionary: [String: Any]) {
            self.id = dictionary["id"] as? String ?? ""
            self.message = dictionary["message"] as? String ?? ""
            self.extendedData = dictionary["extended_data"] as? String ?? ""
        }
    }

    struct BatchStatus {
        var id: String
        var status: BatchStatusEnum
        var invalidTransactions: [InvalidTransaction]
        init(_ dictionary: [String: Any]) {
            self.id = dictionary["id"] as? String ?? ""
            self.status = BatchStatusEnum(
                rawValue: dictionary["status"] as? String ?? "UNHANDLED") ?? BatchStatusEnum.unhandled
            self.invalidTransactions = (
                dictionary["invalid_transactions"] as? [[String: Any]] ?? []).compactMap(InvalidTransaction.init)
        }
    }

    public func postRequest(batchList: BatchList, batchId: String) {
        let postBatch = URL(string: self.url + "/batches")!
        var postUrlRequest = URLRequest(url: postBatch)
        postUrlRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        postUrlRequest.httpMethod = "POST"
        do {
            try postUrlRequest.httpBody = batchList.serializedData()
        } catch {
            print("Unable to serialize batch data")
        }
        URLSession.shared.dataTask(with: postUrlRequest) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            guard data != nil else {
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 202 {
                    print("Transaction Submitted")
                    self.getBatchStatus(batchID: batchId, wait: 10)
                }
            } else {
                return
            }
        }.resume()
    }

    private func getBatchStatus(batchID: String, wait: Int) {
        let batchStatuses = URL(string: self.url + "/batch_statuses?id=\(batchID)&wait=\(wait)")!
        URLSession.shared.dataTask(with: batchStatuses) {(data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            guard let data = data else {
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                        guard let batchStatusResponse = jsonResponse as? [String: Any] else {
                            print("Failed to deserialize batch status response")
                            return
                        }
                        guard let dataArray = batchStatusResponse["data"] as? [[String: Any]] else {
                            print("Failed to fetch batch status data")
                            return
                        }
                        let batchStatus = dataArray.compactMap(BatchStatus.init)[0]
                        self.handleBatchStatus(batchStatus: batchStatus)
                    } catch let parsingError {
                        print("Error", parsingError)
                    }
                }
            } else {
                print("Error parsing batch status response")
                return
            }
        }.resume()
    }

    private func handleBatchStatus(batchStatus: BatchStatus) {
        switch batchStatus.status {
        case BatchStatusEnum.invalid:
            let invalidTransaction = batchStatus.invalidTransactions[0]
            print(invalidTransaction.message)
            print("Invalid Transaction ID: \(invalidTransaction.id)")
        case BatchStatusEnum.committed:
            print("Game Successfully Created!")
        case BatchStatusEnum.pending:
            print("Batch Pending")
        case BatchStatusEnum.unknown:
            print("Batch Status Unknown")
        case BatchStatusEnum.unhandled:
            print("Unhandled status")
        }
    }
}
