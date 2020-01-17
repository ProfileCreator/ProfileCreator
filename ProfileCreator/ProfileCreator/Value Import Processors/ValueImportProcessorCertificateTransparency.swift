//
//  ValueImportProcessorCertificateTransparency.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import CommonCrypto
import Security

class ValueImportProcessorCertificateTransparency: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.security.certificatetransparency")
    }

    enum PublicKeyAlgorithm: String {
        case rsa2048
        case rsa4096
        case ecDsaSecp256r1
        case ecDsaSecp384r1

        var asn1Header: Data? {
            switch self {
            case .rsa2048:
                return Data(bytes: [ 0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                                     0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00 ])
            case .rsa4096:
                return Data(bytes: [ 0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                                     0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00 ])
            case .ecDsaSecp256r1:
                return Data(bytes: [ 0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
                                     0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
                                     0x42, 0x00 ])
            case .ecDsaSecp384r1:
                return Data(bytes: [ 0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
                                     0x01, 0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00 ])
            }
        }
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // File, Directory or URL
        guard
            let fileUTI = self.fileUTI,
            let fileURL = self.fileURL,
            NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypeX509Certificate as String) else { completionHandler(nil); return }

        // Get Certificate and generate Hash
        guard
            let certificate = try self.certificate(forURL: fileURL),
            let certificateHash = try self.spkiHash(forCertificate: certificate),
            let certificateHashData = Data(base64Encoded: certificateHash) else { completionHandler(nil); return }

        // Check if certificate is already added
        if let currentValue = toCurrentValue as? [[String: Any]], currentValue.contains(where: {
            if let hash = $0["Hash"] as? Data {
                return hash == certificateHashData
            } else {
                return false
            }
        }) {
            completionHandler(nil)
            return
        }

        var value = [String: Any]()

        // Algorithm
        value["Algorithm"] = "sha256"

        // Hash
        value["Hash"] = certificateHashData

        if var currentValue = toCurrentValue as? [[String: Any]] {
            currentValue.append(value)
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }

    func certificate(forURL url: URL) throws -> SecCertificate? {
        do {
            let data = try Data(contentsOf: url)

            // Create SecCertificate from passed Data
            if let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData) {
                return certificate
            } else if
                let certificateString = String(data: data, encoding: .utf8),
                let certData = Certificate.certificateData(forString: certificateString) {
                return SecCertificateCreateWithData(kCFAllocatorDefault, certData as CFData)
            } else {
                throw ValueImportError("Failed to create a SecCertificate instance from passed data")
            }
        } catch {
            throw error
        }
    }

    func spkiHash(forCertificate certificate: SecCertificate) throws -> String? {
        var error: Unmanaged<CFError>?

        guard
            let publicKey = publicKey(forCertificate: certificate),
            let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?,
            let publicKeyASN1HeaderData = publicKeyASN1Header(forKey: publicKey) else {
                throw ValueImportError("The selected certificate did not have a valid publick key or ASN1 header.\n\nVerify that the certificate file only contains ONE certificate.")
        }

        let context = UnsafeMutablePointer<CC_SHA256_CTX>.allocate(capacity: 1)
        CC_SHA256_Init(context)

        publicKeyASN1HeaderData.withUnsafeBytes { bytes in
            _ = CC_SHA256_Update(context, bytes, CC_LONG(publicKeyASN1HeaderData.count))
        }

        publicKeyData.withUnsafeBytes { bytes in
            _ = CC_SHA256_Update(context, bytes, CC_LONG(publicKeyData.count))
        }

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, context)
        let publicKeyInfoData = Data(bytes: digest)

        return publicKeyInfoData.base64EncodedString()
    }

    func publicKey(forCertificate certificate: SecCertificate) -> SecKey? {
        if #available(OSX 10.14, *) {
            return SecCertificateCopyKey(certificate)
        } else {
            var publicSecKey: SecKey?
            let osStatus = SecCertificateCopyPublicKey(certificate, &publicSecKey)
            guard osStatus == errSecSuccess else {
                Log.shared.error(message: "Failed to copy certificate public key with error: \(String(describing: SecCopyErrorMessageString(osStatus, nil)))", category: String(describing: self))
                return nil
            }
            return publicSecKey
        }
    }

    func publicKeyASN1Header(forKey key: SecKey) -> Data? {
        guard
            let publicKeyAttributes = SecKeyCopyAttributes(key) as? [String: Any],
            let publicKeyTypeString = publicKeyAttributes[kSecAttrKeyType as String] as? String,
            let publicKeyType = Int(publicKeyTypeString),
            let publicKeySize = publicKeyAttributes[kSecAttrKeySizeInBits as String] as? Int else { return nil }

        switch publicKeyType {
        case Int(kSecAttrKeyTypeRSA as String):
            if publicKeySize == 2_048 { return PublicKeyAlgorithm.rsa2048.asn1Header }
            if publicKeySize == 4_096 { return PublicKeyAlgorithm.rsa4096.asn1Header }
        case Int(kSecAttrKeyTypeEC as String):
            if publicKeySize == 256 { return PublicKeyAlgorithm.ecDsaSecp256r1.asn1Header }
            if publicKeySize == 384 { return PublicKeyAlgorithm.ecDsaSecp384r1.asn1Header }
        default:
            return nil
        }

        return nil
    }
}
