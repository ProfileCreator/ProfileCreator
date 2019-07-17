//
//  PayloadLibraryCellViewLibrary.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadLibraryCellViewLibrary: NSTableCellView, PayloadLibraryCellView {

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

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(payloadPlaceholder: PayloadPlaceholder) {
        self.placeholder = payloadPlaceholder

        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        self.imageViewIcon = LibraryImageView.icon(image: payloadPlaceholder.icon, width: 28.0, indent: 2.0, constraints: &constraints, cellView: self)
        self.buttonToggle = LibraryButton.toggle(image: NSImage(named: NSImage.addTemplateName), width: 14.0, indent: 5.0, constraints: &constraints, cellView: self)
        if payloadPlaceholder.domain != kManifestDomainConfiguration, UserDefaults.standard.bool(forKey: PreferenceKey.payloadLibraryShowDomainAsTitle) {
            self.textFieldTitle = LibraryTextField.title(string: payloadPlaceholder.domain, fontSize: 11, fontWeight: NSFont.Weight.semibold.rawValue, indent: 4.0, constraints: &constraints, cellView: self)
        } else {
            self.textFieldTitle = LibraryTextField.title(string: payloadPlaceholder.title, fontSize: 11, fontWeight: NSFont.Weight.semibold.rawValue, indent: 4.0, constraints: &constraints, cellView: self)
        }

        if payloadPlaceholder.payload.updateAvailable {
            self.textFieldDescription = LibraryTextField.description(string: "Update Available", constraints: &constraints, topConstant: 0.0, cellView: self)
            self.textFieldDescription?.textColor = .systemRed
        }

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        // ImageView Leading
        let constraintImageViewLeading = NSLayoutConstraint(item: self.imageViewIcon!,
                                                            attribute: .leading,
                                                            relatedBy: .equal,
                                                            toItem: self,
                                                            attribute: .leading,
                                                            multiplier: 1.0,
                                                            constant: 5.0)

        self.constraintImageViewLeading = constraintImageViewLeading
        constraints.append(constraintImageViewLeading)

        if self.textFieldDescription == nil {
            // TextFieldTitle Center Y
            constraints.append(NSLayoutConstraint(item: self.textFieldTitle!,
                                                  attribute: .centerY,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .centerY,
                                                  multiplier: 1.0,
                                                  constant: 0.0))
        } else if let textFieldTitle = self.textFieldTitle {
            constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .top,
                                                  multiplier: 1.0,
                                                  constant: 2.5))
        }
        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }
}
