//
//  PayloadCellViewPopUpButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewPopUpButtonSegments: PayloadCellView, ProfileCreatorCellView, PopUpButtonCellView, NSMenuDelegate {

    // MARK: -
    // MARK: Instance Variables

    var popUpButton: NSPopUpButton?
    var textFieldUnit: NSTextField?
    var valueDefault: Any?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        // ---------------------------------------------------------------------
        //  Clear out all previous views as we will not need them, but we need to be a PayloadCellView so this was easiest. Could rework this if more views like this special view is introduced.
        // ---------------------------------------------------------------------
        if let textFieldTitle = self.textFieldTitle {
            textFieldTitle.removeFromSuperview()
            self.textFieldTitle = nil
        }

        if let textFieldDescription = self.textFieldDescription {
            textFieldDescription.removeFromSuperview()
            self.textFieldDescription = nil
        }

        if let textFieldMessage = self.textFieldMessage {
            textFieldMessage.removeFromSuperview()
            self.textFieldMessage = nil
        }

        self.height = 0
        self.cellViewConstraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        // TextField Description
        self.setupTextField(description: NSLocalizedString("Please select a category to show it's settings", comment: ""))

        // PopUpButton
        var titles = [String]()
        if let rangeListTitles = subkey.rangeListTitles {
            titles = rangeListTitles
        } else if let rangeList = subkey.rangeList {
            rangeList.forEach { titles.append(String(describing: $0)) }
        }
        self.popUpButton = EditorPopUpButton.withTitles(titles: titles, cellView: self)
        self.setupPopUpButton()

        // Separator Left
        let separatorLeft = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 + 20.0), height: 250.0))
        separatorLeft.translatesAutoresizingMaskIntoConstraints = false
        separatorLeft.boxType = .separator
        self.setup(separator: separatorLeft, alignment: .left)

        // Separator Right
        let separatorRight = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 + 20.0), height: 250.0))
        separatorRight.translatesAutoresizingMaskIntoConstraints = false
        separatorRight.boxType = .separator
        self.setup(separator: separatorRight, alignment: .right)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.defaultValue() {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Get Value
        // ---------------------------------------------------------------------
        let value: String?
        if let valueUser = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? String {
            value = valueUser
        } else if let valueDefault = self.valueDefault as? String {
            value = valueDefault
        } else {
            value = self.popUpButton?.itemTitles.first
        }

        // ---------------------------------------------------------------------
        //  Select Value
        // ---------------------------------------------------------------------
        if let selectedTitle = value, self.popUpButton!.itemTitles.contains(selectedTitle) {
            self.popUpButton!.selectItem(withTitle: selectedTitle)
        }

        // ---------------------------------------------------------------------
        //  Add spacing to bottom
        // ---------------------------------------------------------------------
        self.updateHeight(14.0)

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.popUpButton
        self.trailingKeyView = self.popUpButton

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.popUpButton?.isEnabled = enable
    }

    // MARK: -
    // MARK: PopUpButton Functions

    func selected(_ popUpButton: NSPopUpButton) {
        if
            let selectedTitle = popUpButton.titleOfSelectedItem,
            let selectedValue = PayloadUtility.value(forRangeListTitle: selectedTitle, subkey: self.subkey) {

            self.profile.settings.setValue(selectedValue, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            self.profileEditor.reloadTableView(updateCellViews: true)
        } else {
            Log.shared.error(message: "Subkey: \(self.subkey.keyPath) Failed to get value for selected title: \(String(describing: popUpButton.titleOfSelectedItem)) ", category: String(describing: self))
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewPopUpButtonSegments {

    private func setupPopUpButton() {

        // ---------------------------------------------------------------------
        //  Add PopUpButton to TableCellView
        // ---------------------------------------------------------------------
        guard let popUpButton = self.popUpButton else { return }

        popUpButton.isBordered = false
        popUpButton.font = NSFont.systemFont(ofSize: 20, weight: .bold)

        self.addSubview(popUpButton)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        self.cellViewConstraints.append(NSLayoutConstraint(item: popUpButton,
                                                           attribute: .top,
                                                           relatedBy: .equal,
                                                           toItem: self.textFieldDescription,
                                                           attribute: .bottom,
                                                           multiplier: 1.0,
                                                           constant: 6.0))
        self.updateHeight(6 + popUpButton.intrinsicContentSize.height)

/*
        self.cellViewConstraints.append(NSLayoutConstraint(item: popUpButton,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 8.0))
        self.updateHeight(8 + popUpButton.intrinsicContentSize.height)
*/
        // Center X
        self.cellViewConstraints.append(NSLayoutConstraint(item: popUpButton,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: popUpButton,
                                              attribute: .leading,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // Trailing
        self.cellViewConstraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: popUpButton,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))
    }

    private func setupTextField(description: String) {

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

        self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldDescription,
                                                           attribute: .top,
                                                           relatedBy: .equal,
                                                           toItem: self,
                                                           attribute: .top,
                                                           multiplier: 1.0,
                                                           constant: 8.0))
        self.updateHeight(8 + textFieldDescription.intrinsicContentSize.height)
/*
        if let popUpButton = self.popUpButton {
            self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldDescription,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: popUpButton,
                                                  attribute: .bottom,
                                                  multiplier: 1.0,
                                                  constant: 6.0))
            self.updateHeight(6 + textFieldDescription.intrinsicContentSize.height)
        } else {
            self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldDescription,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .top,
                                                  multiplier: 1.0,
                                                  constant: 8.0))
            self.updateHeight(8 + textFieldDescription.intrinsicContentSize.height)
        }
*/
        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldDescription,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // Trailing
        self.cellViewConstraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldDescription,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))
    }

    private func setup(separator: NSBox, alignment: NSLayoutConstraint.Attribute) {

        guard let popUpButton = self.popUpButton else { return }

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(separator)

        // Center Y
        self.cellViewConstraints.append(NSLayoutConstraint(item: separator,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: popUpButton,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0.0))

        if alignment == .left {

            // Leading
            self.cellViewConstraints.append(NSLayoutConstraint(item: separator,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .leading,
                                                  multiplier: 1,
                                                  constant: 8.0))

            // Trailing
            self.cellViewConstraints.append(NSLayoutConstraint(item: popUpButton,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: separator,
                                                  attribute: .trailing,
                                                  multiplier: 1,
                                                  constant: 8.0))
        } else {

            // Leading
            self.cellViewConstraints.append(NSLayoutConstraint(item: separator,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: popUpButton,
                                                  attribute: .trailing,
                                                  multiplier: 1,
                                                  constant: 8.0))

            // Trailing
            self.cellViewConstraints.append(NSLayoutConstraint(item: separator,
                                                  attribute: .trailing,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .trailing,
                                                  multiplier: 1,
                                                  constant: 8.0))

        }
    }
}
