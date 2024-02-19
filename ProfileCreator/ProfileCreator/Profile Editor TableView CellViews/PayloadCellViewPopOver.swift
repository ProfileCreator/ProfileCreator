//
//  PayloadCellViewPopOver.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2019 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

let kSubstitutionVariablePopOverWidth: CGFloat = 400.0
let kSubstitutionVariablesPopOverWidth: CGFloat = 560.0

class PayloadCellViewPopOver {

    let frame: NSRect

    let popOver = NSPopover()

    init(frame: NSRect, animates: Bool = true) {
        self.frame = frame

        self.popOver.behavior = .transient
        self.popOver.animates = animates
    }

    func showSubstitutionVariables(for subkey: PayloadSubkey, inView cellView: PayloadCellView) {
        self.popOver.contentViewController = PayloadCellViewPopOverViewController(cellView: cellView, subkey: subkey)
        self.popOver.show(relativeTo: self.frame, of: cellView, preferredEdge: .minY)
    }

    func showSubstitutionVariable(inView cellView: NSView) {
        self.popOver.show(relativeTo: self.frame, of: cellView, preferredEdge: .maxY)
    }
}

class PayloadCellViewPopOverViewController: NSViewController {

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(cellView: PayloadCellView, subkey: PayloadSubkey) {
        super.init(nibName: nil, bundle: nil)
        self.view = PayloadCellViewPopOverView(cellView: cellView, subkey: subkey)
    }

    init(variable: String, info: [String: String]) {
        super.init(nibName: nil, bundle: nil)
        self.view = PayloadCellViewPopOverView(variable: variable, info: info)
    }
}

class PayloadCellViewPopOverView: NSView {

