//
//  Encoding.swift
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
extension Data {
    public func toHex() -> String {
        return map { String(format: "%02x", UInt8($0)) }.joined()
    }
}

extension UInt8 {
    static func fromHex(hexString: String) -> UInt8 {
        return UInt8(strtoul(hexString, nil, 16))
    }
}

extension StringProtocol {
    var toBytes: [UInt8] {
        let hexa = Array(self)
        return stride(from: 0, to: count, by: 2).compactMap {
            UInt8.fromHex(hexString: String(hexa[$0..<$0.advanced(by: 2)]))
        }
    }
}

public func hash(data: [UInt8]) -> Data {
    var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))

    _ = digest.withUnsafeMutableBytes { (digestBytes) in
        CC_SHA256(data, CC_LONG(data.count), digestBytes)
    }
    return digest
}
