//
//  ValueInfoProcessorCertificate.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads
import SwiftASN1
import X509

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

        do {
            let derBytes: [UInt8] = [UInt8](data)
            let asn1Cert = try X509.Certificate(derEncoded: derBytes)

            if let title = self.valueForNestedAttribute(forDistinguishedName: asn1Cert.subject, forAttribute: .RDNAttributeType.commonName) {

                valueInfo.title = String(describing: title)
            } else {
                valueInfo.title = "Unknown Subject"
            }

            if asn1Cert.issuer == asn1Cert.subject {
                self.certificateType = .selfSignedCA

                // Top
                valueInfo.topLabel = NSLocalizedString("Root certificate authority", comment: "")
            } else {
                self.certificateType = .standard

                // Is Certificate Authority
                let isCertificateAuthority = try asn1Cert.extensions.basicConstraints == .isCertificateAuthority(maxPathLength: 0)

                // Top
                if isCertificateAuthority {
                    valueInfo.topLabel = NSLocalizedString("Intermediate certificate authority", comment: "")
                } else {

                    if let organizationName = self.valueForNestedAttribute(forDistinguishedName: asn1Cert.issuer, forAttribute: .RDNAttributeType.organizationName) {
                        valueInfo.topLabel = NSLocalizedString("Issued by: \(organizationName)", comment: "")
                    } else {
                        valueInfo.topLabel = NSLocalizedString("Unknown Issuer", comment: "")
                    }
                }

                // Not Valid Before
                if asn1Cert.notValidBefore.compare(Date()) == ComparisonResult.orderedDescending {

                    // Center
                    valueInfo.centerLabel = NSLocalizedString("Not valid before: \(DateFormatter.localizedString(from: asn1Cert.notValidBefore, dateStyle: .long, timeStyle: .long))", comment: "")

                    // Bottom
                    valueInfo.bottomLabel = NSLocalizedString("This certificate is not yet valid", comment: "")
                    valueInfo.bottomError = true
                }

                // Not Valid After
                if
                    !valueInfo.bottomError,
                    asn1Cert.notValidAfter.compare(Date()) == ComparisonResult.orderedAscending {

                    // Center
                    valueInfo.centerLabel = NSLocalizedString("Expired: \(DateFormatter.localizedString(from: asn1Cert.notValidAfter, dateStyle: .long, timeStyle: .long))", comment: "")

                    // Bottom
                    valueInfo.bottomLabel = NSLocalizedString("This certificate has expired", comment: "")
                    valueInfo.bottomError = true
                } else {

                    // Center
                    valueInfo.centerLabel = NSLocalizedString("Expires: \(DateFormatter.localizedString(from: asn1Cert.notValidAfter, dateStyle: .long, timeStyle: .long))", comment: "")
                }
            }
        } catch {
            Log.shared.error(message: "Failed to get certificate values with error: \(String(describing: error))", category: String(describing: self))

            return nil
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

    private func valueForNestedAttribute(forDistinguishedName distinguishedName: DistinguishedName, forAttribute attribute: ASN1ObjectIdentifier) -> Any? {

        for relativeDistinguishedName in distinguishedName {
            if let attribute = relativeDistinguishedName.first(where: { $0.type == attribute }) {
                return attribute.value
            }
        }

        return nil
    }
}
