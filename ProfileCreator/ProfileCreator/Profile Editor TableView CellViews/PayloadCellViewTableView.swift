//
//  TableCellViewTextField.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewTableView: PayloadCellView, ProfileCreatorCellView, TableViewCellView {

    // MARK: -
    // MARK: Instance Variables

    var scrollView: NSScrollView?
    var tableView: NSTableView?
    var progressIndicator = NSProgressIndicator()
    var textFieldProgress = NSTextField()
    var imageViewDragDrop = NSImageView()
    var buttonImport: NSSegmentedControl?
    var isImporting = false
    var tableViewContent = [Any]()
    var tableViewColumns = [PayloadSubkey]()
    var tableViewContentSubkey: PayloadSubkey?
    var tableViewContentType: PayloadValueType = .undefined
    var valueDefault: Any?
    let buttonAddRemove = NSSegmentedControl()

    private var dragDropType = NSPasteboard.PasteboardType(rawValue: "private.table-row")

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

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
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.scrollView = EditorTableView.scrollView(height: 100.0, constraints: &self.cellViewConstraints, target: self, cellView: self)
        if let tableView = self.scrollView?.documentView as? NSTableView {
            tableView.allowsMultipleSelection = true
            tableView.registerForDraggedTypes([dragDropType])
            self.tableView = tableView
        }
        self.setupScrollView()

        // ---------------------------------------------------------------------
        //  Setup Table View Content
        // ---------------------------------------------------------------------
        if let aTableView = self.tableView {
            self.setupContent(forTableView: aTableView, subkey: subkey)
        }

        // ---------------------------------------------------------------------
        //  Setup Button Add/Remove
        // ---------------------------------------------------------------------
        self.setupButtonAddRemove()

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: self.buttonAddRemove)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.defaultValue() {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Drag n Drop support
        // ---------------------------------------------------------------------
        if self.valueImportProcessor != nil {
            self.tableView?.registerForDraggedTypes([.backwardsCompatibleFileURL])

            self.setupButtonImport()
            self.setupProgressIndicator()
            self.setupTextFieldProgress()
            self.setupImageViewDragDrop()
        }

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        self.tableViewContent = self.getTableViewContent()

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.buttonAddRemove
        self.trailingKeyView = self.buttonAddRemove

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)

        // ---------------------------------------------------------------------
        //  Reload TableView
        // ---------------------------------------------------------------------
        self.tableView?.reloadData()
    }

    private func getTableViewContent() -> [Any] {
        var valueTableView: Any?
        if let value = self.profile.settings.value(forSubkey: self.subkey, payloadIndex: self.payloadIndex) {
            valueTableView = value
        } else if let valueDefault = self.valueDefault {
            valueTableView = valueDefault
        }

        if let value = valueTableView, let tableViewContent = self.tableViewContent(fromValue: value) {
            return tableViewContent
        } else {
            return [Any]()
        }
    }

    private func tableViewReloadData() {
        self.tableViewContent = self.getTableViewContent()
        self.tableView?.reloadData()
    }

    private func tableViewContent(fromValue value: Any) -> [Any]? {
        if subkey.typeInput == .dictionary, let valueDict = value as? [String: Any] {
            var newValueArray = [[String: Any]]()
            if let subkeyKey = subkey.subkeys.first(where: { $0.key == ManifestKeyPlaceholder.key }), let subkeyValue = subkey.subkeys.first(where: { $0.key == ManifestKeyPlaceholder.value }) {
                for (key, value) in valueDict {
                    var newValue = [String: Any]()
                    newValue[subkeyKey.key] = key
                    newValue[subkeyValue.key] = value
                    newValueArray.append(newValue)
                }
            }
            return newValueArray
        } else if subkey.typeInput == .array, let valueArray = value as? [Any] {
            return valueArray
        } else {
            Log.shared.debug(message: "Input type: \(subkey.typeInput) is not currently handled by CellViewTableView", category: String(describing: self))
        }
        return nil
    }

    private func tableViewContentSave() {
        switch self.subkey.type {
        case .dictionary:
            guard let tableViewContent = self.tableViewContent as? [[String: Any]] else {
                return
            }
            var valueSave = [String: Any]()
            for rowValue in tableViewContent {
                let key = rowValue[ManifestKeyPlaceholder.key] as? String ?? ""
                if let value = rowValue[ManifestKeyPlaceholder.value] {
                    valueSave[key] = value
                }
            }
            self.profile.settings.setValue(valueSave, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
        case .array:
            self.profile.settings.setValue(self.tableViewContent, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
        default:
            Log.shared.debug(message: "Type: \(subkey.typeInput) is not currently handled by CellViewTableView", category: String(describing: self))
        }
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.tableView?.isEnabled = enable
        self.buttonAddRemove.isEnabled = enable
        if let buttonImport = self.buttonImport {
            buttonImport.isEnabled = enable
        }
    }

    // MARK: -
    // MARK: Button Actions

    @objc private func clickedImport(_ segmentedControl: NSSegmentedControl) {

        guard let window = self.window else { return }

        // ---------------------------------------------------------------------
        //  Setup open dialog
        // ---------------------------------------------------------------------
        let openPanel = NSOpenPanel()
        // FIXME: Should use the name from file import as the prompt
        openPanel.prompt = NSLocalizedString("Select File", comment: "")
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = true
        if let allowedFileTypes = subkey.allowedFileTypes {
            openPanel.allowedFileTypes = allowedFileTypes
        }

        // ---------------------------------------------------------------------
        //  Get open dialog allowed file types
        // ---------------------------------------------------------------------
        if let allowedFileTypes = self.subkey.allowedFileTypes {
            openPanel.allowedFileTypes = allowedFileTypes
        }

        openPanel.beginSheetModal(for: window) { response in
            if response == .OK {
                _ = self.importURLs(openPanel.urls)
            }
        }
    }

    @objc private func clicked(_ segmentedControl: NSSegmentedControl) {
        if segmentedControl.selectedSegment == 0 { // Add
            self.addRow()
        } else if segmentedControl.selectedSegment == 1 { // Remove
            if let rowIndexes = self.tableView?.selectedRowIndexes {
                self.removeRow(indexes: rowIndexes)
            }
        }
    }

    private func addRow() {

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

        var newRow: Any
        if self.tableViewContentType == .dictionary {
            var newRowDict = [String: Any]()
            for tableViewColumn in self.tableViewColumns {

                // Do not set a default value for keys that will copy their values
                if tableViewColumn.valueCopy != nil || tableViewColumn.valueDefaultCopy != nil { continue }

                let relativeKeyPath = tableViewColumn.valueKeyPath.deletingPrefix(self.subkey.valueKeyPath + ".")
                guard let newRowValue = tableViewColumn.defaultValue() ?? PayloadUtility.emptyValue(valueType: tableViewColumn.type) else { continue }
                newRowDict.setValue(value: newRowValue, forKeyPath: relativeKeyPath)
            }
            newRow = newRowDict
        } else {
            if let rangeList = self.tableViewContentSubkey?.rangeList, let newRowValue = rangeList.first(where: { !self.tableViewContent.containsAny(value: $0, ofType: self.tableViewContentType) }) {
                newRow = newRowValue
            } else {
                guard let newRowValue = self.tableViewContentSubkey?.defaultValue() ?? PayloadUtility.emptyValue(valueType: self.tableViewContentType) else { return }
                newRow = newRowValue
            }
        }

        var newIndex: Int
        if let index = self.tableView?.selectedRowIndexes.last, (index + 1) <= self.tableViewContent.count {
            self.tableViewContent.insert(newRow, at: (index + 1))
            newIndex = index + 1
        } else {
            self.tableViewContent.append(newRow)
            newIndex = self.tableViewContent.count - 1
        }
        self.tableViewContentSave()
        self.tableViewReloadData()
        self.tableView?.selectRowIndexes(IndexSet(integer: newIndex), byExtendingSelection: false)
    }

    private func removeRow(indexes: IndexSet) {
        guard !indexes.isEmpty, let indexMax = indexes.max(), indexMax < self.tableViewContent.count else {
            Log.shared.error(message: "Index too large: \(String(describing: indexes.max())). self.tableViewContent.count: \(self.tableViewContent.count)", category: String(describing: self))
            return
        }

        self.tableViewContent.remove(at: indexes)
        self.tableView?.removeRows(at: indexes, withAnimation: .slideDown)
        self.tableViewContentSave()

        let rowCount = self.tableViewContent.count
        if 0 < rowCount {
            if indexMax < rowCount {
                self.tableView?.selectRowIndexes(IndexSet(integer: indexMax), byExtendingSelection: false)
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
        tableColumn.isHidden = profile.settings.showHiddenKeys ? false : subkey.hidden == .all
        if subkey.type == .bool {
            tableColumn.sizeToFit()
            tableColumn.maxWidth = tableColumn.headerCell.cellSize.width + 1
            tableColumn.minWidth = 17.0
        }
        return tableColumn
    }

    func setValue(_ value: Any?, forSubkey subkey: PayloadSubkey, row: Int) {

        if self.subkey.type != .dictionary {

            let subkeyValueKeyPath = PayloadUtility.expandKeyPath(subkey.valueKeyPath, withRootKeyPath: self.subkey.valueKeyPath + ".\(row)")
            guard let newValue = value else { return }
            self.profile.settings.setValue(newValue, forValueKeyPath: subkeyValueKeyPath, subkey: subkey, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: self.payloadIndex)
            self.tableViewContent = self.getTableViewContent()

        } else {

            // ---------------------------------------------------------------------
            //  Get the current row settings
            // ---------------------------------------------------------------------
            var tableViewContent = self.tableViewContent

            // ---------------------------------------------------------------------
            //  Update the current row settings
            // ---------------------------------------------------------------------
            var rowContent: Any?
            if let newValue = value {
                if self.tableViewContentType == .dictionary {
                    guard var rowContentDict = tableViewContent[row] as? [String: Any] else { return }

                    // Calculate relative key path and use KeyPath adding
                    let relativeKeyPath = subkey.valueKeyPath.deletingPrefix(self.subkey.valueKeyPath + ".")
                    rowContentDict.setValue(value: newValue, forKeyPath: relativeKeyPath)
                    rowContent = rowContentDict
                } else {
                    rowContent = newValue
                }
            } else if self.tableViewContentType == .dictionary {
                guard var rowContent = tableViewContent[row] as? [String: Any] else { return }
                rowContent.removeValue(forKey: subkey.key)
            } else {
                rowContent = PayloadUtility.emptyValue(valueType: subkey.type)
            }

            guard let newRowContent = rowContent else { return }
            tableViewContent[row] = newRowContent

            // ---------------------------------------------------------------------
            //  Save the changes internally and to the payloadSettings
            // ---------------------------------------------------------------------
            self.tableViewContent = tableViewContent
            self.tableViewContentSave()
        }
    }

    func setupContent(forTableView tableView: NSTableView, subkey: PayloadSubkey) {

        // FIXME: Highly temporary implementation
        if let tableViewSubkey = self.tableViewContentSubkey {

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
            case .dictionary:
                if subkey.subkeys.contains(where: { $0.key == ManifestKeyPlaceholder.key }) {
                    var subkeys = [PayloadSubkey]()
                    if let subkeyKey = subkey.subkeys.first(where: { $0.key == ManifestKeyPlaceholder.key }) {
                        subkeys.append(subkeyKey)
                    }

                    if let subkeyValue = subkey.subkeys.first(where: { $0.key == ManifestKeyPlaceholder.value }) {
                        if subkeyValue.type == .dictionary, subkeyValue.hidden == .container {
                            subkeys.append(contentsOf: self.columnSubkeys(forSubkeys: subkeyValue.subkeys))
                        } else {
                            subkeys.append(subkeyValue)
                        }
                    }

                    for tableViewColumnSubkey in subkeys {
                        if !self.profile.settings.isAvailableForSelectedPlatform(subkey: tableViewColumnSubkey) { continue }
                        self.tableViewColumns.append(tableViewColumnSubkey)

                        // ---------------------------------------------------------------------
                        //  Setup TableColumn
                        // ---------------------------------------------------------------------
                        tableView.addTableColumn(self.tableColumn(forSubkey: tableViewColumnSubkey, profile: self.profile))
                    }
                } else {
                    for tableViewColumnSubkey in self.columnSubkeys(forSubkeys: tableViewSubkey.subkeys) {

                        if !profile.settings.isAvailableForSelectedPlatform(subkey: tableViewColumnSubkey) { continue }
                        self.tableViewColumns.append(tableViewColumnSubkey)

                        // ---------------------------------------------------------------------
                        //  Setup TableColumn
                        // ---------------------------------------------------------------------
                        tableView.addTableColumn(self.tableColumn(forSubkey: tableViewColumnSubkey, profile: profile))
                    }
                }

                if tableViewSubkey.subkeys.count < 2 {
                    self.tableView?.headerView = nil
                    self.tableView?.toolTip = tableViewSubkey.subkeys.first?.description
                }
            case .array:
                // FIXME: Handle arrays in arrays
                for tableViewColumnSubkey in tableViewSubkey.subkeys where tableViewColumnSubkey.type == .array {
                    for nextSubkey in tableViewColumnSubkey.subkeys {
                        if !self.profile.settings.isAvailableForSelectedPlatform(subkey: nextSubkey) { continue }
                        self.tableViewColumns.append(nextSubkey)

                        // ---------------------------------------------------------------------
                        //  Setup TableColumn
                        // ---------------------------------------------------------------------
                        tableView.addTableColumn(self.tableColumn(forSubkey: nextSubkey, profile: self.profile))
                    }
                }
            case .bool,
                 .string,
                 .integer:
                if !self.profile.settings.isAvailableForSelectedPlatform(subkey: tableViewSubkey) { return }
                self.tableViewColumns.append(tableViewSubkey)

                // ---------------------------------------------------------------------
                //  Setup TableColumn
                // ---------------------------------------------------------------------
                tableView.addTableColumn(self.tableColumn(forSubkey: tableViewSubkey, profile: self.profile))
            default:
                Log.shared.error(message: "Unhandled PayloadValueType in TableView: \(tableViewSubkey.typeInput)", category: String(describing: self))
            }
        } else {
            Log.shared.error(message: "Subkey: \(subkey.keyPath) subkey count is: \(subkey.subkeys.count). Only 1 subkey is currently supported", category: "")
        }

        self.tableView?.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
    }

    private func columnSubkeys(forSubkeys subkeys: [PayloadSubkey]) -> [PayloadSubkey] {
        var columnSubkeys = [PayloadSubkey]()
        for subkey in subkeys {
            if subkey.typeInput == .dictionary, subkey.hidden == .container {
                columnSubkeys.append(contentsOf: self.columnSubkeys(forSubkeys: subkey.subkeys))
            } else {
                columnSubkeys.append(subkey)
            }
        }
        return columnSubkeys
    }

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
}

// MARK: -
// MARK: EditorTableViewProtocol Functions

extension PayloadCellViewTableView: EditorTableViewProtocol {

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

        self.setValue(selectedValue, forSubkey: tableColumnSubkey, row: menuItem.tag)
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

        self.setValue(selectedValue, forSubkey: tableColumnSubkey, row: popUpButton.tag)
    }
}

// MARK: -
// MARK: NSButton Functions

extension PayloadCellViewTableView {
    @objc func buttonClicked(_ button: NSButton) {

        // ---------------------------------------------------------------------
        //  Get all required objects
        // ---------------------------------------------------------------------
        guard
            let keyPath = button.identifier?.rawValue,
            let tableColumnSubkey = self.tableViewColumns.first(where: { $0.keyPath == keyPath }) else {
                // FIXME: Correct Error
                return
        }

        self.setValue(button.state == .on ? true : false, forSubkey: tableColumnSubkey, row: button.tag)
    }
}

// MARK: -
// MARK: NSTextFieldDelegate Functions

extension PayloadCellViewTableView {
    internal func controlTextDidChange(_ notification: Notification) {
        self.isEditing = true
        if (notification.object as? NSComboBox) != nil {
            self.saveCurrentComboBoxEdit(notification)
        } else {
            self.saveCurrentEdit(notification)
        }
    }

    internal func controlTextDidEndEditing(_ notification: Notification) {
        if self.isEditing {
            self.isEditing = false
            if (notification.object as? NSComboBox) != nil {
                self.saveCurrentComboBoxEdit(notification)
            } else {
                self.saveCurrentEdit(notification)
            }
        }
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
        //  Get the keyPath assigned the TextField being edited
        // ---------------------------------------------------------------------
        guard let textField = notification.object as? NSTextField, let keyPath = textField.identifier?.rawValue else { return }

        // ---------------------------------------------------------------------
        //  Get the subkey using the keyPath assigned the TextField being edited
        // ---------------------------------------------------------------------
        guard let textFieldSubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: keyPath, domainIdentifier: self.subkey.domainIdentifier, type: self.subkey.payloadType) else {
            Log.shared.error(message: "Found no subkey that matches TextField identifier keyPath: \(keyPath)", category: String(describing: self))
            return
        }

        // ---------------------------------------------------------------------
        //  Set TextColor (red if not matching format)
        // ---------------------------------------------------------------------
        textField.highlighSubstrings(for: textFieldSubkey)

        // ---------------------------------------------------------------------
        //  Update Value
        // ---------------------------------------------------------------------
        self.setValue(stringValue, forSubkey: textFieldSubkey, row: textField.tag)
    }

    private func saveCurrentComboBoxEdit(_ notification: Notification) {

        guard let comboBox = notification.object as? NSComboBox, let keyPath = comboBox.identifier?.rawValue else { return }
        guard let comboBoxSubkey = self.subkey.subkeys.first(where: { $0.keyPath == keyPath }) ?? self.subkey.subkeys.first(where: { $0.subkeys.contains(where: { $0.keyPath == keyPath }) }) else {
            Log.shared.error(message: "Found no subkey that matches ComboBox identifier keyPath: \(keyPath)", category: String(describing: self))
            return
        }

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

            comboBox.highlighSubstrings(for: self.subkey)

            self.setValue(newValue, forSubkey: comboBoxSubkey, row: comboBox.tag)
        }
    }
}

