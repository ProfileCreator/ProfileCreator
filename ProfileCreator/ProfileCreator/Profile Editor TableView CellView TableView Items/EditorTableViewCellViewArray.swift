//
//  EditorTableViewCellViewArray.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class EditorTableViewCellViewArray: NSTableCellView {

    // MARK: -
    // MARK: Variables

    let popOver = NSPopover()
    var popOverViewController: EditorTableViewCellViewArrayViewController?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(cellView: PayloadCellViewTableView, subkey: PayloadSubkey, keyPath: String, value: [Any], row: Int) {
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup PopOver
        // ---------------------------------------------------------------------
        self.popOverViewController = EditorTableViewCellViewArrayViewController(cellView: cellView,
                                                                                subkey: subkey,
                                                                                keyPath: keyPath,
                                                                                value: value,
                                                                                row: row)
        self.setupPopOver(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Setup TextField
        // ---------------------------------------------------------------------
        self.setupTextField(constraints: &constraints)
        if let lastSubkey = subkey.subkeys.last, let placeholderValue = lastSubkey.valuePlaceholder {
            self.textField?.placeholderString = String(describing: placeholderValue)
        }
        // if let tableViewContent = cellView.tableViewContent as? [[String: Any]], let value = tableViewContent[row][subkey.keyPath] as? [Any] {
        self.textField?.stringValue = value.compactMap { String(describing: $0) }.joined(separator: ", ")
        // }
        self.textField?.delegate = cellView
        self.textField?.tag = row
        self.textField?.identifier = NSUserInterfaceItemIdentifier(rawValue: keyPath)

        // ---------------------------------------------------------------------
        //  Add Notification Observers
        // ---------------------------------------------------------------------
        if let arrayView = self.popOverViewController?.view as? EditorTableViewCellViewArrayView {
            arrayView.addObserver(self, forKeyPath: arrayView.tableViewContentSelector, options: .new, context: nil)
        }

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    deinit {
        if let arrayView = self.popOverViewController?.view as? EditorTableViewCellViewArrayView {
            arrayView.removeObserver(self, forKeyPath: arrayView.tableViewContentSelector, context: nil)
        }
    }

    // MARK: -
    // MARK: Gesture Functions

    @objc func showArrayInput(_ textField: NSTextField) {
        self.popOver.show(relativeTo: self.bounds, of: self, preferredEdge: .minY)
        if
            let arrayView = self.popOverViewController?.view as? EditorTableViewCellViewArrayView,
            let tableView = arrayView.tableView {

            self.window?.makeFirstResponder(tableView)

            if arrayView.tableViewContent.isEmpty {
                arrayView.addRow()
            }

            if let index = arrayView.indexOfEmptyRow() {
                tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                    if let rowView = tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? NSTableCellView {
                        rowView.textField?.selectText(self)
                    }
                }
            } else {
                tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            }
        }
    }

    // MARK: -
    // MARK: Key/Value Observing Functions

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let value = change?[.newKey] as? [Any] {
            self.textField?.stringValue = value.compactMap { String(describing: $0) }.joined(separator: ", ")
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension EditorTableViewCellViewArray {
    private func setupPopOver(constraints: inout [NSLayoutConstraint]) {
        self.popOver.behavior = .transient
        self.popOver.animates = true
        self.popOver.contentViewController = self.popOverViewController
    }

    private func setupTextField(constraints: inout [NSLayoutConstraint]) {
        let textField = PayloadTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byTruncatingTail
        textField.isBordered = false
        textField.isBezeled = false
        textField.bezelStyle = .squareBezel
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = true
        textField.textColor = .labelColor
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        self.addSubview(textField)
        self.textField = textField

        // ---------------------------------------------------------------------
        //  Setup GestureRecognizer
        // ---------------------------------------------------------------------
        let gesture = NSClickGestureRecognizer()
        gesture.buttonMask = 0x2 // Right click to show array input
        gesture.target = self
        gesture.action = #selector(self.showArrayInput(_:))
        textField.addGestureRecognizer(gesture)

        // CenterY
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 2.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textField,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 2.0))

    }
}

class EditorTableViewCellViewArrayViewController: NSViewController {

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(cellView: PayloadCellViewTableView, subkey: PayloadSubkey, keyPath: String, value: [Any], row: Int) {
        super.init(nibName: nil, bundle: nil)
        self.view = EditorTableViewCellViewArrayView(cellView: cellView, subkey: subkey, keyPath: keyPath, value: value, row: row)
    }
}

