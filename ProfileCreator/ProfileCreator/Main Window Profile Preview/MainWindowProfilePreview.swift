//
//  MainWindowProfilePreview.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowProfilePreviewController: NSObject {

    // MARK: -
    // MARK: Variables

    let view = NSVisualEffectView()
    let infoViewController = MainWindowProfilePreviewInfoViewController()
    let previewViewController = MainWindowProfilePreviewViewController()

    // MARK: -
    // MARK: Initialization

    override init() {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Effect View (Background)
        // ---------------------------------------------------------------------
        self.view.translatesAutoresizingMaskIntoConstraints = false
        if #available(OSX 10.14, *) {
            self.view.material = .contentBackground
        } else {
            self.view.material = .light
        }

        // ---------------------------------------------------------------------
        //  Setup Info View
        // ---------------------------------------------------------------------
        insert(subview: infoViewController.view)

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeProfileSelection(_:)), name: .didChangeProfileSelection, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .didChangeProfileSelection, object: nil)
    }

    @objc func didChangeProfileSelection(_ notification: NSNotification?) {
        if let userInfo = notification?.userInfo,
            let profileIdentifiers = userInfo[NotificationKey.identifiers] as? [UUID] {

            if profileIdentifiers.count == 1 {
                if let profile = ProfileController.sharedInstance.profile(withIdentifier: profileIdentifiers.first!) {
                    self.previewViewController.updateSelection(profile: profile)
                    infoViewController.view.removeFromSuperview()
                    insert(subview: previewViewController.view)
                    self.view.state = .inactive
                }
            } else {
                self.infoViewController.updateSelection(count: profileIdentifiers.count)
                previewViewController.view.removeFromSuperview()
                insert(subview: infoViewController.view)
                self.view.state = .active
            }
        }
    }

    // MARK: -
    // MARK: Setup Layout Constraints

    private func insert(subview: NSView) {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Add subview to main view
        // ---------------------------------------------------------------------
        self.view.addSubview(subview)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Top
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: subview,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: subview,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: subview,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: subview,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }
}

class MainWindowProfilePreviewViewController: NSObject {

    // MARK: -
    // MARK: Variables

    let view = NSView()
    let textFieldTitle = NSTextField()
    let textFieldDescription = NSTextField()

    // MARK: -
    // MARK: Initialization

    override init() {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup View
        // ---------------------------------------------------------------------
        self.view.translatesAutoresizingMaskIntoConstraints = false

        // ---------------------------------------------------------------------
        //  Create and add TextField
        // ---------------------------------------------------------------------
        self.setupTextFieldTitle(constraints: &constraints)
        self.setupTextFieldDescription(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: -
    // MARK: Public Functions

    public func updateSelection(profile: Profile) {
        self.textFieldTitle.stringValue = profile.settings.title
        if profile.versionFormatSupported {
            self.textFieldDescription.stringValue = "(This will show a preview of the profile settings. Not Implemented.)"
        } else {
            self.textFieldDescription.stringValue = "This profile is saved in an older format and cannot be read by this version of ProfileCreator.\n\nTo add this profile to the application again you need to export it as a .mobileconfig using ProfileCreator Beta 4 (0.1-4).\n\nTo learn more, please read the release notes for Beta 5."
        }
    }

    // MARK: -
    // MARK: Setup Layout Constraints

    private func setupTextFieldTitle(constraints: inout [NSLayoutConstraint]) {

        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.lineBreakMode = .byWordWrapping
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = false
        self.textFieldTitle.font = NSFont.boldSystemFont(ofSize: 30)
        self.textFieldTitle.textColor = .labelColor
        self.textFieldTitle.alignment = .center
        self.textFieldTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // ---------------------------------------------------------------------
        //  Add subview to main view
        // ---------------------------------------------------------------------
        self.view.addSubview(self.textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 60.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 10.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 10.0))
    }

    private func setupTextFieldDescription(constraints: inout [NSLayoutConstraint]) {

        self.textFieldDescription.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldDescription.lineBreakMode = .byWordWrapping
        self.textFieldDescription.isBordered = false
        self.textFieldDescription.isBezeled = false
        self.textFieldDescription.drawsBackground = false
        self.textFieldDescription.isEditable = false
        self.textFieldDescription.font = NSFont.systemFont(ofSize: 19)
        self.textFieldDescription.textColor = .tertiaryLabelColor
        self.textFieldDescription.alignment = .center
        self.textFieldDescription.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.textFieldDescription.stringValue = "(This will show a preview of the profile settings. Not Implemented.)"

        // ---------------------------------------------------------------------
        //  Add subview to main view
        // ---------------------------------------------------------------------
        self.view.addSubview(self.textFieldDescription)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldDescription,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 8))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 20.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textFieldDescription,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 20.0))
    }
}

class MainWindowProfilePreviewInfoViewController: NSObject {

    // MARK: -
    // MARK: Variables

    let view = NSView()
    let textField = NSTextField()

    // MARK: -
    // MARK: Initialization

    override init() {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup View
        // ---------------------------------------------------------------------
        self.view.translatesAutoresizingMaskIntoConstraints = false

        // ---------------------------------------------------------------------
        //  Create and add TextField
        // ---------------------------------------------------------------------
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.lineBreakMode = .byWordWrapping
        self.textField.isBordered = false
        self.textField.isBezeled = false
        self.textField.drawsBackground = false
        self.textField.isEditable = false
        self.textField.font = NSFont.systemFont(ofSize: 19)
        self.textField.textColor = .tertiaryLabelColor
        self.textField.alignment = .center
        setupTextField(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // ---------------------------------------------------------------------
        //  Set initial state to no profile selected
        // ---------------------------------------------------------------------
        updateSelection(count: 0)
    }

    // MARK: -
    // MARK: Public Functions

    public func updateSelection(count: Int) {
        switch count {
        case 0:
            self.textField.stringValue = NSLocalizedString("No Profile Selected", comment: "")
        case 1:
            self.textField.stringValue = NSLocalizedString("\(count) Profile Selected", comment: "")
        default:
            self.textField.stringValue = NSLocalizedString("\(count) Profiles Selected", comment: "")
        }
    }

    // MARK: -
    // MARK: Setup Layout Constraints

    private func setupTextField(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add subview to main view
        // ---------------------------------------------------------------------
        self.view.addSubview(self.textField)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Center Vertically
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))
    }
}