// MARK: -
// MARK: NSComboBoxDelegate Functions

extension PayloadCellViewTableView: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(_ notification: Notification) {

        guard let comboBox = notification.object as? NSComboBox, let keyPath = comboBox.identifier?.rawValue else { return }
        guard let comboBoxSubkey = self.subkey.subkeys.first(where: { $0.keyPath == keyPath }) ?? self.subkey.subkeys.first(where: { $0.subkeys.contains(where: { $0.keyPath == keyPath }) }) else {
            Log.shared.error(message: "Found no subkey that matches ComboBox identifier keyPath: \(keyPath)", category: String(describing: self))
            return
        }

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

            comboBox.highlighSubstrings(for: self.subkey)

            self.setValue(newValue, forSubkey: comboBoxSubkey, row: comboBox.tag)
        }
    }
}

// MARK: -
// MARK: NSTableViewDataSource Functions

extension PayloadCellViewTableView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        self.tableViewContent.count
    }

    func allowedUTIs() -> [String]? {
        var allowedUTIs = [String]()
        guard let allowedFileTypes = self.allowedFileTypes else {
            return nil
        }

        for type in allowedFileTypes {
            if type.contains(".") {
                allowedUTIs.append(type)
            } else if let typeUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "kext" as CFString, nil)?.takeUnretainedValue() as String? {
                allowedUTIs.append(typeUTI)
            }
        }

        return allowedUTIs
    }

    // -------------------------------------------------------------------------
    //  Drag/Drop Support
    // -------------------------------------------------------------------------
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: self.dragDropType)
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {

        guard !self.isImporting else { return NSDragOperation() }

        if info.draggingPasteboard.availableType(from: [dragDropType]) != nil, dropOperation == .above {
            return .move
        } else if info.draggingPasteboard.availableType(from: [.backwardsCompatibleFileURL]) != nil {

        if let allowedFileTypes = self.allowedUTIs() {
            if info.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingContentsConformToTypes: allowedFileTypes]) {
                tableView.setDropRow(-1, dropOperation: .on)
                return .copy
            }
        } else {
            tableView.setDropRow(-1, dropOperation: .on)
            return .copy
        }
        }
        return NSDragOperation()
    }

    func importURLs(_ urls: [URL]) -> Bool {
        guard let valueImportProcessor = self.valueImportProcessor else { return false }

        self.isImporting = true
        self.progressIndicator.startAnimation(self)

        let dispatchQueue = DispatchQueue(label: "serial")
        let dispatchGroup = DispatchGroup()
        let dispatchSemaphore = DispatchSemaphore(value: 0)

        dispatchQueue.async {
            for url in urls {
                dispatchGroup.enter()
                DispatchQueue.main.async {
                    self.textFieldProgress.stringValue = "Processing \(url.lastPathComponent)…"
                }

                do {
                    try valueImportProcessor.addValue(forFile: url, toCurrentValue: self.tableViewContent, subkey: self.subkey, cellView: self) { updatedValue in
                        if let updatedTableViewContent = updatedValue as? [Any] {
                            self.tableViewContent = updatedTableViewContent
                            self.tableViewContentSave()
                            DispatchQueue.main.async {
                                self.tableView?.reloadData()
                            }
                        }
                        dispatchSemaphore.signal()
                        dispatchGroup.leave()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert(withMessage: error.localizedDescription)
                        dispatchSemaphore.signal()
                        dispatchGroup.leave()
                    }
                }

                dispatchSemaphore.wait()
            }
        }

        dispatchGroup.notify(queue: dispatchQueue) {
            DispatchQueue.main.async {
                self.isImporting = false
                self.progressIndicator.stopAnimation(self)
                self.textFieldProgress.stringValue = ""
                self.tableViewReloadData()
            }
        }

        return true
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard !self.isImporting else { return false }

        if info.draggingPasteboard.availableType(from: [dragDropType]) != nil {
            var oldIndexes = [Int]()
            info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:]) { dragItem, _, _ in
                // swiftlint:disable:next force_cast
                if let str = (dragItem.item as! NSPasteboardItem).string(forType: self.dragDropType), let index = Int(str) {
                    oldIndexes.append(index)
                }
            }
            var oldIndexOffset = 0
            var rowsToMoveIndex = row
            var rowsToMove = [Any]()
            for oldIndex in oldIndexes {
                rowsToMove.append(self.tableViewContent.remove(at: oldIndex + oldIndexOffset))

                // Decrease the index for the next item by 1 each time one is removed as the indexes are in ascending order.
                oldIndexOffset -= 1
                if oldIndex < row {
                    rowsToMoveIndex -= 1
                }
            }

            self.tableViewContent.insert(contentsOf: rowsToMove, at: rowsToMoveIndex)
            self.tableViewContentSave()
            self.tableViewReloadData()

            return true
        } else if let allowedFileTypes = self.allowedUTIs(), let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingContentsConformToTypes: allowedFileTypes]) as? [URL] {
            return self.importURLs(urls)
        }
        return false
    }
}

