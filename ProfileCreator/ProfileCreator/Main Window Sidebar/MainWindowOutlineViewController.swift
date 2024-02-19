//
//  MainWindowOutlineViewController.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

// MARK: -
// MARK: Protocols
// MAKR: -

protocol MainWindowOutlineViewDelegate: AnyObject {
    func shouldRemoveItems(atIndexes: IndexSet)
}

protocol MainWindowOutlineViewSelectionDelegate: AnyObject {
    func selected(item: OutlineViewChildItem, sender: Any?)
    func updated(item: OutlineViewChildItem, sender: Any?)
}

// MARK: -
// MARK: Classes

class MainWindowOutlineViewController: NSObject {

    // MARK: -
    // MARK: Variables

    let outlineView = MainWindowOutlineView()
    let scrollView = OverlayScrollView(frame: NSRect.zero)

    var alert: Alert?
    var selectedItem: OutlineViewChildItem?
    var parents = [OutlineViewParentItem]()

    var parentLibrary: MainWindowLibrary?
    var parentLibraryJSS: MainWindowLibraryJSS?

    var allProfilesGroup: OutlineViewChildItem?

    weak var selectionDelegate: MainWindowOutlineViewSelectionDelegate?

    // MARK: -
    // MARK: Initialization

    override init() {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        NotificationCenter.default.addObserver(self, selector: #selector(didAddGroup(_:)), name: .didAddGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didAddProfile(_:)), name: .didAddProfile, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didSaveProfile(_:)), name: .didSaveProfile, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRemoveProfilesFromGroup(_:)), name: .didRemoveProfilesFromGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangePayloadLibraryGroup(_:)), name: .didChangePayloadLibraryGroup, object: nil)

        // ---------------------------------------------------------------------
        //  Setup Table Column
        // ---------------------------------------------------------------------
        let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "MainWindowOutlineViewTableColumn"))
        tableColumn.isEditable = true

        // ---------------------------------------------------------------------
        //  Setup OutlineView
        // ---------------------------------------------------------------------
        self.outlineView.addTableColumn(tableColumn)
        self.outlineView.translatesAutoresizingMaskIntoConstraints = true
        self.outlineView.selectionHighlightStyle = .sourceList
        self.outlineView.floatsGroupRows = false
        self.outlineView.rowSizeStyle = .default
        self.outlineView.headerView = nil
        self.outlineView.dataSource = self
        self.outlineView.delegate = self
        self.outlineView.registerForDraggedTypes(kMainWindowDragDropUTIs)

        // Things I've tried to remove the separator between the views in the outline view
        /*
         self.outlineView.gridColor = .clear
         self.outlineView.gridStyleMask = NSTableViewGridLineStyle(rawValue: 0)
         self.outlineView.intercellSpacing = NSZeroSize
         */

        // ---------------------------------------------------------------------
        //  Setup ScrollView
        // ---------------------------------------------------------------------
        self.scrollView.documentView = self.outlineView
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.autoresizesSubviews = true

        // ---------------------------------------------------------------------
        //  Add all parent views to outline view
        // ---------------------------------------------------------------------
        addParents()

