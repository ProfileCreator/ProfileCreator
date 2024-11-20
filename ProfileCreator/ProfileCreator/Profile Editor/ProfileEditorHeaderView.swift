//
//  ProfileEditorHeaderView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class ProfileEditorHeaderView: NSObject {

    // MARK: -
    // MARK: Variables

    weak var profile: Profile?

    let headerView = NSView()
    let textFieldTitle = NSTextField()
    let textFieldTitleTopIndent: CGFloat = 28.0

    let textFieldDescription = NSTextField()
    let textFieldDescriptionTopIndent: CGFloat = 4.0

    let textFieldPlatforms = NSTextField()
    let textFieldScope = NSTextField()

    let popUpButtonAppVersion = NSPopUpButton()

    let imageViewIcon = NSImageView()
    let buttonAddRemove = NSButton()

    let buttonTitleEnable = NSLocalizedString("Add", comment: "")
    let buttonTitleDisable = NSLocalizedString("Remove", comment: "")

    var height: CGFloat = 0.0
    var layoutConstraintHeight: NSLayoutConstraint?

    weak var selectedPayloadPlaceholder: PayloadPlaceholder?
    weak var profileEditor: ProfileEditor?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile) {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangePayloadSelected(_:)), name: .didChangePayloadSelected, object: nil)

        // ---------------------------------------------------------------------
        //  Add subviews to headerView
        // ---------------------------------------------------------------------
        self.setupHeaderView(constraints: &constraints)
        self.setupTextFieldTitle(constraints: &constraints)
        self.setupTextFieldDescription(constraints: &constraints)
        self.setupTextFieldPlatforms(constraints: &constraints)
        self.setupTextFieldScope(constraints: &constraints)
        self.setupPopUpButtonAppVersion(constraints: &constraints)
        self.setupButtonAddRemove(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: -
    // MARK: Private Functions

    private func updateHeight(_ height: CGFloat) {
        self.height += height
    }

    // MARK: -
    // MARK: Functions

    @objc func didChangePayloadSelected(_ notification: NSNotification?) {
        guard
            let userInfo = notification?.userInfo,
            let payloadPlaceholder = userInfo[NotificationKey.payloadPlaceholder] as? PayloadPlaceholder,
            let selected = userInfo[NotificationKey.payloadSelected] as? Bool else { return }

        if self.selectedPayloadPlaceholder == payloadPlaceholder {
            self.setButtonState(enabled: selected)
        }
    }

    func setButtonState(enabled: Bool) {
        if enabled {
            self.buttonAddRemove.attributedTitle = NSAttributedString(string: self.buttonTitleDisable, attributes: [ .foregroundColor: NSColor.systemRed ])
        } else {
            self.buttonAddRemove.title = self.buttonTitleEnable // attributedTitle = NSAttributedString(string: "Add", attributes: [ NSAttributedStringKey.foregroundColor : NSColor.green ])
        }
    }

    @objc func clicked(button: NSButton) {
        if let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder {
            NotificationCenter.default.post(name: .changePayloadSelected, object: self, userInfo: [NotificationKey.payloadPlaceholder: selectedPayloadPlaceholder ])
        }
    }

    @objc func toggleTitle(sender: NSGestureRecognizer) {
        if let toolTip = self.textFieldTitle.toolTip {
            self.textFieldTitle.toolTip = self.textFieldTitle.stringValue
            self.textFieldTitle.stringValue = toolTip
        }
    }

    func select(payloadPlaceholder: PayloadPlaceholder) {
        if self.selectedPayloadPlaceholder != payloadPlaceholder {
            self.selectedPayloadPlaceholder = payloadPlaceholder

            // Hide button if it's the general settings
            if payloadPlaceholder.payloadType == .custom || ( payloadPlaceholder.domain == kManifestDomainConfiguration && payloadPlaceholder.payloadType == .manifestsApple ) {
                self.buttonAddRemove.isHidden = true
            } else if let profile = self.profile {
                self.buttonAddRemove.isHidden = false
                self.setButtonState(enabled: profile.settings.isIncludedInProfile(payload: payloadPlaceholder.payload))
            } else {
                self.buttonAddRemove.isHidden = true
            }

            self.textFieldTitle.stringValue = payloadPlaceholder.title
            if payloadPlaceholder.domain != kManifestDomainConfiguration {
                self.textFieldTitle.toolTip = payloadPlaceholder.domain
            } else { self.textFieldTitle.toolTip = nil }

            self.textFieldDescription.stringValue = payloadPlaceholder.description

            self.popUpButtonAppVersion.removeAllItems()
            if payloadPlaceholder.payloadType == .managedPreferencesApplications, let payload = payloadPlaceholder.payload as? PayloadManagedPreference {
                if let appVersions = payload.appVersions {
                    self.popUpButtonAppVersion.addItems(withTitles: appVersions)
                }
            }

            self.textFieldPlatforms.stringValue = PayloadUtility.string(fromPlatforms: payloadPlaceholder.payload.platforms, separator: " ")
            self.textFieldScope.stringValue = PayloadUtility.string(fromTargets: payloadPlaceholder.payload.targets, separator: " ")
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension ProfileEditorHeaderView {
    private func setupHeaderView(constraints: inout [NSLayoutConstraint]) {
        self.headerView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupButtonAddRemove(constraints: inout [NSLayoutConstraint]) {
        self.buttonAddRemove.translatesAutoresizingMaskIntoConstraints = false
        self.buttonAddRemove.title = self.buttonTitleEnable
        self.buttonAddRemove.bezelStyle = .roundRect
        self.buttonAddRemove.setButtonType(.momentaryPushIn)
        self.buttonAddRemove.isBordered = true
        self.buttonAddRemove.isTransparent = false
        self.buttonAddRemove.action = #selector(self.clicked(button:))
        self.buttonAddRemove.target = self

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.headerView.addSubview(self.buttonAddRemove)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.buttonAddRemove,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.headerView,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: self.textFieldTitleTopIndent))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.headerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.buttonAddRemove,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 24.0))
    }

    private func setupTextFieldPlatforms(constraints: inout [NSLayoutConstraint]) {
        self.textFieldPlatforms.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldPlatforms.lineBreakMode = .byWordWrapping
        self.textFieldPlatforms.isBordered = false
        self.textFieldPlatforms.isBezeled = false
        self.textFieldPlatforms.drawsBackground = false
        self.textFieldPlatforms.isEditable = false
        self.textFieldPlatforms.isSelectable = false
        self.textFieldPlatforms.textColor = .secondaryLabelColor
        self.textFieldPlatforms.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        self.textFieldPlatforms.alignment = .right
        self.textFieldPlatforms.font = NSFont.systemFont(ofSize: 12, weight: .regular)

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.headerView.addSubview(self.textFieldPlatforms)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldPlatforms,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.buttonAddRemove,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 6.0))

        // Width
        constraints.append(NSLayoutConstraint(item: self.textFieldPlatforms,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 97.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.headerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldPlatforms,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 24.0))
    }

    private func setupTextFieldScope(constraints: inout [NSLayoutConstraint]) {
        self.textFieldScope.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldScope.lineBreakMode = .byWordWrapping
        self.textFieldScope.isBordered = false
        self.textFieldScope.isBezeled = false
        self.textFieldScope.drawsBackground = false
        self.textFieldScope.isEditable = false
        self.textFieldScope.isSelectable = false
        self.textFieldScope.textColor = .secondaryLabelColor
        self.textFieldScope.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        self.textFieldScope.alignment = .right
        self.textFieldScope.font = NSFont.systemFont(ofSize: 12, weight: .regular)

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.headerView.addSubview(self.textFieldScope)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldScope,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldPlatforms,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 1.0))

        // Width
        constraints.append(NSLayoutConstraint(item: self.textFieldScope,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 76.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.headerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldScope,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 24.0))
    }

    private func setupTextFieldTitle(constraints: inout [NSLayoutConstraint]) {
        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.lineBreakMode = .byWordWrapping
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = false
        self.textFieldTitle.isSelectable = false
        self.textFieldTitle.textColor = .labelColor
        self.textFieldTitle.alignment = .left
        self.textFieldTitle.stringValue = "Title"
        self.textFieldTitle.font = NSFont.systemFont(ofSize: 28, weight: .heavy)
        self.textFieldTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // ---------------------------------------------------------------------
        //  Setup GestureRecognizer
        // ---------------------------------------------------------------------
        let gesture = NSClickGestureRecognizer()
        gesture.numberOfClicksRequired = 1
        gesture.target = self
        gesture.action = #selector(self.toggleTitle(sender:))
        self.textFieldTitle.addGestureRecognizer(gesture)

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.headerView.addSubview(self.textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.headerView,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: self.textFieldTitleTopIndent))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.headerView,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 24.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.textFieldPlatforms,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 4.0))
    }

    private func setupPopUpButtonAppVersion(constraints: inout [NSLayoutConstraint]) {
        self.popUpButtonAppVersion.translatesAutoresizingMaskIntoConstraints = false
        self.popUpButtonAppVersion.isHidden = true

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.headerView.addSubview(self.popUpButtonAppVersion)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.popUpButtonAppVersion,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.textFieldScope,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.popUpButtonAppVersion,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldScope,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 4.0))
    }

    private func setupTextFieldDescription(constraints: inout [NSLayoutConstraint]) {
        self.textFieldDescription.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldDescription.lineBreakMode = .byWordWrapping
        self.textFieldDescription.isBordered = false
        self.textFieldDescription.isBezeled = false
        self.textFieldDescription.drawsBackground = false
        self.textFieldDescription.isEditable = false
        self.textFieldDescription.isSelectable = false
        self.textFieldDescription.textColor = .labelColor
        self.textFieldDescription.alignment = .left
        self.textFieldDescription.stringValue = "Description"
        self.textFieldDescription.font = NSFont.systemFont(ofSize: 17, weight: .ultraLight)
        self.textFieldDescription.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.headerView.addSubview(self.textFieldDescription)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldDescription,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: self.textFieldDescriptionTopIndent))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.headerView,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 24.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.textFieldPlatforms,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.textFieldDescription,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 4.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self.headerView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.textFieldDescription,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 12.0))

        // self.updateHeight(description.intrinsicContentSize.height)
    }
}
