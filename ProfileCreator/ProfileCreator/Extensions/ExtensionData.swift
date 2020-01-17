//
//  ExtensionData.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

extension Data {

    init?(contentsOfCertificate url: URL) throws {
        do {
            let certificateString = try String(contentsOf: url, encoding: .utf8)
            if let certificateData = Certificate.certificateData(forString: certificateString) {
                self = certificateData
            } else {
                return nil
            }
        } catch {
            try self.init(contentsOf: url)
        }
    }

    func fontTableNameValue(atOffset offset: Int) -> UInt16 {
        return UInt16(bigEndian: subdata(in: offset..<(offset + 8)).withUnsafeBytes { $0.pointee })
    }

    func fontTableString(atOffset offset: Int, length: Int, encoding: String.Encoding) -> String? {
        var stringBytes = [UInt8](repeating: 0, count: length)
        self.copyBytes(to: &stringBytes, from: offset..<(offset + length))
        return String(bytes: stringBytes, encoding: encoding)
    }
}