        // ---------------------------------------------------------------------
        //  Expand the first two parents (All Profiles & Library which can't show/hide later)
        // ---------------------------------------------------------------------
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        self.outlineView.expandItem(self.parents[0], expandChildren: false)
        self.outlineView.expandItem(self.parents[1], expandChildren: false)
        NSAnimationContext.endGrouping()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .didAddGroup, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didAddProfile, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didSaveProfile, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didRemoveProfilesFromGroup, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didChangePayloadLibraryGroup, object: nil)
    }

    // MARK: -
    // MARK: Private Functions

    private func addParents() {

        // ---------------------------------------------------------------------
        //  Add parent item: "All Profiles"
        // ---------------------------------------------------------------------
        let allProfiles = MainWindowAllProfiles(outlineViewController: self)
        self.parents.append(allProfiles)

        // ---------------------------------------------------------------------
        //  Store the "All Profiles" group in it's own instance variable for future use
        // ---------------------------------------------------------------------
        if let allProfilesGroup = allProfiles.children.first {
            self.allProfilesGroup = allProfilesGroup
        }

        self.addParentGroups()

        // ---------------------------------------------------------------------
        //  Reload the outline view after adding items
        // ---------------------------------------------------------------------
        self.reloadOutlineView()
    }

    private func addParentGroups() {

        // ---------------------------------------------------------------------
        //  Add parent item: "Library"
        // ---------------------------------------------------------------------
        let parentLibrary = MainWindowLibrary(title: SidebarGroupTitle.library, group: .library, groupFolderURL: nil, outlineViewController: self)
        self.parents.append(parentLibrary)
        self.parentLibrary = parentLibrary

        let parentLibraryJSS = MainWindowLibraryJSS(outlineViewController: self)
        self.parentLibraryJSS = parentLibraryJSS

        // ---------------------------------------------------------------------
        //  Add parent item: "JSS"
        // ---------------------------------------------------------------------
        if !parentLibraryJSS.children.isEmpty {
            self.parents.append(parentLibraryJSS)
        }

        // TODO: - Add more parent groups here like:
        //         JSS/MDM Profiles
        //         Local Profiles
    }

    // -------------------------------------------------------------------------
    //  Convenience method to reaload data in outline view and keep current selection
    // -------------------------------------------------------------------------
    private func reloadOutlineView() {
        let selectedRowIndexes = self.outlineView.selectedRowIndexes
        self.outlineView.reloadData()
        self.outlineView.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
    }

    func removeItems(atIndexes: IndexSet) {

        var firstItemParent: OutlineViewParentItem?
        var itemsToRemove = [OutlineViewChildItem]()

        // ---------------------------------------------------------------------
        //  Get all group instances to remove
        // ---------------------------------------------------------------------
        for row in atIndexes {
            if let group = self.outlineView.item(atRow: row) as? OutlineViewChildItem {
                if firstItemParent == nil, let parent = self.outlineView.parent(forItem: group) as? OutlineViewParentItem {
                    firstItemParent = parent
                }
                itemsToRemove.append(group)
            }
        }

        // ---------------------------------------------------------------------
        //  Verify a valid parent was found, else there will be inconsistencies after delete
        // ---------------------------------------------------------------------
        if let parent = firstItemParent {

            // -----------------------------------------------------------------
            //  Try to remove each group
            // -----------------------------------------------------------------
            for group in itemsToRemove {
                do {
                    try group.removeFromDisk()
                } catch {
                    Log.shared.error(message: "Failed to remove group: \(group.title) from disk with error: \(error)", category: String(describing: self))
                }

                if let selectedItem = self.selectedItem, group.title == selectedItem.title {
                    self.selectedItem = nil
                }

                if let index = parent.children.firstIndex(where: { $0.title == group.title }) {
                    parent.children.remove(at: index)
                }
            }

            self.reloadOutlineView()
        }
    }

    // MARK: -
    // MARK: Notification Functions

    @objc func didAddGroup(_ notification: NSNotification?) {

        // ---------------------------------------------------------------------
        //  Reload outline view if sender was any of the outline view parents
        // ---------------------------------------------------------------------
        guard let sender = notification?.object as? OutlineViewParentItem else {
            return
        }

        if !self.parents.contains(where: { $0.group == sender.group }) {
            self.parents.append(sender)
        }

        // ---------------------------------------------------------------------
        //  Get the group that was added
        // ---------------------------------------------------------------------
        guard
            let userInfo = notification?.userInfo,
            let group = userInfo[NotificationKey.group] as? OutlineViewChildItem else {
                return
        }

        // FIXME: Only checking identifiers feels weak, but as the protocol doesn't support equatable, this will do
        if self.parents.contains(where: { $0.identifier == sender.identifier }) {
            self.reloadOutlineView()

            // -----------------------------------------------------------------
            //  If the parent the group was added to isn't expanded, expand it
            // -----------------------------------------------------------------
            if !self.outlineView.isItemExpanded(sender) {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0
                self.outlineView.expandItem(sender)
                NSAnimationContext.endGrouping()
            }

            // -----------------------------------------------------------------
            //  Select the user added group
            // -----------------------------------------------------------------
            let row = self.outlineView.row(forItem: group)
            if 0 <= row {
                self.outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            }
        }
    }

    @objc func didChangePayloadLibraryGroup(_ notification: NSNotification?) {
        let parentIndexMax = (self.parents.count - 1)
        if parentIndexMax <= 0 { return }
        let parentIndexSet = IndexSet(1...parentIndexMax)
        self.outlineView.removeItems(at: IndexSet(1...parentIndexMax), inParent: nil, withAnimation: NSTableView.AnimationOptions(rawValue: 0))
        self.parents.removeLast(parentIndexSet.count)
        self.addParentGroups()
        self.reloadOutlineView()
        for group in self.parents where !(group is MainWindowAllProfiles) {
            if !self.outlineView.isItemExpanded(group) {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0
                self.outlineView.expandItem(group)
                NSAnimationContext.endGrouping()
            }
        }

    }

    // -------------------------------------------------------------------------
    //  When a profile was added, add it to the selected group and the All Profiles group.
    //  NOTE: This notifications should not be implemented in the All Profiles group.
    //        Then it might update after the outline view has reloaded and it won't
    //        update the profile count or profile list.
    // -------------------------------------------------------------------------
    @objc func didAddProfile(_ notification: NSNotification?) {

        // ---------------------------------------------------------------------
        //  Get passed identifier and verify that something is selected
        // ---------------------------------------------------------------------
        guard let selectedItem = self.selectedItem,
            let userInfo = notification?.userInfo,
            let identifier = userInfo[SettingsKey.identifier] as? UUID else {
                return
        }

        // ---------------------------------------------------------------------
        //  Add identifier to the "All Profiles" group
        // ---------------------------------------------------------------------
        if let allProfilesGroup = self.allProfilesGroup {
            allProfilesGroup.addProfiles(withIdentifiers: [identifier])
        }

        // ---------------------------------------------------------------------
        //  Add identifier to the selected group (If it's not the "All Profiles" group)
        // ---------------------------------------------------------------------
        if !(selectedItem is MainWindowAllProfilesGroup) {
            selectedItem.addProfiles(withIdentifiers: [identifier])
        }

        // ---------------------------------------------------------------------
        //  Notify delegate that the selected item was updated
        // ---------------------------------------------------------------------
        if let delegateMethod = self.selectionDelegate?.updated {
            delegateMethod(selectedItem, self)
        }

        reloadOutlineView()
    }

    @objc func didSaveProfile(_ notification: NSNotification?) {

        // ---------------------------------------------------------------------
        //  Reload outline view when a profile was saved
        // ---------------------------------------------------------------------
        reloadOutlineView()
    }

    @objc func didRemoveProfilesFromGroup(_ notification: NSNotification?) {

        // ---------------------------------------------------------------------
        //  Reload outline view when a profile was removed
        // ---------------------------------------------------------------------
        reloadOutlineView()
    }
}

