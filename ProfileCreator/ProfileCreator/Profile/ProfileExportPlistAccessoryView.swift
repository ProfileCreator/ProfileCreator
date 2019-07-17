//
//  ProfileExportAccessoryView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ProfileExportPlistAccessoryView: NSView {

    // MARK: -
    // MARK: Variables

    var textFieldHeaderMDMInformation = NSTextField()
    var boxMessage = NSBox()

    // MARK: -
    // MARK: Weak Variables

    weak var profile: Profile?
    weak var exportSettings: ProfileSettings?

    // MARK: -
    // MARK: Initialization

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile, exportSettings: ProfileSettings) {

        // ---------------------------------------------------------------------
        //  Initialize Self
        // ---------------------------------------------------------------------
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile
        self.exportSettings = exportSettings

        var constraints = [NSLayoutConstraint]()
        var frameHeight: CGFloat = 0.0
        let centerView = NSView()
        var lastSubview: NSView?

        // ---------------------------------------------------------------------
        //  Add Export Information
        // ---------------------------------------------------------------------

        if let box = addBox(title: "",
                            toView: centerView,
                            lastSubview: lastSubview,
                            lastTextField: nil,
                            height: &frameHeight,
                            indent: kExportPreferencesIndent,
                            constraints: &constraints) {
            lastSubview = box

            var boxTextString = "The following domains will be exported to the selected folder:"
            for payload in exportSettings.payloadsEnabled() {
                boxTextString += "\n\t• " + payload.domainIdentifier
            }

            if let boxText = addHeader(title: boxTextString,
                                       withSeparator: false,
                                       toView: box,
                                       lastSubview: nil,
                                       height: &frameHeight,
                                       constraints: &constraints) as? NSTextField {

                boxText.lineBreakMode = .byWordWrapping
                boxText.preferredMaxLayoutWidth = kExportPreferencesViewWidth - (kExportPreferencesIndent + 20.0)

                // ---------------------------------------------------------------------
                //  Add constraints to last view
                // ---------------------------------------------------------------------
                // Bottom
                constraints.append(NSLayoutConstraint(item: box,
                                                      attribute: .bottom,
                                                      relatedBy: .equal,
                                                      toItem: boxText,
                                                      attribute: .bottom,
                                                      multiplier: 1,
                                                      constant: 8.0))
            }
        }

        // ---------------------------------------------------------------------
        //  Add constraints to last view
        // ---------------------------------------------------------------------
        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: lastSubview,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 12.0))

        // ---------------------------------------------------------------------
        //  Add subviews to accessory view
        // ---------------------------------------------------------------------
        self.setup(centerView: centerView, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // Height
        NSLayoutConstraint.activate([NSLayoutConstraint(item: self,
                                                        attribute: .height,
                                                        relatedBy: .equal,
                                                        toItem: nil,
                                                        attribute: .notAnAttribute,
                                                        multiplier: 1,
                                                        constant: self.fittingSize.height)])
    }
}

extension ProfileExportPlistAccessoryView {
    func setup(centerView: NSView, constraints: inout [NSLayoutConstraint]) {

        centerView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(centerView)

        // Leading
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: centerView,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: centerView,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0.0))

        // Top
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: centerView,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: centerView,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0.0))
    }
}