    var topSeparator: NSView?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(variable: String, info: [String: String]) {

        // ---------------------------------------------------------------------
        //  Initialize Self
        // ---------------------------------------------------------------------
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Content
        // ---------------------------------------------------------------------
        self.translatesAutoresizingMaskIntoConstraints = false

        var frameHeight: CGFloat = 0.0
        var lastTextField: NSView?

        lastTextField = addTitle(variable,
                                 description: info[ManifestKey.description.rawValue] ?? "-",
                                 below: nil,
                                 height: &frameHeight,
                                 constraints: &constraints)

        if let example = info[ManifestKey.valuePlaceholder.rawValue], !example.isEmpty {
            lastTextField = addTitleWithCodeDescription(NSLocalizedString("Example", comment: ""),
                                                        description: example,
                                                        below: lastTextField,
                                                        height: &frameHeight,
                                                        constraints: &constraints)
        }

        if let source = info[ManifestKey.substitutionSource.rawValue] {
            var sourceTitle = NSLocalizedString("Value Source: ", comment: "")
            var sourceString = "-"
            if source == "local" {
                sourceTitle += NSLocalizedString("Local", comment: "")
                sourceString = NSLocalizedString("This variable is resolved using information from the device.", comment: "")
            } else if source == "mdm" {
                sourceTitle += NSLocalizedString("MDM", comment: "")
                sourceString = NSLocalizedString("This variable is resolved using information from the MDM.", comment: "")
            }
            lastTextField = addTitle(sourceTitle,
                                     description: sourceString,
                                     below: lastTextField,
                                     height: &frameHeight,
                                     constraints: &constraints)
        }

        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 20))

        frameHeight += 20.0

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // ---------------------------------------------------------------------
        //  Set the view frame for use when switching between preference views
        // ---------------------------------------------------------------------
        self.frame = NSRect(x: 0.0, y: 0.0, width: kSubstitutionVariablePopOverWidth, height: frameHeight)
    }

    init(cellView: PayloadCellView, subkey: PayloadSubkey) {

        // ---------------------------------------------------------------------
        //  Initialize Self
        // ---------------------------------------------------------------------
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Verify we got substitution variables
        // ---------------------------------------------------------------------
        guard let substitutionVariables = subkey.substitutionVariables else { return }

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Content
        // ---------------------------------------------------------------------
        self.translatesAutoresizingMaskIntoConstraints = false

        var frameHeight: CGFloat = 0.0
        var lastKey: NSTextField?
        var lastDescription: NSTextField?
        var lastExample: NSTextField?

        (lastKey, lastDescription, lastExample) = self.addRow(key: NSLocalizedString("Substitution Variable", comment: ""),
                                                              description: NSLocalizedString("Description", comment: ""),
                                                              example: NSLocalizedString("Example Value", comment: ""),
                                                              belowKey: nil,
                                                              belowDescription: nil,
                                                              belowExample: nil,
                                                              height: &frameHeight,
                                                              constraints: &constraints)
        lastDescription?.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .bold)
        lastExample?.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .bold)

        self.topSeparator = self.rowSeparator(below: lastKey, height: &frameHeight, constraints: &constraints)

        for (key, value) in Array(substitutionVariables).sorted(by: { $0.0 < $1.0 }) {
            let description = value[ManifestKey.description.rawValue] ?? "-"
            let example = value[ManifestKey.valuePlaceholder.rawValue] ?? "-"
            (lastKey, lastDescription, lastExample) = self.addRow(key: key,
                                                                  description: description,
                                                                  example: example,
                                                                  belowKey: lastKey,
                                                                  belowDescription: lastDescription,
                                                                  belowExample: lastExample,
                                                                  height: &frameHeight,
                                                                  constraints: &constraints)
        }

        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: lastKey,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 20))

        frameHeight += 20.0

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // ---------------------------------------------------------------------
        //  Set the view frame for use when switching between preference views
        // ---------------------------------------------------------------------
        self.frame = NSRect(x: 0.0, y: 0.0, width: kSubstitutionVariablesPopOverWidth, height: frameHeight)
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewPopOverView {
    func rowTextField(stringValue: String, weight: NSFont.Weight) -> NSTextField {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byTruncatingTail
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = true
        textField.textColor = .labelColor
        if weight == .bold {
            textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: weight)
        }
        textField.alignment = .left
        textField.stringValue = stringValue

        return textField
    }

    func rowSeparator(below: NSView?, height: inout CGFloat, constraints: inout [NSLayoutConstraint]) -> NSBox {

        // ---------------------------------------------------------------------
        //  Create and add vertical separator
        // ---------------------------------------------------------------------
        let separator = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 * 2), height: 250.0))
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator
        self.addSubview(separator)

        // ---------------------------------------------------------------------
        //  Add Constraints
        // ---------------------------------------------------------------------

        // Top
        constraints.append(NSLayoutConstraint(item: separator,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: below ?? self,
                                              attribute: below != nil ? .bottom : .top,
                                              multiplier: 1,
                                              constant: 5.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: separator,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 20.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: separator,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 20.0))

        // ---------------------------------------------------------------------
        //  Update height value
        // ---------------------------------------------------------------------
        height += 5.0 + separator.intrinsicContentSize.height

        return separator
    }

    func addTitle(_ title: String, description: String, below: NSView?, height: inout CGFloat, constraints: inout [NSLayoutConstraint]) -> NSTextField? {

        // -------------------------------------------------------------------------
        //  Create and add TextField Title
        // -------------------------------------------------------------------------
        let textFieldTitle = self.rowTextField(stringValue: title, weight: .bold)
        textFieldTitle.lineBreakMode = .byWordWrapping
        self.addSubview(textFieldTitle)

        // Top
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: below ?? self,
                                              attribute: below != nil ? .bottom : .top,
                                              multiplier: 1,
                                              constant: below != nil ? 6.0 : 10.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: below ?? self,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: below != nil ? 0.0 : 20.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 20.0))

        height += (below != nil ? 6.0 : 10.0) + textFieldTitle.intrinsicContentSize.height

        // -------------------------------------------------------------------------
        //  Create and add TextField Description
        // -------------------------------------------------------------------------
        let textFieldDescription = self.rowTextField(stringValue: description, weight: .regular)
        textFieldDescription.lineBreakMode = .byWordWrapping
        textFieldDescription.preferredMaxLayoutWidth = kSubstitutionVariablePopOverWidth - (20.0 + 20.0)
        self.addSubview(textFieldDescription)

        // Top
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 6.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldDescription,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 20.0))

        height += 6.0 + textFieldDescription.intrinsicContentSize.height

        return textFieldDescription
    }

    func addTitleWithCodeDescription(_ title: String, description: String, below: NSView?, height: inout CGFloat, constraints: inout [NSLayoutConstraint]) -> NSTextField? {

        // -------------------------------------------------------------------------
        //  Create and add TextField Title
        // -------------------------------------------------------------------------
        let textFieldTitle = self.rowTextField(stringValue: title, weight: .bold)
        textFieldTitle.lineBreakMode = .byWordWrapping
        self.addSubview(textFieldTitle)

        // Top
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: below ?? self,
                                              attribute: below != nil ? .bottom : .top,
                                              multiplier: 1,
                                              constant: below != nil ? 6.0 : 10.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: below ?? self,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: below != nil ? 0.0 : 20.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 20.0))

        height += (below != nil ? 6.0 : 10.0) + textFieldTitle.intrinsicContentSize.height

        // -------------------------------------------------------------------------
        //  Create and add TextField Description
        // -------------------------------------------------------------------------
        let textFieldDescription = self.rowTextField(stringValue: description, weight: .regular)
        textFieldDescription.lineBreakMode = .byWordWrapping
        textFieldDescription.isBordered = true
        textFieldDescription.isBezeled = false
        textFieldDescription.drawsBackground = true
        textFieldDescription.preferredMaxLayoutWidth = kSubstitutionVariablePopOverWidth - (20.0 + 20.0)
        self.addSubview(textFieldDescription)

        // Top
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 6.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldDescription,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 20.0))

        height += 6.0 + textFieldDescription.intrinsicContentSize.height

        return textFieldDescription
    }

    func addRow(key: String,
                description: String,
                example: String,
                belowKey: NSView?,
                belowDescription: NSView?,
                belowExample: NSView?,
                height: inout CGFloat,
                // swiftlint:disable:next large_tuple
                constraints: inout [NSLayoutConstraint]) -> (NSTextField?, NSTextField?, NSTextField?) {

        // -------------------------------------------------------------------------
        //  Create and add TextField for Column 1
        // -------------------------------------------------------------------------
        let textFieldKey = self.rowTextField(stringValue: key, weight: .bold)
        self.addSubview(textFieldKey)

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldKey,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: belowKey ?? self,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: belowKey != nil ? 0.0 : 20.0))

        // Width
        constraints.append(NSLayoutConstraint(item: textFieldKey,
                                              attribute: .width,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 150.0))

        // -------------------------------------------------------------------------
        //  Create and add TextField for Column 2
        // -------------------------------------------------------------------------
        let textFieldDescription = self.rowTextField(stringValue: description, weight: .regular)
        textFieldDescription.lineBreakMode = .byWordWrapping
        textFieldDescription.preferredMaxLayoutWidth = 250.0
        self.addSubview(textFieldDescription)

        // SUPER weak check
        if (belowKey as? NSTextField)?.stringValue == "Substitution Variable" {
            // Top
            constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: self.topSeparator,
                                                  attribute: .bottom,
                                                  multiplier: 1,
                                                  constant: 8.0))
        } else {
        // Top
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: belowDescription ?? self.topSeparator ?? self,
                                              attribute: belowDescription != nil ? .bottom : .top,
                                              multiplier: 1,
                                              constant: belowDescription != nil ? 6.0 : 10.0))
        }

        // First Baseline
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .firstBaseline,
                                              relatedBy: .equal,
                                              toItem: textFieldKey,
                                              attribute: .firstBaseline,
                                              multiplier: 1,
                                              constant: 0.0))

        if let below = belowDescription {
            // Leading
            constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: below,
                                                  attribute: .leading,
                                                  multiplier: 1,
                                                  constant: 0.0))
        }

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: textFieldKey,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 8.0))

        // Width
        constraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 250.0))

        // -------------------------------------------------------------------------
        //  Create and add TextField for Column 3
        // -------------------------------------------------------------------------
        let textFieldExample = self.rowTextField(stringValue: example, weight: .regular)
        self.addSubview(textFieldExample)

        // First Baseline
        constraints.append(NSLayoutConstraint(item: textFieldExample,
                                              attribute: .firstBaseline,
                                              relatedBy: .equal,
                                              toItem: textFieldKey,
                                              attribute: .firstBaseline,
                                              multiplier: 1,
                                              constant: 0.0))

        if let below = belowExample {
            // Leading
            constraints.append(NSLayoutConstraint(item: textFieldExample,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: below,
                                                  attribute: .leading,
                                                  multiplier: 1,
                                                  constant: 0.0))
        }

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldExample,
                                              attribute: .leading,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: textFieldDescription,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 4.0))

        // Width
        constraints.append(NSLayoutConstraint(item: textFieldExample,
                                              attribute: .width,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 100.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldExample,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 20.0))

        height += (belowDescription != nil ? 6.0 : 10.0) + textFieldDescription.intrinsicContentSize.height

        return (textFieldKey, textFieldDescription, textFieldExample)
    }
}