class EditorTableViewCellViewArrayView: NSView, TableViewCellView, NSComboBoxDelegate {

    // MARK: -
    // MARK: Instance Variables

    unowned var profile: Profile
    unowned var subkey: PayloadSubkey
    unowned var cellView: PayloadCellViewTableView
    let row: Int
    var scrollView: NSScrollView?
    var tableView: NSTableView?

    @objc dynamic var tableViewContent = [Any]()
    let tableViewContentSelector: String

    var tableViewColumns = [PayloadSubkey]()
    var tableViewContentSubkey: PayloadSubkey?
    var tableViewContentType: PayloadValueType = .undefined

    var valueDefault: [[String: Any]]?
    let buttonAdd = NSButton()
    let buttonRemove = NSButton()
    let containerView = ViewWhite(acceptsFirstResponder: false) // NSView()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(cellView: PayloadCellViewTableView, subkey: PayloadSubkey, keyPath: String, value: [Any], row: Int) {

        self.row = row
        self.subkey = subkey
        self.cellView = cellView
        self.profile = cellView.profile

        // ---------------------------------------------------------------------
        //  Set Value Type
        // ---------------------------------------------------------------------
        if subkey.typeInput == .dictionary {
            self.tableViewContentSubkey = subkey
        } else if subkey.typeInput == .array {
            self.tableViewContentSubkey = subkey.subkeys.first
        }
        self.tableViewContentType = self.tableViewContentSubkey?.type ?? .undefined

