//
//  TableCellViewTextField.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewTextFieldNumber: PayloadCellView, ProfileCreatorCellView, NSTextFieldDelegate {

    // MARK: -
    // MARK: Instance Variables

    var textFieldInput: PayloadTextField?
    var textFieldMinMax: NSTextField?
    var textFieldUnit: NSTextField?

    var valueDefault: NSNumber?
    @objc private var value: Any?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        var leadingTextField: NSTextField

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.textFieldInput = EditorTextField.input(defaultString: "", placeholderString: "", cellView: self)
        self.setupTextFieldInput()

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: self.textFieldInput)

        leadingTextField = self.textFieldInput!

        // If a min and max value is set, then show that trailing the input field
        if let rangeMin = subkey.rangeMin, let rangeMax = subkey.rangeMax {
            let rangeString = "\(String(describing: rangeMin)) - \(String(describing: rangeMax))"
            self.textFieldMinMax = EditorTextField.label(string: "(\(rangeString))",
                fontWeight: .regular,
                leadingItem: leadingTextField,
                leadingConstant: 7.0,
                trailingItem: nil,
                constraints: &self.cellViewConstraints,
                cellView: self)
            self.setupTextFieldMinMax()
            leadingTextField = self.textFieldMinMax!
        }

        if let valueUnit = subkey.valueUnit {
            self.textFieldUnit = EditorTextField.label(string: valueUnit, fontWeight: .regular, leadingItem: leadingTextField, leadingConstant: 7.0, trailingItem: nil, constraints: &self.cellViewConstraints, cellView: self)
            self.setupTextFieldUnit()
        }

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.valueDefault as? NSNumber {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Placeholder Value
        // ---------------------------------------------------------------------
        if let valuePlaceholder = subkey.valuePlaceholder {
            // FIXME: This double check could probably be done better
            if let valueNumber = valuePlaceholder as? NSNumber {
                self.textFieldInput?.placeholderString = self.stringValue(valueNumber, forType: subkey.typeInput)
            } else if let valueString = valuePlaceholder as? String {
                self.textFieldInput?.placeholderString = valueString
            } else {
                // FIXME: Correct Error
            }
        } else if self.isRequired {
            self.textFieldInput?.placeholderString = NSLocalizedString("Required", comment: "")
        }

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        if let value = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? NSNumber {
            self.textFieldInput?.stringValue = self.stringValue(value, forType: subkey.typeInput)
        } else if let valueDefault = self.valueDefault {
            self.textFieldInput?.stringValue = self.stringValue(valueDefault, forType: subkey.typeInput)
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.textFieldInput
        self.trailingKeyView = self.textFieldInput

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.textFieldInput?.isEnabled = enable
        self.textFieldInput?.isSelectable = enable
    }

    func stringValue(_ value: NSNumber, forType type: PayloadValueType) -> String {
        if type == .integer {
            return String(describing: value.intValue)
        } else if type == .float {
            var string = String(describing: value.doubleValue)
            if let decimalSeparator = Locale.current.decimalSeparator {
                if decimalSeparator != "." {
                    string = string.replacingOccurrences(of: ".", with: decimalSeparator)
                }
            }
            return string
        } else {
            return value.stringValue
        }
    }
}

// MARK: -
// MARK: NSControl Functions

extension PayloadCellViewTextFieldNumber {

    internal func controlTextDidChange(_ obj: Notification) {
        self.isEditing = true
        if
            let userInfo = obj.userInfo,
            let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
            let newString = fieldEditor.textStorage?.string {

            self.textFieldInput?.highlighSubstrings(for: self.subkey)

            self.setValue(newString)
        }
    }

    internal func controlTextDidEndEditing(_ obj: Notification) {
        if self.isEditing {
            self.isEditing = false
            if
                let userInfo = obj.userInfo,
                let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
                let newString = fieldEditor.textStorage?.string {

                self.textFieldInput?.highlighSubstrings(for: self.subkey)

                self.setValue(newString)
            }
        }
    }

    internal func setValue(_ value: String) {
        switch self.subkey.typeInput {
        case .float:
            if let doubleValue = value.doubleValue {
                self.profile.settings.setValue(NSNumber(value: doubleValue), forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            }
        case .integer:
            if let intValue = Int(value) {
                self.profile.settings.setValue(NSNumber(value: intValue), forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            }
        default:
            Log.shared.error(message: "Subkey type: \(subkey.type) is not supported in a TextFieldNumber CellView", category: String(describing: self))
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewTextFieldNumber {

    private func setupTextFieldInput() {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        guard let textFieldInput = self.textFieldInput else { return }
        self.addSubview(textFieldInput)

        // ---------------------------------------------------------------------
        //  Add Number Formatter to TextField
        // ---------------------------------------------------------------------
        let numberFormatter = NumberFormatter()

        if self.subkey.type == .float {
            numberFormatter.allowsFloats = true
            numberFormatter.numberStyle = .decimal
        } else {
            numberFormatter.numberStyle = .none
        }

        if let rangeMax = self.subkey.rangeMax as? NSNumber {
            numberFormatter.maximum = rangeMax
        } else {
            numberFormatter.maximum = Int.max as NSNumber
        }

        if let rangeMin = self.subkey.rangeMin as? NSNumber {
            numberFormatter.minimum = rangeMin
        } else {
            numberFormatter.minimum = Int.min as NSNumber
        }

        if let decimalPlaces = self.subkey.valueDecimalPlaces {
            numberFormatter.maximumFractionDigits = decimalPlaces
            numberFormatter.minimumFractionDigits = decimalPlaces
        } else {
            numberFormatter.maximumFractionDigits = 15 // This is the default in plist <real> tags. which is a double.
        }

        textFieldInput.formatter = numberFormatter
        textFieldInput.bind(.value, to: self, withKeyPath: "value", options: [NSBindingOption.nullPlaceholder: "", NSBindingOption.continuouslyUpdatesValue: true])

        // ---------------------------------------------------------------------
        //  Get TextField Number Maximum Width
        // ---------------------------------------------------------------------

        // FIXME: Just set it to a static width right now, same as Int.max. But this needs to be dynamic!
        // Width
        self.cellViewConstraints.append(NSLayoutConstraint(item: textFieldInput,
                                                           attribute: .width,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: 184.0))

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: textFieldInput)

        // Leading
        self.addConstraints(forViewLeading: textFieldInput)
    }

    private func setupTextFieldMinMax() {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        guard let textFieldMinMax = self.textFieldMinMax else { return }

        textFieldMinMax.textColor = .secondaryLabelColor
    }

    private func setupTextFieldUnit() {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        guard let textFieldUnit = self.textFieldUnit else { return }

        textFieldUnit.textColor = .secondaryLabelColor

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        if let textFieldMinMax = self.textFieldMinMax {
            if let index = self.cellViewConstraints.firstIndex(where: {
                if let secondItem = $0.secondItem as? NSTextField, secondItem == textFieldMinMax, $0.secondAttribute == .trailing {
                    return true
                }
                return false
            }) {
                self.cellViewConstraints.remove(at: index)
                textFieldMinMax.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            }
        }
    }
}