extension MainWindowOutlineViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let parentItem = item as? OutlineViewParentItem {
            return parentItem.children.count
        } else {
            return self.parents.count
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let parentItem = item as? OutlineViewParentItem {
            return parentItem.children[index]
        } else {
            return self.parents[index]
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        item is OutlineViewParentItem ? true : false
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if tableColumn?.identifier == .tableColumnMainWindowOutlineView, let outlineViewItem = item as? OutlineViewItem {
            return outlineViewItem.title
        }
        return "-"
    }

    // MARK: Drag/Drop Support

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {

        let pasteboard = info.draggingPasteboard

        guard let availableType = pasteboard.availableType(from: kMainWindowDragDropUTIs) else { return NSDragOperation() }

        if availableType == .backwardsCompatibleFileURL, pasteboard.canReadObject(forClasses: [NSURL.self], options: kMainWindowDragDropFilteringOptions), item is OutlineViewChildItem {
            return NSDragOperation.copy
        } else if availableType == .profile, let group = item as? OutlineViewChildItem, group.isEditable {
            if let selectedItem = self.selectedItem, selectedItem.hash == group.hash {
                return NSDragOperation()
            } else {
                return (info.draggingSourceOperationMask == NSDragOperation.copy ? NSDragOperation.copy : NSDragOperation.move)
            }
        }
        return NSDragOperation()
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pasteboard = info.draggingPasteboard

        if let draggingData = pasteboard.data(forType: .profile) {
            do {
                let profileIdentifiers = try JSONDecoder().decode([UUID].self, from: draggingData)
                if let child = item as? OutlineViewChildItem {
                    child.addProfiles(withIdentifiers: profileIdentifiers)
                    self.reloadOutlineView()
                    return true
                }
            } catch {
                Log.shared.error(message: "Failed to decode dropped item: \(info)", category: String(describing: self))
            }
        } else if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: kMainWindowDragDropFilteringOptions) as? [URL] {
            ProfileImport.shared.importMobileconfigs(atURLs: urls) { profileIdentifiers in
                    if let child = item as? OutlineViewChildItem {
                        child.addProfiles(withIdentifiers: profileIdentifiers)
                        DispatchQueue.main.async {
                            self.reloadOutlineView()
                        }
                    }
            }
            return true
        }
        return false
    }
}

