//
//  ValueInfoProcessors.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class ValueInfoProcessors {

    // MARK: -
    // MARK: Variables

    public static let shared = ValueInfoProcessors()

    // MARK: -
    // MARK: Initialization

    private init() {}

    public func processor(forSubkey subkey: PayloadSubkey) -> ValueInfoProcessor? {
        guard let allowedFileTypes = subkey.allowedFileTypes, let allowedUTI = allowedFileTypes.first else { return nil }
        return self.processor(forUTI: allowedUTI)
    }

    public func processor(forFileAtURL url: URL) -> ValueInfoProcessor? {
        return self.processor(forUTI: url.typeIdentifier)
    }

    public func processor(withIdentifier identifier: String) -> ValueInfoProcessor? {
        switch identifier {
        case "certificate":
            return ValueInfoProcessorCertificate()
        case "font":
            return ValueInfoProcessorFont()
        case "image":
            return ValueInfoProcessorImage()
        case "shell-script":
            return ValueInfoProcessorShellScript()
        default:
            return nil
        }
    }

    public func processor(forUTI uti: String) -> ValueInfoProcessor? {
        if NSWorkspace.shared.type(uti, conformsToType: kUTTypeX509Certificate as String) || NSWorkspace.shared.type(uti, conformsToType: kUTTypePKCS12 as String) {
            return ValueInfoProcessorCertificate()
        } else if NSWorkspace.shared.type(uti, conformsToType: kUTTypeFont as String) {
            return ValueInfoProcessorFont()
        } else if NSWorkspace.shared.type(uti, conformsToType: kUTTypeImage as String) {
            return ValueInfoProcessorImage()
        } else if NSWorkspace.shared.type(uti, conformsToType: kUTTypeShellScript as String) {
            return ValueInfoProcessorShellScript()
        }
        return nil
    }
}
