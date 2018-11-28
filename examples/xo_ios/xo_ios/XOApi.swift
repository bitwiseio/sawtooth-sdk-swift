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
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                        let dataArry = json["data"] as! NSArray
                        let dataDictionary: NSDictionary = dataArry.firstObject! as! NSDictionary
                        self.handleBatchStatus(batchStatusData: dataDictionary)
                    } catch {
                        print("Unable to serialize response data")
                    }
                }
            } else {
                return
            }
        }.resume()
    }
    
    private func handleBatchStatus(batchStatusData: NSDictionary) {
        switch batchStatusData["status"]! as! String {
        case "INVALID":
            let invalidTransactions = batchStatusData["invalid_transactions"] as! NSArray
            let invalidTransactionDictionary = invalidTransactions.firstObject! as! NSDictionary
            print(invalidTransactionDictionary["message"] as! String)
            print("Invalid Transaction ID: \(invalidTransactionDictionary["id"] as! String)")
        case "COMMITTED":
            print("Game Successfully Created!")
        case "PENDING":
            print("Batch Pending")
        case "UNKNOWN":
            print("Batch Status Unknown")
        default:
            print("Unhandled status")
        }
    }
}