        // ---------------------------------------------------------------------
        //  Initialize Key/Value Observing Selector Strings
        // ---------------------------------------------------------------------
        self.tableViewContentSelector = NSStringFromSelector(#selector(getter: self.tableViewContent))

        // ---------------------------------------------------------------------
        //  Initialize Self
        // ---------------------------------------------------------------------
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.scrollView = EditorTableView.scrollView(height: 109.0, constraints: &constraints, target: self, cellView: self.containerView)
        if let tableView = self.scrollView?.documentView as? NSTableView { self.tableView = tableView }
        self.setupScrollView(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Setup Content
        // ---------------------------------------------------------------------
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupTableViewContent(subkey: subkey)
        self.setupContainerView(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Setup Button Add/Remove
        // ---------------------------------------------------------------------
        self.setupButtonAdd(constraints: &constraints)
        self.setupButtonRemove(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.valueDefault as? [[String: Any]] {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        self.setValue(value, forKey: self.tableViewContentSelector)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // ---------------------------------------------------------------------
        //  Reload TableView
        // ---------------------------------------------------------------------
        self.tableView?.reloadData()
    }

    // MARK: -
    // MARK: Button Actions

    @objc private func clicked(_ button: NSButton) {
        if button.tag == 0 {
            self.addRow()
        } else if button.tag == 1, let selectedRow = self.tableView?.selectedRow {
            self.removeRow(index: selectedRow)
        }
    }

    // MARK: -
    // MARK: Private Functions

    private func newRowValue() -> Any? {
        if let rangeList = self.tableViewContentSubkey?.rangeList, let newRowValue = rangeList.first(where: { !self.tableViewContent.containsAny(value: $0, ofType: self.tableViewContentType) }) {
            return newRowValue
        } else if let newRowValue = self.tableViewContentSubkey?.defaultValue() ?? PayloadUtility.emptyValue(valueType: self.tableViewContentType) {
            return newRowValue
        }
        return nil
    }

    func indexOfEmptyRow() -> Int? {
        guard let tableViewColumn = self.tableViewColumns.first else { return nil }
        return self.tableViewContent.firstIndex {
            switch tableViewColumn.type {
            case .bool:
                return $0 as? Bool == self.newRowValue() as? Bool
            case .integer:
                return $0 as? Int == self.newRowValue() as? Int
            case .string:
                return $0 as? String == self.newRowValue() as? String
            default:
                return false
            }
        }
    }

    func addRow() {

        // Verify there isn't a limit on maximum number or items in the array.
        if let repetitionMax = self.subkey.repetitionMax {
            if repetitionMax <= self.tableViewContent.count {
                // FIXME: This must be notified to the user
                Log.shared.info(message: "Only \(repetitionMax) rows are allowd in the array for subkey: \(self.subkey.keyPath)", category: String(describing: self))
                return
            }
        }

        // Verify the values unique is set and if all values are already set
        if self.tableViewContentType != .dictionary, self.tableViewContentSubkey?.valueUnique ?? false {
            if let subkey = self.tableViewContentSubkey, let rangeList = subkey.rangeList, self.tableViewContent.contains(values: rangeList, ofType: subkey.type, sorted: true) {
                Log.shared.info(message: "All supported values are already in the array, cannot create another row because values must be unique", category: String(describing: self))
                return
            }
        }

        guard let newRow = self.newRowValue() else { return }

        self.tableViewContent.append(newRow)
        self.cellView.setValue(self.tableViewContent, forSubkey: self.subkey, row: self.row)
        self.setValue(self.tableViewContent, forKey: self.tableViewContentSelector)

        self.tableView?.reloadData()

        let newRowIndex = self.tableViewContent.count - 1

        if self.tableViewContentType == .string {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                if let rowView = self.tableView?.view(atColumn: 0, row: newRowIndex, makeIfNecessary: false) as? NSTableCellView {
                    rowView.textField?.selectText(self)
                }
            }
        }

        self.tableView?.selectRowIndexes(IndexSet(integer: newRowIndex), byExtendingSelection: false)
        self.tableView?.scrollRowToVisible(newRowIndex)
    }

    private func removeRow(index: Int) {
        guard 0 <= index, index < self.tableViewContent.count else {
            Log.shared.error(message: "Index too large: \(index). self.tableViewContent.count: \(self.tableViewContent.count)", category: String(describing: self))
            return
        }

        self.tableViewContent.remove(at: index)
        self.tableView?.removeRows(at: IndexSet(integer: index), withAnimation: .slideDown)
        self.cellView.setValue(self.tableViewContent, forSubkey: self.subkey, row: self.row)
        self.setValue(self.tableViewContent, forKey: self.tableViewContentSelector)

        let rowCount = self.tableViewContent.count
        if 0 < rowCount {
            if index < rowCount {
                self.tableView?.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            } else {
                self.tableView?.selectRowIndexes(IndexSet(integer: (rowCount - 1)), byExtendingSelection: false)
            }
        }
    }

    private func tableColumn(forSubkey subkey: PayloadSubkey, profile: Profile) -> NSTableColumn {
        let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(subkey.keyPath))
        tableColumn.isEditable = true
        tableColumn.title = profile.settings.titleString(forSubkey: subkey)
        tableColumn.headerToolTip = subkey.description
        if subkey.type == .bool {
            tableColumn.sizeToFit()
            tableColumn.maxWidth = tableColumn.headerCell.cellSize.width + 1
            tableColumn.minWidth = 17.0
        }
        return tableColumn
    }

    private func setupTableViewContent(subkey: PayloadSubkey) {

        guard let tableView = self.tableView else { return }

        if subkey.subkeys.count == 1, let tableViewSubkey = subkey.subkeys.first {

            if self.tableViewContentSubkey?.rangeList != nil {
                let tableColumnReorder = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Reorder"))
                tableColumnReorder.isEditable = false
                tableColumnReorder.title = ""
                tableColumnReorder.sizeToFit()
                tableColumnReorder.maxWidth = 4.0
                tableColumnReorder.minWidth = 4.0
                tableView.addTableColumn(tableColumnReorder)
            }

            switch tableViewSubkey.typeInput {
            case .string:
                if !self.profile.settings.isAvailableForSelectedPlatform(subkey: tableViewSubkey) { return }
                self.tableViewColumns.append(tableViewSubkey)

                // ---------------------------------------------------------------------
                //  Setup TableColumn
                // ---------------------------------------------------------------------
                tableView.addTableColumn(self.tableColumn(forSubkey: tableViewSubkey, profile: self.profile))

            default:
                Log.shared.error(message: "Unsupported type: \(tableViewSubkey.typeInput) in Array TableCell View", category: String(describing: self))
            }
        } else {
            Log.shared.error(message: "Currently only one subkey is supported in an Array TableCell view", category: String(describing: self))
        }

        self.tableView?.headerView = nil
        self.tableView?.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
    }

    private func saveCurrentEdit(_ notification: Notification) {

        // ---------------------------------------------------------------------
        //  Verify we are editing and get the current value
        // ---------------------------------------------------------------------
        guard
            let userInfo = notification.userInfo,
            let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
            let stringValue = fieldEditor.textStorage?.string else { return }

        // ---------------------------------------------------------------------
        //  Get all required objects
        // ---------------------------------------------------------------------
        guard let textField = notification.object as? NSTextField, let keyPath = textField.identifier?.rawValue else { return }
        guard let textFieldSubkey = self.subkey.subkeys.first(where: { $0.keyPath == keyPath }) ?? self.subkey.subkeys.first(where: { $0.subkeys.contains(where: { $0.keyPath == keyPath }) }) else {
            Log.shared.error(message: "Found no subkey that matches TextField identifier keyPath: \(keyPath)", category: String(describing: self))
            return
        }

        // ---------------------------------------------------------------------
        //  Set TextColor (red if not matching format)
        // ---------------------------------------------------------------------
        textField.highlighSubstrings(for: textFieldSubkey)

        // ---------------------------------------------------------------------
        //  Get the table view settings
        // ---------------------------------------------------------------------
        var tableViewContent = self.tableViewContent

        // ---------------------------------------------------------------------
        //  Verify the current row still exist
        // ---------------------------------------------------------------------
        if tableViewContent.count <= textField.tag { return }

        // ---------------------------------------------------------------------
        //  Get the current row settings
        // ---------------------------------------------------------------------
        var rowContent = tableViewContent[textField.tag]

        // ---------------------------------------------------------------------
        //  Update the current row settings
        // ---------------------------------------------------------------------
        switch textFieldSubkey.type {
        case .float:
            if let floatValue = Float(stringValue) {
                rowContent = NSNumber(value: floatValue)
            }
        case .integer:
            if let intValue = Int(stringValue) {
                rowContent = NSNumber(value: intValue)
            }
        case .string:
            rowContent = stringValue
        default:
            Log.shared.error(message: "Subkey type: \(textFieldSubkey.type) is not currently supported in a TableView Array CellView", category: String(describing: self))
        }

        tableViewContent[textField.tag] = rowContent
        self.cellView.setValue(tableViewContent, forSubkey: self.subkey, row: self.row)
        self.setValue(tableViewContent, forKey: self.tableViewContentSelector)
    }

    private func saveCurrentComboBoxEdit(_ notification: Notification) {

        guard let comboBox = notification.object as? NSComboBox, let keyPath = comboBox.identifier?.rawValue else { return }
        guard let comboBoxSubkey = self.subkey.subkeys.first(where: { $0.keyPath == keyPath }) ?? self.subkey.subkeys.first(where: { $0.subkeys.contains(where: { $0.keyPath == keyPath }) }) else {
            Log.shared.error(message: "Found no subkey that matches ComboBox identifier keyPath: \(keyPath)", category: String(describing: self))
            return
        }

        // ---------------------------------------------------------------------
        //  Get the table view settings
        // ---------------------------------------------------------------------
        var tableViewContent = self.tableViewContent

        // ---------------------------------------------------------------------
        //  Verify the current row still exist
        // ---------------------------------------------------------------------
        if tableViewContent.count <= comboBox.tag { return }

        // ---------------------------------------------------------------------
        //  Get the current row settings
        // ---------------------------------------------------------------------
        var rowContent = tableViewContent[comboBox.tag]

        if let selectedValue = comboBox.objectValue {
            var newValue: Any?
            if
                comboBox.objectValues.contains(value: selectedValue, ofType: self.subkey.type),
                let selectedTitle = selectedValue as? String,
                let value = PayloadUtility.value(forRangeListTitle: selectedTitle, subkey: self.subkey) {
                newValue = value
            } else {
                newValue = selectedValue
            }

            // ---------------------------------------------------------------------
            //  Update the current row settings
            // ---------------------------------------------------------------------
            switch comboBoxSubkey.type {
            case .float:
                if let floatValue = newValue as? Float {
                    rowContent = NSNumber(value: floatValue)
                }
            case .integer:
                if let intValue = newValue as? Int {
                    rowContent = NSNumber(value: intValue)
                }
            case .string:
                if let stringValue = newValue as? String {
                    rowContent = stringValue
                }
            default:
                Log.shared.error(message: "Subkey type: \(comboBoxSubkey.type) is not currently supported in a TableView Array CellView", category: String(describing: self))
            }

            comboBox.highlighSubstrings(for: self.subkey)

            tableViewContent[comboBox.tag] = rowContent
            self.cellView.setValue(tableViewContent, forSubkey: self.subkey, row: self.row)
            self.setValue(tableViewContent, forKey: self.tableViewContentSelector)
        }
    }
}

// MARK: -
// MARK: NSComboBoxDelegate Functions

extension EditorTableViewCellViewArrayView {
    func comboBoxSelectionDidChange(_ notification: Notification) {

        guard let comboBox = notification.object as? NSComboBox, let keyPath = comboBox.identifier?.rawValue else { return }
        guard let comboBoxSubkey = self.subkey.subkeys.first(where: { $0.keyPath == keyPath }) ?? self.subkey.subkeys.first(where: { $0.subkeys.contains(where: { $0.keyPath == keyPath }) }) else {
            Log.shared.error(message: "Found no subkey that matches ComboBox identifier keyPath: \(keyPath)", category: String(describing: self))
            return
        }

        // ---------------------------------------------------------------------
        //  Get the table view settings
        // ---------------------------------------------------------------------
        var tableViewContent = self.tableViewContent

        // ---------------------------------------------------------------------
        //  Verify the current row still exist
        // ---------------------------------------------------------------------
        if tableViewContent.count <= comboBox.tag { return }

        // ---------------------------------------------------------------------
        //  Get the current row settings
        // ---------------------------------------------------------------------
        var rowContent = tableViewContent[comboBox.tag]

        if let selectedValue = comboBox.objectValueOfSelectedItem {
            var newValue: Any?
            if
                comboBox.objectValues.contains(value: selectedValue, ofType: self.subkey.type),
                let selectedTitle = selectedValue as? String,
                let value = PayloadUtility.value(forRangeListTitle: selectedTitle, subkey: self.subkey) {
                newValue = value
            } else {
                newValue = selectedValue
            }

            // ---------------------------------------------------------------------
            //  Update the current row settings
            // ---------------------------------------------------------------------
            switch comboBoxSubkey.type {
            case .float:
                if let floatValue = newValue as? Float {
                    rowContent = NSNumber(value: floatValue)
                }
            case .integer:
                if let intValue = newValue as? Int {
                    rowContent = NSNumber(value: intValue)
                }
            case .string:
                if let stringValue = newValue as? String {
                    rowContent = stringValue
                }
            default:
                Log.shared.error(message: "Subkey type: \(comboBoxSubkey.type) is not currently supported in a TableView Array CellView", category: String(describing: self))
            }

            comboBox.highlighSubstrings(for: self.subkey)

            tableViewContent[comboBox.tag] = rowContent
            self.cellView.setValue(tableViewContent, forSubkey: self.subkey, row: self.row)
            self.setValue(tableViewContent, forKey: self.tableViewContentSelector)
        }
    }
}

// MARK: -
// MARK: NSTextFieldDelegate Functions

extension EditorTableViewCellViewArrayView {
    internal func controlTextDidChange(_ notification: Notification) {
        if (notification.object as? NSComboBox) != nil {
            self.saveCurrentComboBoxEdit(notification)
        } else {
            self.saveCurrentEdit(notification)
        }
    }

    internal func controlTextDidEndEditing(_ notification: Notification) {
        if (notification.object as? NSComboBox) != nil {
            self.saveCurrentComboBoxEdit(notification)
        } else {
            self.saveCurrentEdit(notification)
        }
    }
}

// MARK: -
// MARK: NSTableViewDataSource Functions

extension EditorTableViewCellViewArrayView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        self.tableViewContent.count
    }
}