// MARK: -
// MARK: NSTableViewDelegate Functions

extension PayloadCellViewTableView: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        21.0
    }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        guard
            row <= self.tableViewContent.count,
            let tableColumn = column,
            let tableColumnSubkey = self.tableViewColumns.first(where: { $0.keyPath == tableColumn.identifier.rawValue }) else { return nil }

        let rowValue = self.rowValue(forColumnSubkey: tableColumnSubkey, row: row)

        if let rangeList = tableColumnSubkey.rangeList, rangeList.count <= ProfilePayloads.rangeListConvertMax {
            if tableColumnSubkey.rangeListAllowCustomValue {
                return EditorTableViewCellViewComboBox(cellView: self,
                                                       keyPath: tableColumnSubkey.keyPath,
                                                       value: rowValue,
                                                       subkey: tableColumnSubkey,
                                                       row: row)
            } else {
                return EditorTableViewCellViewPopUpButton(cellView: self,
                                                          keyPath: tableColumnSubkey.keyPath,
                                                          value: rowValue,
                                                          subkey: tableColumnSubkey,
                                                          row: row)
            }
        }

        switch tableColumnSubkey.typeInput {
        case .array:
            return EditorTableViewCellViewArray(cellView: self,
                                                subkey: tableColumnSubkey,
                                                keyPath: tableColumnSubkey.keyPath,
                                                value: rowValue as? [Any] ?? [Any](),
                                                row: row)
        case .bool:
            return EditorTableViewCellViewCheckbox(cellView: self,
                                                   keyPath: tableColumnSubkey.keyPath,
                                                   value: rowValue as? Bool ?? false,
                                                   row: row)
        case .integer:
            return EditorTableViewCellViewTextFieldNumber(cellView: self,
                                                          keyPath: tableColumnSubkey.keyPath,
                                                          value: rowValue as? NSNumber,
                                                          placeholderValue: tableColumnSubkey.valuePlaceholder as? NSNumber,
                                                          type: tableColumnSubkey.type,
                                                          row: row)
        case .string:
            return EditorTableViewCellViewTextField(cellView: self,
                                                    keyPath: tableColumnSubkey.keyPath,
                                                    value: rowValue as? String,
                                                    placeholderString: tableColumnSubkey.valuePlaceholder as? String ?? tableColumn.title,
                                                    row: row)
        default:
            Log.shared.error(message: "Unknown TableColumn Subkey Type: \(tableColumnSubkey.type)", category: String(describing: self))
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView {
            self.buttonAddRemove.setEnabled((tableView.selectedRowIndexes.count) == 0 ? false : true, forSegment: 1)
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewTableView {
    private func setupScrollView() {
        guard let scrollView = self.scrollView else { return }

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: scrollView)

        // Leading
        self.addConstraints(forViewLeading: scrollView)

        // Trailing
        self.addConstraints(forViewTrailing: scrollView)

    }

    private func setupProgressIndicator() {
        self.progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.progressIndicator.style = .spinning
        self.progressIndicator.controlSize = .small
        self.progressIndicator.isIndeterminate = true
        self.progressIndicator.isDisplayedWhenStopped = false

        // ---------------------------------------------------------------------
        //  Add ProgressIndicator to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.progressIndicator)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.progressIndicator,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: self.buttonImport ?? self.buttonAddRemove,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 6.0))

        // Center
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.buttonAddRemove,
                                                           attribute: .centerY,
                                                           relatedBy: .equal,
                                                           toItem: self.progressIndicator,
                                                           attribute: .centerY,
                                                           multiplier: 1.0,
                                                           constant: 0.0))

    }

    private func setupImageViewDragDrop() {
        self.imageViewDragDrop.translatesAutoresizingMaskIntoConstraints = false
        self.imageViewDragDrop.image = NSImage(named: "DragDrop")
        self.imageViewDragDrop.imageScaling = .scaleProportionallyUpOrDown
        self.imageViewDragDrop.setContentHuggingPriority(.required, for: .horizontal)
        self.imageViewDragDrop.toolTip = NSLocalizedString("This payload key supports Drag and Drop", comment: "")
        self.imageViewDragDrop.isHidden = self.valueImportProcessor == nil

        // ---------------------------------------------------------------------
        //  Add ImageView to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.imageViewDragDrop)

        // Height
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.imageViewDragDrop,
                                                           attribute: .height,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: 20.0))

        // Width
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.imageViewDragDrop,
                                                           attribute: .width,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: 30.0))

        // Center
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.progressIndicator,
                                                           attribute: .centerY,
                                                           relatedBy: .equal,
                                                           toItem: self.imageViewDragDrop,
                                                           attribute: .centerY,
                                                           multiplier: 1.0,
                                                           constant: 2.0))

        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.imageViewDragDrop,
                                                           attribute: .leading,
                                                           relatedBy: .greaterThanOrEqual,
                                                           toItem: self.textFieldProgress,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 6.0))

        // Trailing
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.imageViewDragDrop,
                                                           attribute: .trailing,
                                                           relatedBy: .equal,
                                                           toItem: self.scrollView,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 2.0))
    }

    private func setupTextFieldProgress() {
        self.textFieldProgress.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldProgress.lineBreakMode = .byWordWrapping
        self.textFieldProgress.isBordered = false
        self.textFieldProgress.isBezeled = false
        self.textFieldProgress.drawsBackground = false
        self.textFieldProgress.isEditable = false
        self.textFieldProgress.isSelectable = false
        self.textFieldProgress.textColor = .secondaryLabelColor
        self.textFieldProgress.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .regular)
        self.textFieldProgress.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        self.textFieldProgress.stringValue = ""
        self.textFieldProgress.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.textFieldProgress)

        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.textFieldProgress,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: self.progressIndicator,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 6.0))
        // Trailing
        // self.addConstraints(forViewTrailing: self.textFieldProgress)

        // Center
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.textFieldProgress,
                                                           attribute: .centerY,
                                                           relatedBy: .equal,
                                                           toItem: self.progressIndicator,
                                                           attribute: .centerY,
                                                           multiplier: 1.0,
                                                           constant: 0.0))
    }

    private func setupButtonAddRemove() {
        guard let scrollView = self.scrollView else { return }

        self.buttonAddRemove.translatesAutoresizingMaskIntoConstraints = false
        self.buttonAddRemove.segmentStyle = .roundRect
        self.buttonAddRemove.segmentCount = 2
        self.buttonAddRemove.trackingMode = .momentary
        self.buttonAddRemove.setImage(NSImage(named: NSImage.addTemplateName), forSegment: 0)
        self.buttonAddRemove.setImage(NSImage(named: NSImage.removeTemplateName), forSegment: 1)
        self.buttonAddRemove.setEnabled(false, forSegment: 1)
        self.buttonAddRemove.action = #selector(clicked(_:))
        self.buttonAddRemove.target = self

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.buttonAddRemove)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Leading
        self.addConstraints(forViewLeading: self.buttonAddRemove)

        // Top
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.buttonAddRemove,
                                                           attribute: .top,
                                                           relatedBy: .equal,
                                                           toItem: scrollView,
                                                           attribute: .bottom,
                                                           multiplier: 1.0,
                                                           constant: 8.0))

        self.updateHeight((8 + self.buttonAddRemove.intrinsicContentSize.height))
    }

    private func setupButtonImport() {

        let buttonImport = NSSegmentedControl()

        buttonImport.translatesAutoresizingMaskIntoConstraints = false
        buttonImport.segmentStyle = .roundRect
        buttonImport.segmentCount = 1
        buttonImport.trackingMode = .momentary
        buttonImport.setLabel(NSLocalizedString("Import", comment: ""), forSegment: 0)
        buttonImport.action = #selector(self.clickedImport(_:))
        buttonImport.target = self

        // ---------------------------------------------------------------------
        //  Add Button to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(buttonImport)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Center
        self.cellViewConstraints.append(NSLayoutConstraint(item: self.buttonAddRemove,
                                                           attribute: .centerY,
                                                           relatedBy: .equal,
                                                           toItem: buttonImport,
                                                           attribute: .centerY,
                                                           multiplier: 1.0,
                                                           constant: 0.0))

        // Leading
        self.cellViewConstraints.append(NSLayoutConstraint(item: buttonImport,
                                                           attribute: .leading,
                                                           relatedBy: .equal,
                                                           toItem: self.buttonAddRemove,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 6.0))

        self.buttonImport = buttonImport
    }
}
