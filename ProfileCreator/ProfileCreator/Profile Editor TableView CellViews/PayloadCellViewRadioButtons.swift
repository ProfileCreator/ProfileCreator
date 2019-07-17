//
//  PayloadCellViewCheckbox.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewRadioButtons: PayloadCellView, ProfileCreatorCellView, RadioButtonsCellView {

    // MARK: -
    // MARK: Instance Variables

    var buttons = [NSButton]()
    var valueDefault: Bool = false
    var valueInverted: Bool = false

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        guard let titles = subkey.rangeListTitles else { return }

        // Add all Radio Buttons
        if subkey.type == .bool {

            // ---------------------------------------------------------------------
            //  Set Value Inverted
            // ---------------------------------------------------------------------
            self.valueInverted = subkey.valueInverted

            guard titles.count == 2 else {
                Log.shared.error(message: "Boolean radio buttons require exactly 2 titles in the pfm_range_list_titles key. Currently it has \(titles.count): \(titles)", category: String(describing: self))
                return
            }
        }

        for (index, title) in titles.enumerated() {
            self.buttons.append(EditorRadioButton.withTitle(title: title, index: index, identifier: NSUserInterfaceItemIdentifier(rawValue: subkey.keyPath), cellView: self))
        }

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.setupRadioButtons()

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: buttons.last)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.valueDefault as? Bool {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        var value = self.valueDefault
        // if let payloadValue = self.profile.settings.getPayloadValue(forKeyPath: subkey.keyPath, domain: subkey.domain, type: subkey.payloadType, payloadIndex: payloadIndex) as? Bool {
        if let payloadValue = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? Bool {
            value = payloadValue
        }

        let index = self.tag(forValue: value)
        if index < self.buttons.count {
            let button = self.buttons[index]
            button.state = .on
        } else {
            Log.shared.error(message: "Selected index is not in range of the radio buttons count", category: String(describing: self))
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.buttons.first
        self.trailingKeyView = self.buttons.last

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: Value Inverted Functions

    func tag(forValue value: Bool) -> Int {
        if self.valueInverted {
            return value ? 0 : 1
        } else {
            return value ? 1 : 0
        }
    }

    func value(forTag tag: Int) -> Bool {
        if self.valueInverted {
            return tag == 0 ? true : false
        } else {
            return tag == 0 ? false : true
        }
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        for button in self.buttons {
            button.isEnabled = enable
        }
    }

    // MARK: -
    // MARK: CheckboxCellView Functions

    func clicked(_ radioButton: NSButton) {

        if self.subkey.type == .bool {
            // self.profile.settings.updatePayloadSettings(value: self.value(forTag: radioButton.tag), subkey: self.subkey, payloadIndex: self.payloadIndex)
            self.profile.settings.setValue(self.value(forTag: radioButton.tag), forSubkey: self.subkey, payloadIndex: self.payloadIndex)
        }

        if self.subkey.isConditionalTarget {
            self.profileEditor.reloadTableView(updateCellViews: true)
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewRadioButtons {

    private func setupRadioButtons() {

        // ---------------------------------------------------------------------
        //  Add Buttons to to TableCellView
        // ---------------------------------------------------------------------
        var lastButton: NSButton?
        for radioButton in self.buttons {

            self.addSubview(radioButton)

            // ---------------------------------------------------------------------
            //  Update leading constraints for TextField Title
            // ---------------------------------------------------------------------
            if let lastRadioButton = lastButton {

                // Leading
                self.cellViewConstraints.append(NSLayoutConstraint(item: lastRadioButton,
                                                                   attribute: .leading,
                                                                   relatedBy: .equal,
                                                                   toItem: radioButton,
                                                                   attribute: .leading,
                                                                   multiplier: 1.0,
                                                                   constant: 0.0))

                // Top
                self.cellViewConstraints.append(NSLayoutConstraint(item: radioButton,
                                                                   attribute: .top,
                                                                   relatedBy: .equal,
                                                                   toItem: lastRadioButton,
                                                                   attribute: .bottom,
                                                                   multiplier: 1.0,
                                                                   constant: 4.0))

                self.updateHeight(4.0 + radioButton.intrinsicContentSize.height)
            } else {
                // Below
                self.addConstraints(forViewBelow: radioButton)

                // Leading
                self.addConstraints(forViewLeading: radioButton)
            }

            // Trailing
            self.addConstraints(forViewTrailing: radioButton)

            lastButton = radioButton
        }
    }
}
