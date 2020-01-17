//
//  PayloadCellViewPadding.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewNoKeys: NSTableCellView, ProfileCreatorCellView {

    // MARK: -
    // MARK: PayloadCellView Variables

    var height: CGFloat = 0.0
    let textFieldTitle = NSTextField()
    var textFieldDescription: NSTextField? // Unused
    let buttonShowDisabled = NSButton()

    weak var profile: Profile?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(title titleString: String, description descriptionString: String?, profile: Profile) {
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()
        self.profile = profile

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        self.setupTextField(title: titleString, constraints: &constraints)

        if let description = descriptionString, !description.isEmpty {
            self.setupTextField(description: description, constraints: &constraints)
        }

        if profile.settings.showDisabledKeys == false {
            self.setupButtonShowDisabled(title: NSLocalizedString("Show Disabled Keys", comment: ""), constraints: &constraints)
        }

        // ---------------------------------------------------------------------
        //  Add spacing to bottom
        // ---------------------------------------------------------------------
        self.updateHeight(20.0)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    convenience init(payload: Payload, profile: Profile) {
        self.init(title: payload.title, description: payload.description, profile: profile)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    func updateHeight(_ height: CGFloat) {
        self.height += height
    }

    // MARK: -
    // MARK: Button Actions
    @objc func showDisabled(_ button: NSButton) {
        guard let profile = self.profile else { return }
        profile.settings.setValue(true, forKeyPath: profile.settings.showDisabledKeysSelector)
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewNoKeys {

    private func setupTextField(title: String, constraints: inout [NSLayoutConstraint]) {
        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.lineBreakMode = .byWordWrapping
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = false
        self.textFieldTitle.isSelectable = false
        self.textFieldTitle.textColor = .tertiaryLabelColor
        self.textFieldTitle.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        self.textFieldTitle.stringValue = title
        self.textFieldTitle.alignment = .center
        self.textFieldTitle.font = NSFont.systemFont(ofSize: 20, weight: .bold)

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 8.0))
        self.updateHeight(8 + self.textFieldTitle.intrinsicContentSize.height)

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))
    }

    private func setupTextField(description: String, constraints: inout [NSLayoutConstraint]) {
        let textFieldDescription = NSTextField()
        textFieldDescription.translatesAutoresizingMaskIntoConstraints = false
        textFieldDescription.lineBreakMode = .byWordWrapping
        textFieldDescription.isBordered = false
        textFieldDescription.isBezeled = false
        textFieldDescription.drawsBackground = false
        textFieldDescription.isEditable = false
        textFieldDescription.isSelectable = false
        textFieldDescription.textColor = .labelColor
        textFieldDescription.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        textFieldDescription.stringValue = description
        textFieldDescription.alignment = .center
        textFieldDescription.font = NSFont.systemFont(ofSize: 15, weight: .ultraLight)
        self.textFieldDescription = textFieldDescription

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(textFieldDescription)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 6.0))
        self.updateHeight(6 + textFieldDescription.intrinsicContentSize.height)

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldDescription,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))
    }

    private func setupButtonShowDisabled(title: String, constraints: inout [NSLayoutConstraint]) {
        self.buttonShowDisabled.translatesAutoresizingMaskIntoConstraints = false
        self.buttonShowDisabled.bezelStyle = .rounded
        self.buttonShowDisabled.setButtonType(.momentaryPushIn)
        self.buttonShowDisabled.isBordered = true
        self.buttonShowDisabled.isTransparent = false
        self.buttonShowDisabled.title = title
        self.buttonShowDisabled.target = self
        self.buttonShowDisabled.action = #selector(self.showDisabled(_:))
        self.buttonShowDisabled.sizeToFit()
        self.buttonShowDisabled.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonShowDisabled)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.buttonShowDisabled,
                                                           attribute: .top,
                                                           relatedBy: .equal,
                                                           toItem: self.textFieldTitle,
                                                           attribute: .bottom,
                                                           multiplier: 1.0,
                                                           constant: 8.0))

        // Center X
        constraints.append(NSLayoutConstraint(item: self.buttonShowDisabled,
                                                           attribute: .centerX,
                                                           relatedBy: .equal,
                                                           toItem: self,
                                                           attribute: .centerX,
                                                           multiplier: 1.0,
                                                           constant: 0.0))

        self.updateHeight((8 + self.buttonShowDisabled.intrinsicContentSize.height))
    }
}
