//
//  MainWindowOutlineView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowOutlineView: NSOutlineView {

    // MARK: -
    // MARK: Variables

    var clickedItem: MainWindowLibraryGroup?
    var clickedItemRow: Int = -1

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: NSRect.zero)
    }

    // -------------------------------------------------------------------------
    //  Override keyDown to catch backspace to delete group in outline view
    // -------------------------------------------------------------------------
    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == String(Character(UnicodeScalar(NSEvent.SpecialKey.delete.rawValue)!)), 2 < self.selectedRow {
            self.removeSelectedGroups(self)
        }
        super.keyDown(with: event)
    }

    // -------------------------------------------------------------------------
    //  Override menu(for event:) to show a contextual menu
    // -------------------------------------------------------------------------
    override func menu(for event: NSEvent) -> NSMenu? {

        // ---------------------------------------------------------------------
        //  Get row that was clicked
        // ---------------------------------------------------------------------
        let point = self.convert(event.locationInWindow, from: nil)
        self.clickedItemRow = self.row(at: point)
        if self.clickedItemRow == -1 || self.level(forRow: self.clickedItemRow) != 1 {
            return nil
        }

        // ---------------------------------------------------------------------
        //  Verify a MainWindowLibraryGroup was clicked, else don't return a menu
        // ---------------------------------------------------------------------
        guard let item = self.item(atRow: self.clickedItemRow) as? MainWindowLibraryGroup else {
            return nil
        }

        self.clickedItem = item

        // ---------------------------------------------------------------------
        //  Create menu
        // ---------------------------------------------------------------------
        let menu = NSMenu()

        // ---------------------------------------------------------------------
        //  Add item: "Rename"
        // ---------------------------------------------------------------------
        let menuItemRename = NSMenuItem()
        menuItemRename.title = NSLocalizedString("Rename \"\(item.title)\"", comment: "")
        menuItemRename.isEnabled = true
        menuItemRename.target = self
        menuItemRename.action = #selector(editGroup)
        menu.addItem(menuItemRename)

        // ---------------------------------------------------------------------
        //  Add item: "Delete"
        // ---------------------------------------------------------------------
        let menuItemDelete = NSMenuItem()
        menuItemDelete.title = NSLocalizedString("Delete", comment: "")
        menuItemDelete.isEnabled = true
        menuItemDelete.target = self
        menuItemDelete.action = #selector(removeSelectedGroups(_:))
        menu.addItem(menuItemDelete)

        // ---------------------------------------------------------------------
        //  Return menu
        // ---------------------------------------------------------------------
        return menu
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {

        // ---------------------------------------------------------------------
        //  Only enable "Rename" for editable items
        //  This is currently not neccessary, but might be needed in a future release
        // ---------------------------------------------------------------------
        if let item = self.clickedItem {
            return item.isEditable
        }
        return false
    }

    @objc func editGroup() {

        // ---------------------------------------------------------------------
        //  Set the group in editing mode
        // ---------------------------------------------------------------------
        if self.clickedItemRow != -1 {
            self.selectRowIndexes(IndexSet(integer: self.clickedItemRow), byExtendingSelection: false)
            self.editColumn(0, row: self.clickedItemRow, with: nil, select: true)
        }
    }

    @objc func removeSelectedGroups(_ sender: Any?) {

        // ---------------------------------------------------------------------
        //  Verify the delegate is set and is a MainWindowOutlineViewDelegate
        //  Depending on who is calling the function, get the selected items separately
        // ---------------------------------------------------------------------
        if let delegate = self.delegate as? MainWindowOutlineViewDelegate {
            if sender is NSMenuItem, self.clickedItem != nil, self.clickedItemRow != -1 {
                delegate.shouldRemoveItems(atIndexes: IndexSet(integer: self.clickedItemRow))
            } else if sender is MainWindowOutlineView, !self.selectedRowIndexes.isEmpty {
                delegate.shouldRemoveItems(atIndexes: self.selectedRowIndexes)
            }
        }
    }
}

extension MainWindowOutlineView: NSMenuDelegate {

    func menuDidClose(_ menu: NSMenu) {

        // ---------------------------------------------------------------------
        //  Reset variables set when menu was created
        // ---------------------------------------------------------------------
        self.clickedItem = nil
        self.clickedItemRow = -1
    }
}