// MARK: -
// MARK: NSTableViewDelegate Functions

extension EditorTableViewCellViewArrayView: NSTableViewDelegate {

    func rowValue(forColumnSubkey subkey: PayloadSubkey, row: Int) -> Any? {

        let rowContent = self.tableViewContent[row]
        var rowValue: Any?

        if self.tableViewContentType == .dictionary, let rowContentDict = rowContent as? [String: Any] {
            let relativeKeyPath = subkey.valueKeyPath.deletingPrefix(self.subkey.valueKeyPath + ".")
            rowValue = rowContentDict.valueForKeyPath(keyPath: relativeKeyPath)
        } else {
            rowValue = rowContent
        }

        if let valueProcessorIdentifier = subkey.valueProcessor, let value = rowValue {
            let valueProcessor = PayloadValueProcessors.shared.processor(withIdentifier: valueProcessorIdentifier, subkey: subkey, inputType: subkey.type, outputType: subkey.typeInput)
            if let valueProcessed = valueProcessor.process(value: value) {
                rowValue = valueProcessed
            }
        }

        return rowValue
    }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {

        guard
            row < self.tableViewContent.count,
            let tableColumn = column,
            let tableColumnSubkey = self.tableViewColumns.first(where: { $0.keyPath == tableColumn.identifier.rawValue }) else { return nil }

        let rowContent = self.rowValue(forColumnSubkey: tableColumnSubkey, row: row)

        if let rangeList = tableColumnSubkey.rangeList, ((subkey.rangeMin == nil || subkey.rangeMin == nil) || rangeList.count <= ProfilePayloads.rangeListConvertMax) {
            if tableColumnSubkey.rangeListAllowCustomValue {
                return EditorTableViewCellViewComboBox(cellView: self,
                                                       keyPath: tableColumnSubkey.keyPath,
                                                       value: rowContent,
                                                       subkey: tableColumnSubkey,
                                                       row: row)
            } else {
                return EditorTableViewCellViewPopUpButton(cellView: self,
                                                          keyPath: tableColumnSubkey.keyPath,
                                                          value: rowContent,
                                                          subkey: tableColumnSubkey,
                                                          row: row)
            }
        }

        switch tableColumnSubkey.typeInput {
        case .string:
            return EditorTableViewCellViewTextField(cellView: self,
                                                    keyPath: tableColumnSubkey.keyPath,
                                                    value: rowContent as? String,
                                                    placeholderString: tableColumnSubkey.valuePlaceholder as? String ?? tableColumn.title,
                                                    row: row)
        default:
            Log.shared.error(message: "Unknown TableColumn Subkey Type: \(tableColumnSubkey.type)", category: String(describing: self))
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView {
            self.buttonRemove.isEnabled = (tableView.selectedRowIndexes.count) == 0 ? false : true
        }
    }
}

// MARK: -
// MARK: NSPopUpButton Functions

@objc protocol EditorTableViewProtocol: AnyObject {
    @objc func selected(_ popUpButton: NSPopUpButton)
    @objc func select(_ menuItem: NSMenuItem)
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
}

extension EditorTableViewCellViewArrayView: EditorTableViewProtocol {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard
            let keyPath = menuItem.identifier?.rawValue,
            let tableColumnSubkey = self.tableViewColumns.first(where: { $0.keyPath == keyPath }) else {
                // FIXME: Correct Error
                return false
        }

