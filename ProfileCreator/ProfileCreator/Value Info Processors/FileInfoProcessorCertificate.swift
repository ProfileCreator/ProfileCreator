//
//  FileInfoProcessorCertificate.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

enum CertificateFormat {
    case pkcs1
    case pkcs12
}

struct CertificateFileInfoKey {
    static let type = "CertificateType"
}

class FileInfoProcessorCertificate: FileInfoProcessor {

    // MARK: -
    // MARK: Variables

    var certificateType: CertificateType = .standard

    override init(fileURL url: URL) {
        super.init(fileURL: url)
    }

    override init?(data: Data, fileInfo: [String: Any]) {

        // Certificate Type
        if
            let certificateTypeInt = fileInfo[CertificateFileInfoKey.type] as? Int,
            let certificateTyoe = CertificateType(rawValue: certificateTypeInt) {
            self.certificateType = certificateTyoe
        }

        super.init(data: data, fileInfo: fileInfo)
    }

    // MARK: -
    // MARK: Functions

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

    // MARK: -
    // MARK: FileInfoProcessor Functions

    override func fileInfoDict() -> [String: Any] {
        var fileInfoDict = super.fileInfoDict()

        // Certificate Type
        fileInfoDict[CertificateFileInfoKey.type] = self.certificateType.rawValue

        return fileInfoDict
    }

    override func fileData() -> Data? {
        if let fileURL = self.fileURL {

            // Try reading the file contents as a string
            do {
                let certificateString = try String(contentsOf: fileURL, encoding: .utf8)
                let certificateScanner = Scanner(string: certificateString)

                // Move to the first line containing '-----BEGIN CERTIFICATE-----'
                // certificateScanner.scanUpTo("-----BEGIN CERTIFICATE-----", into: nil)
                _ = certificateScanner.scanUpToString("-----BEGIN CERTIFICATE-----")

                // Get the string contents between the first '-----BEGIN CERTIFICATE-----' and '-----END CERTIFICATE-----' encountered
                _ = certificateScanner.scanString("-----BEGIN CERTIFICATE-----")

                let certificateScannerString = certificateScanner.scanUpToString("-----END CERTIFICATE-----")

                // If the scannerString is not empty, replace the plistString
                if let certificateStringBase64 = certificateScannerString, !certificateStringBase64.isEmpty {
                    return Data(base64Encoded: certificateStringBase64, options: .ignoreUnknownCharacters)
                }
            } catch {
                return try? Data(contentsOf: fileURL)
            }

            return nil
        } else {
            return self.fileDataVar
        }
    }

