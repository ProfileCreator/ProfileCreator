//
//  ProfileSigning.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

class ProfileSigning {

    class func sign(_ profile: [String: Any], usingSigningCertificate signingCertificate: Data) throws -> Data? {

        // ---------------------------------------------------------------------
        //  Get the selected signing identity
        // ---------------------------------------------------------------------
        guard let identity = Identities.codeSigningIdentity(persistentRef: signingCertificate) else {
            throw ProfileExportError.signingErrorGetIdentity
        }
        Log.shared.info(message: "Selected Signing Certificate: \(String(describing: identity.certificateName))", category: String(describing: self))

        // ---------------------------------------------------------------------
        //  Generate a configuration profile xml as Data
        // ---------------------------------------------------------------------
        let profileContentData = try PropertyListSerialization.data(fromPropertyList: profile, format: .xml, options: 0)

        // ---------------------------------------------------------------------
        //  Get an unsafeRawPointer to the Data and sign it with CMSEncode
        // ---------------------------------------------------------------------
        var profileContentDataSigned: CFData?
        return try profileContentData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            let osStatus = CMSEncodeContent(identity,
                                            nil,
                                            nil,
                                            false,
                                            CMSSignedAttributes.attrSigningTime,
                                            ptr.baseAddress!,
                                            profileContentData.count,
                                            &profileContentDataSigned)

            // ---------------------------------------------------------------------
            //  Verify there were no signing errors
            // ---------------------------------------------------------------------
            if osStatus != noErr {

                // Replace this log message with the correct throw-error
                let osStatusString = String(SecCopyErrorMessageString(osStatus, nil) ?? "")
                Log.shared.error(message: "Signing profile failed with error: \(osStatus) - \(osStatusString)", category: String(describing: self))

                // This error is returned when the ACLs somehow aren't giving correct access. Simply opening keychaing and switching the ACLs on and off and saving.
                if osStatus == errSecInternalComponent {
                    Log.shared.error(message: "FIX: Open keychain and update the ACLs for the private key of the certificate you are trying to use.", category: String(describing: self))
                }

                throw ProfileExportError.signingErrorFailed(usingCertificate: identity.certificateName ?? "Unknown", withError: osStatusString)
            }

            // ---------------------------------------------------------------------
            //  Write the signed profile to the selected output path
            // ---------------------------------------------------------------------
            return profileContentDataSigned as Data?
        }
    }

    class func decode(data: Data) throws -> Data {
        var osStatus: OSStatus = noErr
        var cmsDecoder: CMSDecoder?
        var cmsEncrypted: DarwinBoolean = false

        osStatus = CMSDecoderCreate(&cmsDecoder)
        if osStatus != noErr {
            let osStatusString = String(SecCopyErrorMessageString(osStatus, nil) ?? "")
            Log.shared.error(message: "Creating CMSDecoder failed with error: \(osStatus) - \(osStatusString)", category: String(describing: self))
            return data
        }

        guard let decoder = cmsDecoder else {
            Log.shared.error(message: "Creating CMSDecoder failed", category: String(describing: self))
            return data
        }

        let decodedData: CFData? = try data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            let rawPtr = UnsafeRawPointer(ptr.baseAddress!)
            var cmsData: CFData?

            osStatus = CMSDecoderUpdateMessage(decoder, rawPtr, data.count)
            if osStatus != noErr {
                let osStatusString = String(SecCopyErrorMessageString(osStatus, nil) ?? "")
                Log.shared.error(message: "CMSDecoderUpdateMessage failed with error: \(osStatus) - \(osStatusString)", category: String(describing: self))
                return nil
            }

            osStatus = CMSDecoderFinalizeMessage(decoder)
            if osStatus != noErr {
                let osStatusString = String(SecCopyErrorMessageString(osStatus, nil) ?? "")
                Log.shared.error(message: "CMSDecoderFinalizeMessage failed with error: \(osStatus) - \(osStatusString)", category: String(describing: self))
                return nil
            }

            CMSDecoderIsContentEncrypted(decoder, &cmsEncrypted)
            if cmsEncrypted.boolValue {
                throw ProfileImportError.isEncrypted
            }

            osStatus = CMSDecoderCopyContent(decoder, &cmsData)
            if osStatus != noErr {
                let osStatusString = String(SecCopyErrorMessageString(osStatus, nil) ?? "")
                Log.shared.error(message: "CMSDecoderCopyContent failed with error: \(osStatus) - \(osStatusString)", category: String(describing: self))
                return nil
            }

            return cmsData
        }

        if let decodedData = decodedData as Data? {
            return decodedData
        } else {
            return data
        }
    }
}
