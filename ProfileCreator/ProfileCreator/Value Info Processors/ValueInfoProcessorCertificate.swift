//
//  ValueInfoProcessorCertificate.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

enum CertificateType: Int {
    case p12
    case selfSignedCA
    case standard
}

class ValueInfoProcessorCertificate: ValueInfoProcessor {

    // MARK: -
    // MARK: Variables

    var certificateType: CertificateType = .standard

    // MARK: -
    // MARK: Intialization

    override init() {
        super.init(withIdentifier: "certificate")
    }

    override func valueInfo(forData data: Data) -> ValueInfo? {
        if let fileUTI = self.fileUTI, NSWorkspace.shared.type(fileUTI as String, conformsToType: kUTTypePKCS12 as String) {
            return self.valueInfoForPKCS12()
        } else {
            return self.valueInfoForPKCS1(data: data)
        }
    }

    func valueInfoForPKCS1(data: Data) -> ValueInfo? {

        // Create an empty ValueInfo struct
        var valueInfo = ValueInfo()

        // Create SecCertificate from passed Data
        let certificate: SecCertificate
        if let cert = SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData) {
            certificate = cert
        } else if
            let certificateString = String(data: data, encoding: .utf8),
            let certData = Certificate.certificateData(forString: certificateString),
            let cert = SecCertificateCreateWithData(kCFAllocatorDefault, certData as CFData) {
            certificate = cert
        } else {
            Log.shared.error(message: "Failed to create a SecCertificate instance from passed data", category: String(describing: self))
            return nil
        }

        // Title
        if let certificateTitle = SecCertificateCopySubjectSummary(certificate) as String? {
            valueInfo.title = certificateTitle
        }

        // Top
        if certificate.isSelfSigned {
            self.certificateType = .selfSignedCA
            valueInfo.topLabel = NSLocalizedString("Root certificate authority", comment: "")
        } else {
            self.certificateType = .standard
            if certificate.isCertificateAuthority {
                valueInfo.topLabel = NSLocalizedString("Intermediate certificate authority", comment: "")
            } else {
                if let issuerName = certificate.issuerName {
                    valueInfo.topLabel = NSLocalizedString("Issued by: \(issuerName)", comment: "")
                } else {
                    valueInfo.topLabel = NSLocalizedString("Unknwon Issuer", comment: "")
                }
            }
        }

        if let validityNotBefore = certificate.validityNotBefore, validityNotBefore.compare(Date()) == ComparisonResult.orderedDescending {

            // Center
            valueInfo.centerLabel = NSLocalizedString("Not valid before: \(DateFormatter.localizedString(from: validityNotBefore, dateStyle: .long, timeStyle: .long))", comment: "")

            // Bottom
            valueInfo.bottomLabel = NSLocalizedString("This certificate is not yet valid", comment: "")
            valueInfo.bottomError = true
        } else if let validityNotAfter = certificate.validityNotAfter {

            if validityNotAfter.compare(Date()) == ComparisonResult.orderedAscending {

                // Center
                valueInfo.centerLabel = NSLocalizedString("Expired: \(DateFormatter.localizedString(from: validityNotAfter, dateStyle: .long, timeStyle: .long))", comment: "")

                // Bottom
                valueInfo.bottomLabel = NSLocalizedString("This certificate has expired", comment: "")
                valueInfo.bottomError = true
            } else {

                // Center
                valueInfo.centerLabel = NSLocalizedString("Expires: \(DateFormatter.localizedString(from: validityNotAfter, dateStyle: .long, timeStyle: .long))", comment: "")
            }
        }

        // Icon
        if let iconURL = self.iconURL(certificateType: self.certificateType) {
            valueInfo.iconPath = iconURL.path
        }

        if let certificateIcon = self.icon(certificateType: self.certificateType) {
            valueInfo.icon = certificateIcon
        } else if let fileUTI = self.fileUTI {
            valueInfo.icon = NSWorkspace.shared.icon(forFileType: fileUTI as String)
        }

        return valueInfo
    }

    func iconURL(certificateType: CertificateType) -> URL? {
        guard let securityInterfaceBundle = Bundle(identifier: "com.apple.securityinterface") ?? Bundle(path: "/System/Library/Frameworks/SecurityInterface.framework") else { return nil }

        switch certificateType {
        case .p12:
            return securityInterfaceBundle.urlForImageResource("CertLargePersonal")
        case .selfSignedCA:
            return securityInterfaceBundle.urlForImageResource("CertLargeRoot")
        case .standard:
            return securityInterfaceBundle.urlForImageResource("CertLargeStd")
        }
    }

    func icon(certificateType: CertificateType) -> NSImage? {
        if let url = self.iconURL(certificateType: certificateType) {
            return NSImage(contentsOf: url)
        }
        return nil
    }

    func valueInfoForPKCS12() -> ValueInfo? {

        var valueInfo = ValueInfo()

        // Title
        valueInfo.title = NSLocalizedString("Personal Information Exchange", comment: "")

        // Message
        valueInfo.message = NSLocalizedString("This content is stored in Personal Information Exchange (PKCS12) format, and is password protected.\nNo information can be displayed.", comment: "")

        // Icon
        if let iconURL = self.iconURL(certificateType: .p12) {
            valueInfo.iconPath = iconURL.path
        }

        if let certificateIcon = self.icon(certificateType: .p12) {
            valueInfo.icon = certificateIcon
        } else if let fileUTI = self.fileUTI {
            valueInfo.icon = NSWorkspace.shared.icon(forFileType: fileUTI as String)
        }

        return valueInfo
    }

    override func valueData(forURL url: URL) -> Data? {
        do {
            return try Data(contentsOfCertificate: url)
        } catch {
            Log.shared.error(message: "Failed to initialize a certificate from file at path: \(url.path)", category: String(describing: self))
            return nil
        }
    }
}