    override func fileInfo() -> FileInfo {

        if let fileInfoVar = self.fileInfoVar {
            return fileInfoVar
        } else {
            var title = ""
            var topLabel = ""
            var centerLabel: String?
            var bottomLabel: String?
            var bottomError = false
            var message: String?
            var icon: NSImage?
            var iconPath: String?

            var certificateFormat: CertificateFormat = .pkcs1

            if let fileURL = self.fileURL, fileURL.pathExtension == "p12" {
                certificateFormat = .pkcs12
            }

            if certificateFormat == .pkcs12 {
                self.certificateType = .p12

                // Title
                title = NSLocalizedString("Personal Information Exchange", comment: "")

                // Message
                message = NSLocalizedString("This content is stored in Personal Information Exchange (PKCS12) format, and is password protected.\nNo information can be displayed.", comment: "")

            } else if
                let fileData = self.fileData(),
                let certificate = SecCertificateCreateWithData(nil, fileData as CFData) {
                var errorRef: Unmanaged<CFError>?

                let certificateValues = SecCertificateCopyValues(certificate,
                                                                 [kSecOIDX509V1ValidityNotBefore,
                                                                  kSecOIDX509V1ValidityNotAfter,
                                                                  kSecOIDX509V1IssuerName,
                                                                  kSecOIDBasicConstraints,
                                                                  kSecOIDTitle] as CFArray, &errorRef) as? [String: Any]
                let error = errorRef?.takeRetainedValue()

                if let certValues = certificateValues {

                    // Title
                    if let certificateTitle = SecCertificateCopySubjectSummary(certificate) { title = certificateTitle as String }

                    // Check if certificate is self signed
                    let issuerData = SecCertificateCopyNormalizedIssuerContent(certificate, &errorRef)
                    if issuerData == nil {
                        Log.shared.error(message: "Failed to get certificate issuer data with error: \(String(describing: errorRef?.takeRetainedValue()))", category: String(describing: self))
                    }

                    let subjectData = SecCertificateCopyNormalizedSubjectContent(certificate, &errorRef)
                    if subjectData == nil {
                        Log.shared.error(message: "Failed to get certificate subject data with error: \(String(describing: errorRef?.takeRetainedValue()))", category: String(describing: self))
                    }

                    if issuerData == subjectData {
                        self.certificateType = .selfSignedCA

                        // Top
                        topLabel = NSLocalizedString("Root certificate authority", comment: "")
                    } else {
                        self.certificateType = .standard

                        // Is Certificate Authority
                        var isCertificateAuthority: Bool = false
                        if
                            let basicConstraintsDict = certValues[kSecOIDBasicConstraints as String] as? [String: Any],
                            let basicConstraints = basicConstraintsDict[kSecPropertyKeyValue as String] as? [[String: Any]] {
                            isCertificateAuthority = basicConstraints.contains(where: {
                                if
                                    let label = $0[kSecPropertyKeyLabel as String] as? String, label == "Certificate Authority",
                                    let value = $0[kSecPropertyKeyValue as String] as? NSString {
                                    return value.boolValue
                                } else { return false }
                            })
                        }

                        // Top
                        if isCertificateAuthority {
                            topLabel = NSLocalizedString("Intermediate certificate authority", comment: "")
                        } else {
                            if
                                let issuersDict = certValues[kSecOIDX509V1IssuerName as String] as? [String: Any],
                                let issuers = issuersDict[kSecPropertyKeyValue as String] as? [[String: Any]],
                                let issuer = issuers.first,
                                let issuerName = issuer[kSecPropertyKeyValue as String] as? String {
                                topLabel = NSLocalizedString("Issued by: \(issuerName)", comment: "")
                            } else {
                                topLabel = NSLocalizedString("Unknwon Issuer", comment: "")
                            }
                        }

                        // Not Valid Before
                        if
                            let notValidBeforeDict = certValues[kSecOIDX509V1ValidityNotBefore as String] as? [String: Any],
                            let notValidBefore = notValidBeforeDict[kSecPropertyKeyValue as String] as? Double,
                            let notValidBeforeDate = CFDateCreate(kCFAllocatorDefault, notValidBefore) as Date? {

                            if notValidBeforeDate.compare(Date()) == ComparisonResult.orderedDescending {

                                // Center
                                centerLabel = NSLocalizedString("Not valid before: \(DateFormatter.localizedString(from: notValidBeforeDate, dateStyle: .long, timeStyle: .long))", comment: "")

                                // Bottom
                                bottomLabel = NSLocalizedString("This certificate is not yet valid", comment: "")
                                bottomError = true
                            }
                        }

                        // Not Valid After
                        if
                            !bottomError,
                            let notValidAfterDict = certValues[kSecOIDX509V1ValidityNotAfter as String] as? [String: Any],
                            let notValidAfter = notValidAfterDict[kSecPropertyKeyValue as String] as? Double,
                            let notValidAfterDate = CFDateCreate(kCFAllocatorDefault, notValidAfter) as Date? {

                            if notValidAfterDate.compare(Date()) == ComparisonResult.orderedAscending {

                                // Center
                                centerLabel = NSLocalizedString("Expired: \(DateFormatter.localizedString(from: notValidAfterDate, dateStyle: .long, timeStyle: .long))", comment: "")

                                // Bottom
                                bottomLabel = NSLocalizedString("This certificate has expired", comment: "")
                                bottomError = true
                            } else {

                                // Center
                                centerLabel = NSLocalizedString("Expires: \(DateFormatter.localizedString(from: notValidAfterDate, dateStyle: .long, timeStyle: .long))", comment: "")
                            }
                        }
                    }
                } else {
                    Log.shared.error(message: "Failed to get certificate values with error: \(String(describing: error))", category: String(describing: self))
                }
            } else {
                Log.shared.error(message: "Failed to get data for file at: \(String(describing: self.fileURL?.path))", category: String(describing: self))
            }

            // Icon
            if let iconURL = self.iconURL(certificateType: self.certificateType) {
                iconPath = iconURL.path
            }

            if let certificateIcon = self.icon(certificateType: self.certificateType) {
                icon = certificateIcon
            } else {
                icon = NSWorkspace.shared.icon(forFileType: self.fileUTI)
            }

            // FIXME: Need to fix defaults here
            self.fileInfoVar = FileInfo(title: title,
                                        topLabel: topLabel,
                                        topContent: "",
                                        topError: false,
                                        centerLabel: centerLabel,
                                        centerContent: nil,
                                        centerError: false,
                                        bottomLabel: bottomLabel,
                                        bottomContent: nil,
                                        bottomError: bottomError,
                                        message: message,
                                        icon: icon,
                                        iconPath: iconPath)
            return self.fileInfoVar!
        }
    }
}
