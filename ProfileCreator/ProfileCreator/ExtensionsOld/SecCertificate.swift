//
//  SecCertificate.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

let kExtendedUseCodeSigning: [UInt8] = [0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x03]
let kExtendedUseCodeSigningData = Data(bytes: kExtendedUseCodeSigning, count: kExtendedUseCodeSigning.count)

extension SecCertificate {
    func value(forKey key: CFString) -> [String: Any]? {
        if let values = self.values(forKeys: [key]) {
            return values[key as String] as? [String: Any]
        } else { return nil }
    }

    func values(forKeys keys: [CFString]?) -> [String: Any]? {
        SecCertificateCopyValues(self, keys as CFArray?, nil) as? [String: Any]
    }

    var commonName: String? {
        var commonName: CFString?
        _ = SecCertificateCopyCommonName(self, &commonName)
        return commonName as String?
    }

    var isValid: Bool {
        let oids: [CFString] = [kSecOIDX509V1ValidityNotAfter, kSecOIDX509V1ValidityNotBefore]
        let certificateValueDict = SecCertificateCopyValues(self, oids as CFArray, nil) as? [String: [String: Any]]
        return relativeTime(forOID: kSecOIDX509V1ValidityNotAfter, values: certificateValueDict) >= 0.0
            && relativeTime(forOID: kSecOIDX509V1ValidityNotBefore, values: certificateValueDict) <= 0.0
    }

    var validityNotBefore: Date? {
        if
            let notValidBeforeDict = self.value(forKey: kSecOIDX509V1ValidityNotBefore),
            let notValidBefore = notValidBeforeDict[kSecPropertyKeyValue as String] as? Double,
            let notValidBeforeDate = CFDateCreate(kCFAllocatorDefault, notValidBefore) as Date? {
            return notValidBeforeDate
        } else {
            return nil
        }
    }

    var validityNotAfter: Date? {
        if
            let notValidBeforeDict = self.value(forKey: kSecOIDX509V1ValidityNotAfter),
            let notValidBefore = notValidBeforeDict[kSecPropertyKeyValue as String] as? Double,
            let notValidBeforeDate = CFDateCreate(kCFAllocatorDefault, notValidBefore) as Date? {
            return notValidBeforeDate
        } else {
            return nil
        }
    }

    var iconLarge: NSImage? {
        guard let securityInterfaceBundle = Bundle(identifier: "com.apple.securityinterface") ?? Bundle(path: "/System/Library/Frameworks/SecurityInterface.framework") else { return nil }

        var certificateIconURL: URL?

        if self.isValid {
            if self.isSelfSigned {
                certificateIconURL = securityInterfaceBundle.urlForImageResource("CertLargeRoot")
            } else {
                certificateIconURL = securityInterfaceBundle.urlForImageResource("CertLargeStd")
            }
        } else {
            if self.isSelfSigned {
                certificateIconURL = securityInterfaceBundle.urlForImageResource("CertSmallRoot_Invalid")
            } else {
                certificateIconURL = securityInterfaceBundle.urlForImageResource("CertSmallStd_Invalid")
            }
        }

        if let url = certificateIconURL {
            return NSImage(contentsOf: url)
        } else { return nil }
    }

    var iconSmall: NSImage? {
        guard let securityInterfaceBundle = Bundle(identifier: "com.apple.securityinterface") ?? Bundle(path: "/System/Library/Frameworks/SecurityInterface.framework") else { return nil }

        var certificateIconURL: URL?

        if self.isValid {
            if self.isSelfSigned {
                certificateIconURL = securityInterfaceBundle.urlForImageResource("CertSmallRoot")
            } else {
                certificateIconURL = securityInterfaceBundle.urlForImageResource("CertSmallStd")
            }
        } else {
            if self.isSelfSigned {
                certificateIconURL = securityInterfaceBundle.urlForImageResource("CertSmallRoot_Invalid")
            } else {
                certificateIconURL = securityInterfaceBundle.urlForImageResource("CertSmallStd_Invalid")
            }
        }

        if let url = certificateIconURL {
            return NSImage(contentsOf: url)
        } else { return nil }
    }

    var issuerName: String? {
        if
            let issuersDict = self.value(forKey: kSecOIDX509V1IssuerName),
            let issuers = issuersDict[kSecPropertyKeyValue as String] as? [[String: Any]],
            let issuer = issuers.first {
            return issuer[kSecPropertyKeyValue as String] as? String
        }
        return nil
    }

    var isSelfSigned: Bool {
        if #available(OSX 10.12.4, *) {
            return SecCertificateCopyNormalizedIssuerSequence(self) == SecCertificateCopyNormalizedSubjectSequence(self)
        } else {
            var errorRef: Unmanaged<CFError>?
            let issuerData = SecCertificateCopyNormalizedIssuerContent(self, &errorRef)
            let issuerDataError = errorRef?.takeRetainedValue()

            if issuerData == nil {
                Log.shared.error(message: "Failed to get issuer data with error: \(String(describing: issuerDataError))", category: String(describing: self))
            }

            let subjectData = SecCertificateCopyNormalizedSubjectContent(self, &errorRef)
            let subjectDataError = errorRef?.takeRetainedValue()

            if subjectData == nil {
                Log.shared.error(message: "Failed to get subject data with error: \(String(describing: subjectDataError))", category: String(describing: self))
            }

            return issuerData == subjectData
        }
    }

    var isCertificateAuthority: Bool {
        var isCertificateAuthority: Bool = false
        if
            let basicConstraintsDict = self.value(forKey: kSecOIDBasicConstraints),
            let basicConstraints = basicConstraintsDict[kSecPropertyKeyValue as String] as? [[String: Any]] {
            isCertificateAuthority = basicConstraints.contains {
                if
                    let label = $0[kSecPropertyKeyLabel as String] as? String, label == "Certificate Authority",
                    let value = $0[kSecPropertyKeyValue as String] as? NSString {
                    return value.boolValue
                } else {
                    return false
                }
            }
        }
        return isCertificateAuthority
    }

    func relativeTime(forOID oid: CFString, values: [String: [String: Any]]?) -> Double {
        guard let dateNumber = values?[oid as String]?[kSecPropertyKeyValue as String] as? NSNumber else { return 0.0 }
        return dateNumber.doubleValue - CFAbsoluteTimeGetCurrent()
    }
}
