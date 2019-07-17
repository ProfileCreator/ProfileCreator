//
//  ProfileEditorOutlineView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileEditor {

    func updateOutlineView(payloadPlaceholder: PayloadPlaceholder) {

        var payloadContent = [String: Any]()

        if payloadPlaceholder.payloadType == .custom, let payloadCustom = payloadPlaceholder.payload as? PayloadCustom {
            if
                let payloadCustomContents = payloadCustom.payloadContent,
                self.selectedPayloadIndex < payloadCustomContents.count {
                payloadContent = payloadCustomContents[self.selectedPayloadIndex]
                payloadContent.removeValue(forKey: PayloadKey.payloadEnabled)
            }
        } else {
            let profileExport = ProfileExport(exportSettings: self.profile.settings)
            profileExport.ignoreErrorInvalidValue = true
            profileExport.ignoreSave = true

            do {
                payloadContent = try profileExport.content(forPayload: payloadPlaceholder.payload, payloadIndex: self.selectedPayloadIndex)
                profileExport.updateManagedPreferences(domain: payloadPlaceholder.domain, type: payloadPlaceholder.payloadType, payloadContent: &payloadContent)
            } catch {
                Log.shared.error(message: "Source view export failed with error: \(error)", category: String(describing: self))
            }
        }

        self.outlineViewController.updateSourceView(payloadContent)
    }

}
