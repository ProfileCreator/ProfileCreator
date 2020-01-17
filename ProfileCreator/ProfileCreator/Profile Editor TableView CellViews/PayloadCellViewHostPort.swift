//
//  PayloadCellViewHostPort.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewHostPort: PayloadCellView, ProfileCreatorCellView, NSTextFieldDelegate {

    // MARK: -
    // MARK: Instance Variables

    var textFieldHost: PayloadTextField?
    var textFieldPort: PayloadTextField?
    var constraintPortTrailing: NSLayoutConstraint?
    @objc var valuePort: NSNumber?

    var isEditingHost: Bool = false
    var isEditingPort: Bool = false
    var valueBeginEditingHost: String?
    var valueBeginEditingPort: String?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.textFieldHost = EditorTextField.input(defaultString: "", placeholderString: "Host", cellView: self)
        self.setupTextField(host: self.textFieldHost!)
        self.textFieldPort = EditorTextField.input(defaultString: "", placeholderString: "Port", cellView: self)
        self.setupTextField(port: self.textFieldPort!)
        _ = EditorTextField.label(string: ":", fontWeight: .regular, leadingItem: self.textFieldHost!, leadingConstant: nil, trailingItem: self.textFieldPort!, constraints: &self.cellViewConstraints, cellView: self)

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.textFieldHost
        self.trailingKeyView = self.textFieldPort

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.textFieldHost?.isEnabled = enable
        self.textFieldHost?.isSelectable = enable
        self.textFieldPort?.isEnabled = enable
        self.textFieldPort?.isSelectable = enable
    }
}

// MARK: -
// MARK: NSControl Functions

extension PayloadCellViewHostPort {

    internal func controlTextDidBeginEditing(_ obj: Notification) {

        guard
            let textField = obj.object as? NSTextField,
            let userInfo = obj.userInfo,
            let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
            let originalString = fieldEditor.textStorage?.string else {
                return
        }

        if textField == self.textFieldHost {
            self.isEditingHost = true
            self.valueBeginEditingHost = originalString
        } else if textField == self.textFieldPort {
            self.isEditingPort = true
            self.valueBeginEditingPort = originalString
        }
    }

    internal func controlTextDidEndEditing(_ obj: Notification) {

        if !isEditingHost && !isEditingPort { return }

        guard
            let textField = obj.object as? NSTextField,
            let userInfo = obj.userInfo,
            let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
            let newString = fieldEditor.textStorage?.string else {
                if isEditingHost {
                    self.isEditingHost = false
                } else if isEditingPort {
                    self.isEditingPort = false
                }
                return
        }

        if textField == self.textFieldHost, newString != self.valueBeginEditingHost {
            // self.profile.settings.updatePayloadSettings(value: newString, subkey: self.subkey, payloadIndex: self.payloadIndex)
            self.profile.settings.setValue(newString, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            self.isEditingHost = false
        } else if textField == self.textFieldPort, newString != self.valueBeginEditingPort {
            // self.profile.settings.updatePayloadSettings(value: newString, subkey: self.subkey, payloadIndex: self.payloadIndex)
            self.profile.settings.setValue(newString, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            self.isEditingPort = false
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewHostPort {

    private func setupTextField(host: NSTextField) {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(host)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: host)

        // Leading
        self.addConstraints(forViewLeading: host)
    }

    private func setupTextField(port: NSTextField) {

        // ---------------------------------------------------------------------
        //  Add Number Formatter to TextField
        // ---------------------------------------------------------------------
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        numberFormatter.minimum = 1
        numberFormatter.maximum = 65_535
        port.formatter = numberFormatter
        port.bind(.value, to: self, withKeyPath: "valuePort", options: [NSBindingOption.nullPlaceholder: "Port", NSBindingOption.continuouslyUpdatesValue: true])

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(port)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Width (fixed size to fit 5 characters: 49.0)
        self.cellViewConstraints.append(NSLayoutConstraint(item: port,
                                                           attribute: .width,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: 49.0))

        // Trailing
        self.constraintPortTrailing = NSLayoutConstraint(item: self,
                                                         attribute: .trailing,
                                                         relatedBy: .equal,
                                                         toItem: port,
                                                         attribute: .trailing,
                                                         multiplier: 1.0,
                                                         constant: 8.0)

        self.cellViewConstraints.append(self.constraintPortTrailing!)
    }

}