        guard let selectedValue = PayloadUtility.value(forRangeListTitle: menuItem.title, subkey: tableColumnSubkey) else {
            Log.shared.error(message: "Subkey: \(self.subkey.keyPath) Failed to get value for selected title: \(String(describing: menuItem.title)) ", category: String(describing: self))
            return false
        }

        if menuItem.tag < self.tableViewContent.count, valueIsEqual(payloadValueType: tableColumnSubkey.type, a: selectedValue, b: self.tableViewContent[menuItem.tag]) {
            return true
        } else {
            return !self.tableViewContent.containsAny(value: selectedValue, ofType: tableColumnSubkey.type)
        }
    }

    @objc func select(_ menuItem: NSMenuItem) {
        guard
            let keyPath = menuItem.identifier?.rawValue,
            let tableColumnSubkey = self.tableViewColumns.first(where: { $0.keyPath == keyPath }) else {
                // FIXME: Correct Error
                return
        }

        guard let selectedValue = PayloadUtility.value(forRangeListTitle: menuItem.title, subkey: tableColumnSubkey) else {
            Log.shared.error(message: "Subkey: \(self.subkey.keyPath) Failed to get value for selected title: \(String(describing: menuItem.title)) ", category: String(describing: self))
            return
        }

        // ---------------------------------------------------------------------
        //  Get the table view settings
        // ---------------------------------------------------------------------
        var tableViewContent = self.tableViewContent

        // ---------------------------------------------------------------------
        //  Verify the current row still exist
        // ---------------------------------------------------------------------
        if tableViewContent.count <= menuItem.tag { return }

        tableViewContent[menuItem.tag] = selectedValue

        self.cellView.setValue(tableViewContent, forSubkey: self.subkey, row: self.row)
        self.setValue(tableViewContent, forKey: self.tableViewContentSelector)
    }

