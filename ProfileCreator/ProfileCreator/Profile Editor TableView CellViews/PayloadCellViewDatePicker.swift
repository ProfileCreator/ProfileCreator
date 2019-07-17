//
//  PayloadCellViewDatePicker.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewDatePicker: PayloadCellView, ProfileCreatorCellView, DatePickerCellView {

    // MARK: -
    // MARK: Instance Variables

    var datePicker: NSDatePicker?
    var textFieldInterval: NSTextField?

    var valueDefault: Date?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        // ---------------------------------------------------------------------
        //  Get settings for the date picker style
        // ---------------------------------------------------------------------
        var showDate = true
        if let dateStyle = subkey.dateStyle {
            showDate = dateStyle == .dateAndTime
        }

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.datePicker = EditorDatePicker.picker(offsetDays: 0, offsetHours: 0, offsetMinutes: 0, showDate: showDate, showTime: true, cellView: self)
        self.setupDatePicker()

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: self.datePicker)

        // ---------------------------------------------------------------------
        //  Get Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.defaultValue() as? Date {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Get Value
        // ---------------------------------------------------------------------
        if let value = profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? Date {
            self.datePicker?.dateValue = value
        } else if let valueDefault = self.valueDefault {
            self.datePicker?.dateValue = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.datePicker
        self.trailingKeyView = self.datePicker

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.datePicker?.isEnabled = enable
    }

    // MARK: -
    // MARK: DatePicker Actions

    internal func selectDate(_ datePicker: NSDatePicker) {
        self.profile.settings.setValue(datePicker.dateValue, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewDatePicker {

    private func setupDatePicker() {

        // ---------------------------------------------------------------------
        //  Add DatePicker to TableCellView
        // ---------------------------------------------------------------------
        guard let datePicker = self.datePicker else { return }
        self.addSubview(datePicker)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: datePicker)

        // Leading
        self.addConstraints(forViewLeading: datePicker)

        // Width
        self.cellViewConstraints.append(NSLayoutConstraint(item: datePicker,
                                                           attribute: .width,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: datePicker.intrinsicContentSize.width))
    }
}
