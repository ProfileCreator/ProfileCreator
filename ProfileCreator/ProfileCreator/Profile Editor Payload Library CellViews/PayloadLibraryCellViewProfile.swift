//
//  PayloadLibraryCellViewProfile.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadLibraryCellViewProfile: NSTableCellView, PayloadLibraryCellView {

    // MARK: -
    // MARK: PayloadLibraryCellView Variables

    var row = -1
    var isMovable = true
    var constraintImageViewLeading: NSLayoutConstraint?

    var textFieldTitle: NSTextField?
    var textFieldDescription: NSTextField?
    var imageViewIcon: NSImageView?
    var buttonToggle: NSButton?
    var buttonToggleIndent: CGFloat = 24
    weak var placeholder: PayloadPlaceholder?
    weak var profile: Profile?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(payloadPlaceholder: PayloadPlaceholder, profile: Profile?) {

        self.placeholder = payloadPlaceholder
        self.profile = profile

        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        let imageViewIcon = LibraryImageView.icon(image: payloadPlaceholder.icon, width: 31.0, indent: 4.0, constraints: &constraints, cellView: self)
        self.imageViewIcon = imageViewIcon

        self.buttonToggle = LibraryButton.toggle(image: NSImage(named: NSImage.removeTemplateName), width: 14.0, indent: 5.0, constraints: &constraints, cellView: self)
        if payloadPlaceholder.domain != kManifestDomainConfiguration, UserDefaults.standard.bool(forKey: PreferenceKey.payloadLibraryShowDomainAsTitle) {
            self.textFieldTitle = LibraryTextField.title(string: payloadPlaceholder.domain, fontSize: 12, fontWeight: NSFont.Weight.bold.rawValue, indent: 6.0, constraints: &constraints, cellView: self)
        } else {
            self.textFieldTitle = LibraryTextField.title(string: payloadPlaceholder.title, fontSize: 12, fontWeight: NSFont.Weight.bold.rawValue, indent: 6.0, constraints: &constraints, cellView: self)
        }

        if payloadPlaceholder.payload.updateAvailable {
            self.textFieldDescription = LibraryTextField.description(string: "Update Available", constraints: &constraints, topConstant: 0.0, cellView: self)
            self.textFieldDescription?.textColor = .systemRed
        } else {
            self.textFieldDescription = LibraryTextField.description(string: "1 Payload", constraints: &constraints, cellView: self)
            self.textFieldDescription?.textColor = .labelColor
        }

        self.updatePayloadCount(payloadPlaceholder: payloadPlaceholder)

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        // ImageView Leading
        let constraintImageViewLeading = NSLayoutConstraint(item: imageViewIcon,
                                                            attribute: .leading,
                                                            relatedBy: .equal,
                                                            toItem: self,
                                                            attribute: .leading,
                                                            multiplier: 1.0,
                                                            constant: 5.0)
        self.constraintImageViewLeading = constraintImageViewLeading
        constraints.append(constraintImageViewLeading)

        // TextFieldTitle Top
        if let textFieldTitle = self.textFieldTitle {
            constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .top,
                                                  multiplier: 1.0,
                                                  constant: 4.5))
        }

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    func updatePayloadCount(payloadPlaceholder: PayloadPlaceholder) {

        guard let profile = self.profile else { return }
        // let payloadCount = profile?.settings.getPayloadDomainSettingsCount(domain: payloadPlaceholder.domain, type: payloadPlaceholder.payloadType) ?? 1
        let payloadCount = profile.settings.settingsCount(forDomainIdentifier: payloadPlaceholder.domainIdentifier, type: payloadPlaceholder.payloadType)
        let payloadCountString: String
        if payloadCount <= 1 {
            payloadCountString = NSLocalizedString("Payload", comment: "")
        } else {
            payloadCountString = NSLocalizedString("Payloads", comment: "")
        }

        self.textFieldDescription?.stringValue = "\(payloadCount == 0 ? 1 : payloadCount) \(payloadCountString)"

    }
}
