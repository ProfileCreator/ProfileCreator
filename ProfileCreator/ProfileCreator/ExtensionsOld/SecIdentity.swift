//
//  SecIdentity.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

extension SecIdentity {
    var certificate: SecCertificate? {
        var certificate: SecCertificate?
        _ = withUnsafeMutablePointer(to: &certificate) {
            SecIdentityCopyCertificate(self, UnsafeMutablePointer($0))
        }
        return certificate
    }

    var certificateName: String? {
        if let certificate = self.certificate {
            return certificate.commonName
        } else { return nil }
    }

    var certificateIconLarge: NSImage? {
        if let certificate = self.certificate {
            return certificate.iconLarge
        } else { return nil }
    }

    var certificateIconSmall: NSImage? {
        if let certificate = self.certificate {
            return certificate.iconSmall
        } else { return nil }
    }

    var isCodeSigningIdentity: Bool {
        guard let certificate = self.certificate else { return false }
        guard let extendedUsageDict = certificate.value(forKey: kSecOIDExtendedKeyUsage) else { return false }
        guard let extendedUsageValue = extendedUsageDict[kSecPropertyKeyValue as String] as? [Data] else { return false }
        return extendedUsageValue.contains(kExtendedUseCodeSigningData)
    }

    var persistentRef: Data? {

        let query = [ kSecClass as String: kSecClassIdentity,
                      kSecValueRef as String: self,
                      kSecMatchLimit as String: kSecMatchLimitOne,
                      kSecReturnPersistentRef as String: kCFBooleanTrue ] as [String: Any]

        var persistentRef: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &persistentRef) != errSecSuccess {
            Log.shared.error(message: "Failed to locate persistent ref for identity: \(self.certificateName ?? "Unknown")", category: String(describing: self))
        }
        if let persistentRefData = persistentRef as? Data {
            return persistentRefData
        } else {
            Log.shared.error(message: "Failed to cast the persistent ref to Data for identity: \(self.certificateName ?? "Unknown")", category: String(describing: self))
            return nil
        }
    }
}
