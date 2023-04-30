//
//  ProfileEditorOutlineView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorOutlineView: NSOutlineView {

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: NSRect.zero)

        self.setupOutlineView()
    }

    func setupOutlineView() {

        // ---------------------------------------------------------------------
        //  Setup OutlineView
        // ---------------------------------------------------------------------
        self.translatesAutoresizingMaskIntoConstraints = true
        // self.selectionHighlightStyle = .sourceList
        self.floatsGroupRows = false
        self.rowSizeStyle = .default
        self.autoresizesOutlineColumn = true
        // self.headerView = nil

        // ---------------------------------------------------------------------
        //  Setup OutlineView Columns
        // ---------------------------------------------------------------------
        // Key
        let tableColumnKey = NSTableColumn(identifier: .tableColumnPropertyListKey)
        tableColumnKey.title = "Key"
        tableColumnKey.isEditable = true
        self.addTableColumn(tableColumnKey)

        // Type
        let tableColumnType = NSTableColumn(identifier: .tableColumnPropertyListType)
        tableColumnType.title = "Type"
        tableColumnType.isEditable = true
        self.addTableColumn(tableColumnType)

        // Value
        let tableColumnValue = NSTableColumn(identifier: .tableColumnPropertyListValue)
        tableColumnValue.title = "Value"
        tableColumnValue.isEditable = true
        self.addTableColumn(tableColumnValue)
    }
}
