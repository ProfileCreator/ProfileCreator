//
//  ExtensionPayloadSubkey.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension PayloadSubkey {
    func defaultValue(profileExport: ProfileExport? = nil, parentValueKeyPath: String? = nil, payloadIndex: Int = 0) -> Any? {

        if let valueDefault = self.valueDefault {
            return valueDefault
        }

        if let valueDefaultCopy = self.valueDefaultCopy {

            let valueDefaultCopyDomain: String
            let valueDefaultCopyKeyPath: String

            if valueDefaultCopy.contains("@") {
                valueDefaultCopyDomain = valueDefaultCopy.components(separatedBy: "@").first ?? self.domainIdentifier
                valueDefaultCopyKeyPath = valueDefaultCopy.components(separatedBy: "@").last ?? valueDefaultCopy
            } else {
                valueDefaultCopyDomain = self.domainIdentifier
                valueDefaultCopyKeyPath = valueDefaultCopy
            }

            if let valueDefaultCopySubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: valueDefaultCopyKeyPath, domainIdentifier: valueDefaultCopyDomain, type: self.payloadType) {

                var valueDefaultCopyParentValueKeyPath: String?

                if let pValueKeyPath = parentValueKeyPath, let valueDefaultCopySubkeyParent = valueDefaultCopySubkey.parentSubkey {
                    valueDefaultCopyParentValueKeyPath = PayloadUtility.expandKeyPath(valueDefaultCopySubkeyParent.valueKeyPath, withRootKeyPath: pValueKeyPath)
                }

                do {
                    return try profileExport?.value(forValueSubkey: valueDefaultCopySubkey, parentValueKeyPath: valueDefaultCopyParentValueKeyPath, payloadIndex: payloadIndex)
                } catch {
                    return nil
                }
            }

        }

        if let valueRangeList = self.rangeList?.first {
            return valueRangeList
        }

        return nil
    }

    func copyValue(profileExport: ProfileExport? = nil, parentValueKeyPath: String? = nil, payloadIndex: Int = 0) -> Any? {

        guard let valueCopy = self.valueCopy else { return nil }

        let valueCopyDomain: String
        let valueCopyKeyPath: String

        if valueCopy.contains("@") {
            valueCopyDomain = valueCopy.components(separatedBy: "@").first ?? self.domainIdentifier
            valueCopyKeyPath = valueCopy.components(separatedBy: "@").last ?? valueCopy
        } else {
            valueCopyDomain = self.domainIdentifier
            valueCopyKeyPath = valueCopy
        }

        guard let valueCopySubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: valueCopyKeyPath, domainIdentifier: valueCopyDomain, type: self.payloadType) else {
            return nil
        }

        var valueDefaultCopyParentValueKeyPath: String?

        if let pValueKeyPath = parentValueKeyPath, let valueDefaultCopySubkeyParent = valueCopySubkey.parentSubkey {
            valueDefaultCopyParentValueKeyPath = PayloadUtility.expandKeyPath(valueDefaultCopySubkeyParent.valueKeyPath, withRootKeyPath: pValueKeyPath)
        }

        do {
            return try profileExport?.value(forValueSubkey: valueCopySubkey, parentValueKeyPath: valueDefaultCopyParentValueKeyPath, payloadIndex: payloadIndex)
        } catch {
            return nil
        }
    }
}
