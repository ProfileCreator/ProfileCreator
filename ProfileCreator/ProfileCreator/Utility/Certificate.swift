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

        var certificateScannerString: NSString? = ""

        // Move to the first line containing '-----BEGIN CERTIFICATE-----'
        certificateScanner.scanUpTo("-----BEGIN CERTIFICATE-----", into: nil)

        // Get the string contents between the first '-----BEGIN CERTIFICATE-----' and '-----END CERTIFICATE-----' encountered
        if !( certificateScanner.scanString("-----BEGIN CERTIFICATE-----", into: nil) && certificateScanner.scanUpTo("-----END CERTIFICATE-----", into: &certificateScannerString) ) {
            return nil
        }

        // If the scannerString is not empty, replace the plistString
        guard let certificateStringBase64 = certificateScannerString as String?, !certificateStringBase64.isEmpty else {
            return nil
        }

        return Data(base64Encoded: certificateStringBase64, options: .ignoreUnknownCharacters)
    }

}
