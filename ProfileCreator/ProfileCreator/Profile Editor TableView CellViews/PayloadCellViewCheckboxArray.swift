//
//  PayloadCellViewCheckboxArray.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

let kCheckboxArraySpacing: CGFloat = 10.0

class PayloadCellViewCheckboxArray: PayloadCellView, ProfileCreatorCellView, CheckboxCellView {

    // MARK: -
    // MARK: Instance Variables

    private weak var checkboxSubkey: PayloadSubkey?
    var checkboxRangeList = [Any]()

    var checkboxes = [NSButton]()
    var valueDefault: [Any]?

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
        self.setupCheckboxes(subkey: subkey)

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: self.checkboxes.last)

        guard let checkboxSubkey = self.checkboxSubkey else { return }

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueProcessorIdentifier = subkey.valueProcessor, let valueDefault = subkey.valueDefault {
            let valueProcessor = PayloadValueProcessors.shared.processor(withIdentifier: valueProcessorIdentifier, subkey: subkey, inputType: subkey.type, outputType: subkey.typeInput)
            if let valueProcessed = valueProcessor.process(value: valueDefault) as? [Any] {
                self.valueDefault = valueProcessed
            }
        }

        if self.valueDefault == nil, let valueDefault = subkey.valueDefault as? [Any] {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        if
            // let values = self.profile.settings.getPayloadValue(forSubkey: self.subkey, payloadIndex: self.payloadIndex) as? [Any],
            let values = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? [Any],
            let valueIndexes = self.checkboxRangeList.indexes(ofValues: values, ofType: checkboxSubkey.type) {
            for checkbox in self.checkboxes.objectsAtIndexes(indexes: valueIndexes) {
                checkbox.state = .on
            }
        } else if
            let valueDefault = self.valueDefault,
            let valueIndexes = self.checkboxRangeList.indexes(ofValues: valueDefault, ofType: checkboxSubkey.type) {
            for checkbox in self.checkboxes.objectsAtIndexes(indexes: valueIndexes) {
                checkbox.state = .on
            }
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.checkboxes.first
        self.trailingKeyView = self.checkboxes.last

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.checkboxes.forEach { $0.isEnabled = enable }
    }

    // MARK: -
    // MARK: CheckboxCellView Functions

    func clicked(_ checkbox: NSButton) {

        // ---------------------------------------------------------------------
        //  Get all required objects
        // ---------------------------------------------------------------------
        guard
            let checkboxSubkey = self.checkboxSubkey,
            checkbox.tag < self.checkboxRangeList.count else { return }

        // ---------------------------------------------------------------------
        //  Get the current array settings
        // ---------------------------------------------------------------------
        let valueDefault = (self.valueDefault != nil) ? self.valueDefault! : [Any]()
        var arrayContent = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? [Any] ?? valueDefault

        // ---------------------------------------------------------------------
        //  Get the value of the selected checkbox
        // ---------------------------------------------------------------------
        let value = self.checkboxRangeList[checkbox.tag]

        // ---------------------------------------------------------------------
        //  Get the value of the selected checkbox
        // ---------------------------------------------------------------------
        if checkbox.state == .on {
            arrayContent.append(value)
        } else {
            arrayContent.remove(value, ofType: checkboxSubkey.type)
        }

        // self.profile.settings.updatePayloadSettings(value: arrayContent, subkey: self.subkey, payloadIndex: self.payloadIndex)
        self.profile.settings.setValue(arrayContent, forSubkey: subkey, payloadIndex: payloadIndex)

        if self.subkey.isConditionalTarget {
            self.profileEditor.reloadTableView(updateCellViews: true)
        }
    }

    private func setupCheckboxes(subkey: PayloadSubkey) {

        guard
            let checkboxSubkey = subkey.subkeys.first,
            let checkboxRangeList = checkboxSubkey.rangeList else { return }

        self.checkboxSubkey = checkboxSubkey
        self.checkboxRangeList = checkboxRangeList

        var titles = [String]()
        if let rangeListTitles = checkboxSubkey.rangeListTitles {
            titles = rangeListTitles
        }

        if titles.count != checkboxRangeList.count {
            titles = [String]()
            checkboxRangeList.forEach { titles.append(String(describing: $0)) }
        }

        // Create all buttons
        for index in checkboxRangeList.indices {
            self.checkboxes.append(EditorCheckbox.title(titles[index], tag: index, cellView: self))
        }

        // Calculate maximum buttons per row
        var rowItemCount: Int = 0

        // Add indent + trailing spacing as default width
        var width: CGFloat = self.indentValue() + 8.0
        for checkboxWidth in self.checkboxes.compactMap({ $0.intrinsicContentSize.width }).sorted(by: >) {
            if (width + checkboxWidth + (CGFloat(rowItemCount) * kCheckboxArraySpacing)) < kEditorTableViewColumnPayloadWidth {
                width += checkboxWidth
                rowItemCount += 1
            } else {
                break
            }
        }

        var lastCheckbox: NSButton?
        var currentRow: Int = 0
        for (index, checkbox) in self.checkboxes.enumerated() {

            // The index of the item in the current row (0 - (rowItemCount - 1))
            let rowItemIndex = index - (rowItemCount * currentRow)

            // The index of the item above the current item
            let aboveIndex = (rowItemIndex + (rowItemCount * currentRow)) - rowItemCount

            // Setup the current checkbox constraints
            self.setup(checkbox: checkbox,
                       leadingCheckbox: rowItemIndex == 0 ? nil : lastCheckbox,
                       belowCheckbox: aboveIndex < 0 ? nil : self.checkboxes[aboveIndex])

            // If this is the last item in a row, increment currentRow and add a trailing constraing
            if rowItemIndex == (rowItemCount - 1) {
                currentRow += 1

                self.cellViewConstraints.append(NSLayoutConstraint(item: self,
                                                                   attribute: .trailing,
                                                                   relatedBy: .greaterThanOrEqual,
                                                                   toItem: checkbox,
                                                                   attribute: .trailing,
                                                                   multiplier: 1.0,
                                                                   constant: 8.0))

                // If this is the first item in a row after the first, add to the cellView height
            } else if 0 < currentRow, rowItemIndex == 0 {
                self.updateHeight(6.0 + checkbox.intrinsicContentSize.height)
            }

            // Set the current checkbox to lastCheckbox
            lastCheckbox = checkbox
        }
    }

    private func setup(checkbox: NSButton, leadingCheckbox: NSButton?, belowCheckbox: NSButton?) {

        // ---------------------------------------------------------------------
        //  Add Checkbox to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(checkbox)

        // Leading
        if let lCheckbox = leadingCheckbox {
            self.cellViewConstraints.append(NSLayoutConstraint(item: checkbox,
                                                               attribute: .leading,
                                                               relatedBy: .equal,
                                                               toItem: lCheckbox,
                                                               attribute: .trailing,
                                                               multiplier: 1.0,
                                                               constant: kCheckboxArraySpacing))

            self.cellViewConstraints.append(NSLayoutConstraint(item: checkbox,
                                                               attribute: .firstBaseline,
                                                               relatedBy: .equal,
                                                               toItem: lCheckbox,
                                                               attribute: .firstBaseline,
                                                               multiplier: 1.0,
                                                               constant: 0.0))
        } else {

            // If it's the first checkbox in the row
            self.addConstraints(forViewLeading: checkbox)

            // If it's the first checkbox in the first row
            if belowCheckbox == nil {
                self.addConstraints(forViewBelow: checkbox)
            }
        }

        if let topCheckbox = belowCheckbox {

            // Top
            self.cellViewConstraints.append(NSLayoutConstraint(item: checkbox,
                                                               attribute: .top,
                                                               relatedBy: .equal,
                                                               toItem: topCheckbox,
                                                               attribute: .bottom,
                                                               multiplier: 1.0,
                                                               constant: 6.0))

            // Leading
            self.cellViewConstraints.append(NSLayoutConstraint(item: checkbox,
                                                               attribute: .leading,
                                                               relatedBy: .equal,
                                                               toItem: topCheckbox,
                                                               attribute: .leading,
                                                               multiplier: 1.0,
                                                               constant: 0.0))

            // Trailing
            self.cellViewConstraints.append(NSLayoutConstraint(item: checkbox,
                                                               attribute: .trailing,
                                                               relatedBy: .equal,
                                                               toItem: topCheckbox,
                                                               attribute: .trailing,
                                                               multiplier: 1.0,
                                                               constant: 0.0))
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewCheckbox {

    private func setupCheckbox() {

        guard let checkbox = self.checkbox else { return }
        self.addSubview(checkbox)

        // ---------------------------------------------------------------------
        //  Update leading constraints for TextField Title
        // ---------------------------------------------------------------------
        self.updateConstraints(forViewLeadingTitle: checkbox)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Leading
        self.addConstraints(forViewLeading: checkbox)

        // Width
        self.cellViewConstraints.append(NSLayoutConstraint(item: checkbox,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: checkbox.intrinsicContentSize.width))
    }
}