extension MainWindowOutlineViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {

        // ---------------------------------------------------------------------
        //  Returns true for all OutlineViewParentItems
        // ---------------------------------------------------------------------
        return item is OutlineViewParentItem
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {

        // ---------------------------------------------------------------------
        //  Returns true for all OutlineViewChildItems
        // ---------------------------------------------------------------------
        return item is OutlineViewChildItem
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {

        // ---------------------------------------------------------------------
        //  Updates internal selection state and notifies delegate of the new selection
        // ---------------------------------------------------------------------
        let selectedRowIndexes = self.outlineView.selectedRowIndexes
        if !selectedRowIndexes.isEmpty {

            // -----------------------------------------------------------------
            //  Assumes MainWindowLibraryGroup and that only one selection is possible.
            //  This might change in a future release and need update
            // -----------------------------------------------------------------
            if let selectedItem = self.outlineView.item(atRow: selectedRowIndexes.first!) as? OutlineViewChildItem {
                self.selectedItem = selectedItem

                // -------------------------------------------------------------
                //  Pass the selected item to the selectionDelegate (if it's set)
                // -------------------------------------------------------------
                if let delegateMethod = self.selectionDelegate?.selected {
                    delegateMethod(selectedItem, self)
                }
            }
        }
    }

    func outlineViewItemDidExpand(_ notification: Notification) {
        // TODO: Implement
    }

    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        if let library = item as? MainWindowLibrary {
            return library.group != .library
        }
        return true
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let parent = item as? OutlineViewParentItem {
            return parent.cellView
        } else if let child = item as? OutlineViewChildItem {
            child.cellView?.updateView()
            return child.cellView
        }
        return nil
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is MainWindowAllProfiles {

            // ------------------------------------------------------------------
            //  Ugly fix to hide the AllProfiles parent view, setting it's height to 0
            // -----------------------------------------------------------------
            // return 0
        } else if item is OutlineViewParentItem {
            return 18
        }
        return 22
    }
}

extension MainWindowOutlineViewController: MainWindowOutlineViewDelegate {

    func shouldRemoveItems(atIndexes: IndexSet) {

        // ---------------------------------------------------------------------
        //  Verify there is a mainWindow present
        // ---------------------------------------------------------------------
        guard let mainWindow = NSApplication.shared.mainWindow  else {
            return
        }

        // ---------------------------------------------------------------------
        //  Create the alert message depending on how may groups were selected
        //  Currently only one is allowed to be selected, that might change in a future release.
        // ---------------------------------------------------------------------
        var alertMessage = ""
        var removedSelected: Bool = false

        if atIndexes.count == 1 {
            if let row = atIndexes.first, let item = self.outlineView.item(atRow: row) as? OutlineViewChildItem, !item.isEditing {
                alertMessage = NSLocalizedString("Are you sure you want to delete the group: \"\(item.title)\"?", comment: "")
                if let selectedItem = self.selectedItem, item.hash == selectedItem.hash {
                    removedSelected = true
                }
            } else {
                return
            }
        } else {
            alertMessage = NSLocalizedString("Are you sure you want to delete the following groups:\n", comment: "")
            for row in atIndexes {
                if let item = self.outlineView.item(atRow: row) as? OutlineViewChildItem, !item.isEditing {
                    alertMessage += "\t\(item.title)\n"
                    if let selectedItem = self.selectedItem, item.hash == selectedItem.hash {
                        removedSelected = true
                    }
                } else {
                    return
                }
            }
        }

        let alertInformativeText = NSLocalizedString("No profile will be removed.", comment: "")

        // ---------------------------------------------------------------------
        //  Show remove group alert to user
        // ---------------------------------------------------------------------
        self.alert = Alert()
        self.alert?.showAlertDelete(message: alertMessage, informativeText: alertInformativeText, window: mainWindow) { delete in
            if delete {
                self.removeItems(atIndexes: atIndexes)
                if removedSelected {
                    self.outlineView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
                }
            }
        }
    }
}
