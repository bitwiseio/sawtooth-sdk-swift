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
import os

func logMessage(msg: String) {
    if #available(iOS 10.0, *) {
        os_log("%@", msg)
    }
}

class XOApi {

    init() {
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

    public func postRequest(url: String,
                            batchList: BatchList,
                            batchId: String,
                            completion: @escaping ((String) -> Void)) {
        let postBatch = URL(string: url + "/batches")!
        var postUrlRequest = URLRequest(url: postBatch)
        postUrlRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        postUrlRequest.httpMethod = "POST"
        do {
            try postUrlRequest.httpBody = batchList.serializedData()
        } catch {
            logMessage(msg: "Unable to serialize batch data")
        }
        URLSession.shared.dataTask(with: postUrlRequest) { (data, response, error) in
            if error != nil {
                logMessage(msg: error!.localizedDescription)
            }
            guard data != nil else {
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 202 {
                    self.getBatchStatus(url: url, batchID: batchId, wait: 5, completion: {statusMessage in
                        DispatchQueue.main.async {
                            completion(statusMessage)
                        }
                    })
                }
            } else {
                return
            }
        }.resume()
    }

    private func getBatchStatus(url: String,
                                batchID: String,
                                wait: Int,
                                completion: @escaping ((String) -> Void)) {
        let batchStatuses = URL(string: url + "/batch_statuses?id=\(batchID)&wait=\(wait)")!
        URLSession.shared.dataTask(with: batchStatuses) {(data, response, error) in
            if error != nil {
                logMessage(msg: error!.localizedDescription)
            }
            guard let data = data else {
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                        guard let batchStatusResponse = jsonResponse as? [String: Any] else {
                            logMessage(msg: "Failed to deserialize batch status response")
                            return
                        }
                        guard let dataArray = batchStatusResponse["data"] as? [[String: Any]] else {
                            logMessage(msg: "Failed to fetch batch status data")
                            return
                        }
                        let batchStatus = dataArray.compactMap(BatchStatus.init)[0]
                        DispatchQueue.main.async {
                            completion(self.handleBatchStatus(batchStatus: batchStatus))
                        }
                    } catch let parsingError {
                        logMessage(msg: String(format: "Error  %@", parsingError.localizedDescription))
                    }
                }
            } else {
                logMessage(msg: "Error parsing batch status response")
                return
            }
        }.resume()
    }

    private func handleBatchStatus(batchStatus: BatchStatus) -> String {
        switch batchStatus.status {
        case BatchStatusEnum.invalid:
            let invalidTransaction = batchStatus.invalidTransactions[0]
            logMessage(msg: invalidTransaction.message)
            logMessage(msg: String(format: "Invalid Transaction ID: %@", invalidTransaction.id))
            return invalidTransaction.message
        case BatchStatusEnum.committed:
            logMessage(msg: "Batch Successfully Committed!")
            return "Batch Successfully Committed!"
        case BatchStatusEnum.pending:
            logMessage(msg: "Batch Pending")
            return "Batch Pending"
        case BatchStatusEnum.unknown:
            logMessage(msg: "Batch Status Unknown")
            return "Batch Status Unknown"
        case BatchStatusEnum.unhandled:
            logMessage(msg: "Unhandled status")
            return "Unhandled Status"
        }
    }

    public func getState(url: String, address: String, completion: @escaping (([String: Any]) -> Void)) {
        let stateResponse = URL(string: url + "/state?address=\(address)")!
        URLSession.shared.dataTask(with: stateResponse) {(data, response, error) in
            if error != nil {
                logMessage(msg: error!.localizedDescription)
            }
            guard let data = data else {
                 DispatchQueue.main.async {
                    completion([:])
                }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                        DispatchQueue.main.async {
                            completion(self.parseState(response: jsonResponse))
                        }
                    } catch let parsingError {
                        logMessage(msg: String(format: "Error %@", parsingError.localizedDescription))
                    }
                }
            } else {
                logMessage(msg: "Error parsing batch status response")
            }
            }.resume()
    }

    private func parseState(response: Any) -> [String: Any] {
        guard let response = response as? [String: Any] else {
           logMessage(msg: "Unable to deserialize state data")
            return [:]
        }
        return response
    }
}
