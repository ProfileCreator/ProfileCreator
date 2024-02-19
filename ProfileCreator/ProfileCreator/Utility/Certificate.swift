//
//  Certificate.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

class Certificate {

    class func certificateData(forString string: String) -> Data? {
        let certificateScanner = Scanner(string: string)

        // Move to the first line containing '-----BEGIN CERTIFICATE-----'
        _ = certificateScanner.scanUpToString("-----BEGIN CERTIFICATE-----")

        _ = certificateScanner.scanString("-----BEGIN CERTIFICATE-----")

        let certificateScannerString: String? = certificateScanner.scanUpToString("-----END CERTIFICATE-----")

        // If the scannerString is not empty, replace the plistString
        guard let certificateStringBase64 = certificateScannerString, !certificateStringBase64.isEmpty else {
            return nil
        }

        return Data(base64Encoded: certificateStringBase64, options: .ignoreUnknownCharacters)
    }

}