    @objc func selected(_ popUpButton: NSPopUpButton) {
        guard
            let keyPath = popUpButton.identifier?.rawValue,
            let tableColumnSubkey = self.tableViewColumns.first(where: { $0.keyPath == keyPath }) else {
                // FIXME: Correct Error
                return
        }

        guard let selectedTitle = popUpButton.titleOfSelectedItem,
            let selectedValue = PayloadUtility.value(forRangeListTitle: selectedTitle, subkey: tableColumnSubkey) else {
                Log.shared.error(message: "Subkey: \(self.subkey.keyPath) Failed to get value for selected title: \(String(describing: popUpButton.titleOfSelectedItem)) ", category: String(describing: self))
                return
        }

        // ---------------------------------------------------------------------
        //  Get the table view settings
        // ---------------------------------------------------------------------
        var tableViewContent = self.tableViewContent

        // ---------------------------------------------------------------------
        //  Verify the current row still exist
        // ---------------------------------------------------------------------
        if tableViewContent.count <= popUpButton.tag { return }

        tableViewContent[popUpButton.tag] = selectedValue

        self.cellView.setValue(tableViewContent, forSubkey: self.subkey, row: self.row)
        self.setValue(tableViewContent, forKey: self.tableViewContentSelector)
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension EditorTableViewCellViewArrayView {
    private func setupContainerView(constraints: inout [NSLayoutConstraint]) {

        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.wantsLayer = true
        self.containerView.layer?.borderWidth = 0.5
        self.containerView.layer?.borderColor = NSColor.systemGray.cgColor

        self.addSubview(self.containerView)

        let indent: CGFloat = 6.0

        // Width
        constraints.append(NSLayoutConstraint(item: self.containerView,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 300.0))

        // Top
        constraints.append(NSLayoutConstraint(item: self.containerView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: indent))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.containerView,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: indent))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.containerView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: indent))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.containerView,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: indent))
    }

    private func setupScrollView(constraints: inout [NSLayoutConstraint]) {
        guard let scrollView = self.scrollView else { return }

        scrollView.borderType = .noBorder

        self.tableView?.usesAlternatingRowBackgroundColors = true
        self.tableView?.rowSizeStyle = .custom
        self.tableView?.rowHeight = 18.0

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Height
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: self.buttonRemove,
                                              attribute: .height,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Width
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: self.buttonRemove,
                                              attribute: .width,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Top
        constraints.append(NSLayoutConstraint(item: scrollView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.containerView,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 1.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: scrollView,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 1.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: scrollView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.containerView,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 1.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.containerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: scrollView,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 1.0))

    }

    private func setupButtonAdd(constraints: inout [NSLayoutConstraint]) {
        self.buttonAdd.translatesAutoresizingMaskIntoConstraints = false
        self.buttonAdd.bezelStyle = .smallSquare
        self.buttonAdd.setButtonType(.momentaryChange)
        self.buttonAdd.isBordered = false
        self.buttonAdd.isTransparent = false
        self.buttonAdd.tag = 0
        self.buttonAdd.target = self
        self.buttonAdd.action = #selector(self.clicked(_:))
        self.buttonAdd.imagePosition = .imageOnly
        if let add = NSImage(named: "Add") {
            self.buttonAdd.image = add
        }
        self.buttonAdd.imageScaling = .scaleProportionallyUpOrDown

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonAdd)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Height
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 16.0))

        // Height == Width
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: self.buttonAdd,
                                              attribute: .width,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Center Y
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.buttonRemove,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self.containerView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.buttonAdd,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 2.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.buttonAdd,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.containerView,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 3.0))
    }

    private func setupButtonRemove(constraints: inout [NSLayoutConstraint]) {
        self.buttonRemove.translatesAutoresizingMaskIntoConstraints = false
        self.buttonRemove.bezelStyle = .smallSquare
        self.buttonRemove.setButtonType(.momentaryChange)
        self.buttonRemove.isBordered = false
        self.buttonRemove.isTransparent = false
        self.buttonRemove.tag = 1
        self.buttonRemove.target = self
        self.buttonRemove.action = #selector(self.clicked(_:))
        self.buttonRemove.imagePosition = .imageOnly
        self.buttonRemove.isEnabled = false
        if let subtract = NSImage(named: "Subtract") {
            self.buttonRemove.image = subtract
        }
        self.buttonRemove.imageScaling = .scaleProportionallyUpOrDown

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonRemove)

        // Leading
        constraints.append(NSLayoutConstraint(item: self.buttonRemove,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.buttonAdd,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }
}
