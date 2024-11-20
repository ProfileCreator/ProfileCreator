//
//  MainWindowTableView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

// MARK: -
// MARK: Protocols
// MAKR: -

protocol MainWindowTableViewDelegate: AnyObject {
    func shouldRemoveItems(atIndexes: IndexSet)
    func profileIdentifier(atRow: Int) -> UUID?
}

// MARK: -
// MARK: Classes
// MAKR: -

class MainWindowTableViewController: NSObject, MainWindowOutlineViewSelectionDelegate, MainWindowTableViewDelegate {

    // MARK: -
    // MARK: Variables

    let tableView = MainWindowTableView()
    let cellView = MainWindowTableViewCellView()
    let scrollView = OverlayScrollView(frame: NSRect.zero)

    var alert: Alert?
    var updateSelectedProfileIdentifiers = true
    var selectedProfileGroup: OutlineViewChildItem?
    var selectedProfileIdentitifers: [UUID]?

    // MARK: -
    // MARK: Initialization

    override init() {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Table Column
        // ---------------------------------------------------------------------
        let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "MainWindowTableViewTableColumn"))
        tableColumn.isEditable = false

        // ---------------------------------------------------------------------
        //  Setup TableView
        // ---------------------------------------------------------------------
        self.tableView.addTableColumn(tableColumn)
        self.tableView.translatesAutoresizingMaskIntoConstraints = true
        self.tableView.floatsGroupRows = false
        self.tableView.rowSizeStyle = .default
        self.tableView.headerView = nil
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.target = self
        self.tableView.doubleAction = #selector(self.editProfile(tableView:))
        self.tableView.allowsMultipleSelection = true
        self.tableView.registerForDraggedTypes(kMainWindowDragDropUTIs)

        // Things I've tried to remove the separator between the views in the outline view
        /*
         self.tableView.gridColor = .clear
         self.tableView.gridStyleMask = NSTableViewGridLineStyle(rawValue: 0)
         self.tableView.intercellSpacing = NSZeroSize
         */

        // ---------------------------------------------------------------------
        //  Setup ScrollView
        // ---------------------------------------------------------------------
        self.scrollView.documentView = self.tableView
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.autoresizesSubviews = true

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        NotificationCenter.default.addObserver(self, selector: #selector(didRemoveProfilesFromGroup(_:)), name: .didRemoveProfilesFromGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didSaveProfile(_:)), name: .didSaveProfile, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .didRemoveProfilesFromGroup, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didSaveProfile, object: nil)
    }

    // MARK: -
    // MARK: MainWindowOutlineViewDelegate Functions

    func selected(item: OutlineViewChildItem, sender: Any?) {
        self.selectedProfileGroup = item
        self.reloadTableView(updateSelection: (self.selectedProfileIdentitifers != nil) ? true : false)
    }

    func updated(item: OutlineViewChildItem, sender: Any?) {
        // TODO: Another weak check using the identifier because it isn't equatable
        if let selectedProfileGroup = self.selectedProfileGroup, selectedProfileGroup.identifier == item.identifier {
            reloadTableView()
        }
    }

    // MARK: -
    // MARK: TableView Actions

    @objc func editProfile(tableView: NSTableView) {
        if
            0 <= self.tableView.clickedRow,
            let identifier = self.profileIdentifier(atRow: self.tableView.clickedRow) {
            ProfileController.sharedInstance.editProfile(withIdentifier: identifier)
        } else {
            Log.shared.error(message: "Failed to get identifier for selected profile.", category: String(describing: self))
        }
    }

    // MARK: -
    // MARK: Notification Functions

    @objc func didRemoveProfilesFromGroup(_ notification: NSNotification?) {
        guard let group = notification?.object as? OutlineViewChildItem, group.identifier == self.selectedProfileGroup?.identifier else {
            return
        }

        if
            let userInfo = notification?.userInfo,
            let indexSet = userInfo[NotificationKey.indexSet] as? IndexSet,
            let indexLast = indexSet.last,
            let profileIdentifiers = self.selectedProfileGroup?.profileIdentifiers,
            !profileIdentifiers.isEmpty {

            var newIndex = (indexLast - indexSet.count)
            if newIndex < 0 { newIndex = 0 }

            self.tableView.reloadData()
            self.tableView.selectRowIndexes(IndexSet(integer: newIndex), byExtendingSelection: false)
        }

        self.tableViewSelectionDidChange(Notification(name: .emptyNotification))
    }

    @objc func didSaveProfile(_ notification: NSNotification?) {
        if
            let userInfo = notification?.userInfo,
            let profileIdentifier = userInfo[NotificationKey.identifier] as? UUID,
            let groupProfileIdentifiers = self.selectedProfileGroup?.profileIdentifiers,
            groupProfileIdentifiers.contains(profileIdentifier) {
            self.reloadTableView()
        }
    }

    // -------------------------------------------------------------------------
    //  Convenience method to reaload data in table view and keep current selection
    // -------------------------------------------------------------------------
    private func reloadTableView(updateSelection: Bool = true) {
        var rowIndexesToSelect: IndexSet?

        // ---------------------------------------------------------------------
        //  Verify that the group has atleast one identifier, else just reload and don't select anything
        // ---------------------------------------------------------------------
        guard let groupProfileIdentifiers = self.selectedProfileGroup?.profileIdentifiers, !groupProfileIdentifiers.isEmpty else {
            self.tableView.reloadData()
            return
        }

        // ---------------------------------------------------------------------
        //  Get the indexes of the currently selected profile(s)
        // ---------------------------------------------------------------------
        if let selectedIdentifiers = self.selectedProfileIdentitifers {
            rowIndexesToSelect = groupProfileIdentifiers.indexes(ofItems: selectedIdentifiers)
        }

        self.tableView.reloadData()

        // ---------------------------------------------------------------------
        //  Select all currently selected profiles that exist in the group
        // ---------------------------------------------------------------------
        if let indexes = rowIndexesToSelect {
            self.updateSelectedProfileIdentifiers = updateSelection
            self.tableView.selectRowIndexes(indexes, byExtendingSelection: false)
        }
    }

    func removeItems(atIndexes: IndexSet, withIdentifiers: [UUID]) {
        if let selectedProfileGroup = self.selectedProfileGroup {
            selectedProfileGroup.removeProfiles(atIndexes: atIndexes, withIdentifiers: withIdentifiers)
        }
    }

    func shouldRemoveItems(atIndexes: IndexSet) {

        // ---------------------------------------------------------------------
        //  Verify there is a mainWindow present
        // ---------------------------------------------------------------------
        guard !atIndexes.isEmpty,
            let mainWindow = NSApplication.shared.mainWindow,
            let selectedProfileGroup = self.selectedProfileGroup else {
                return
        }

        // ---------------------------------------------------------------------
        //  Create the alert message depending on how may groups were selected
        //  Currently only one is allowed to be selected, that might change in a future release.
        // ---------------------------------------------------------------------
        var identifiers = [UUID]()
        var alertMessage = ""
        var alertInformativeText = ""

        if selectedProfileGroup is MainWindowAllProfilesGroup {
            if atIndexes.count == 1 {
                let identifier = selectedProfileGroup.profileIdentifiers[atIndexes.first!]
                identifiers.append(identifier)

                let title = ProfileController.sharedInstance.titleOfProfile(withIdentifier: identifier)
                alertMessage = NSLocalizedString("Are you sure you want to delete the profile \"\(title ?? identifier.uuidString)\"?", comment: "")
                alertInformativeText = NSLocalizedString("This cannot be undone", comment: "")
            } else {
                alertMessage = NSLocalizedString("Are you sure you want to delete the following profiles?", comment: "")
                for index in atIndexes {
                    let identifier = selectedProfileGroup.profileIdentifiers[index]
                    identifiers.append(identifier)

                    let title = ProfileController.sharedInstance.titleOfProfile(withIdentifier: identifier)
                    alertInformativeText += "\t\(title ?? identifier.uuidString)\n"
                }
                alertInformativeText += NSLocalizedString("\nThis cannot be undone", comment: "")
            }
        } else {
            if atIndexes.count == 1 {
                let identifier = selectedProfileGroup.profileIdentifiers[atIndexes.first!]
                identifiers.append(identifier)

                let title = ProfileController.sharedInstance.titleOfProfile(withIdentifier: identifier)
                alertMessage = NSLocalizedString("Are you sure you want to remove the profile \"\(title ?? identifier.uuidString)\" from group \"\(selectedProfileGroup.title)\"?", comment: "")
                alertInformativeText = NSLocalizedString("The profile will still be available under \"All Profiles\"", comment: "")
            } else {
                alertMessage = NSLocalizedString("Are you sure you want to remove the following profiles from group \"\(selectedProfileGroup.title)\"?", comment: "")
                for index in atIndexes {
                    let identifier = selectedProfileGroup.profileIdentifiers[index]
                    identifiers.append(identifier)

                    let title = ProfileController.sharedInstance.titleOfProfile(withIdentifier: identifier)
                    alertInformativeText += "\t\(title ?? identifier.uuidString)\n"
                }
                alertInformativeText += NSLocalizedString("\nAll profiles will still be available under \"All Profiles\"", comment: "")
            }
        }

        // ---------------------------------------------------------------------
        //  Show remove profile alert to user
        // ---------------------------------------------------------------------
        self.alert = Alert()
        self.alert?.showAlertDelete(message: alertMessage, informativeText: alertInformativeText, window: mainWindow) { delete in
            if delete {
                self.removeItems(atIndexes: atIndexes, withIdentifiers: identifiers)
            }
        }
    }

    func profileIdentifier(atRow: Int) -> UUID? {
        if let selectedProfileGroup = self.selectedProfileGroup, atRow < selectedProfileGroup.profileIdentifiers.count {
            return selectedProfileGroup.profileIdentifiers[atRow]
        }
        return nil
    }

    func profileIdentifiers(atIndexes indexes: IndexSet) -> [UUID]? {
        if let selectedProfileGroup = self.selectedProfileGroup {
            return selectedProfileGroup.profileIdentifiers.objectsAtIndexes(indexes: indexes)
        }
        return nil
    }
}

extension MainWindowTableViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        if let selectedProfileGroup = self.selectedProfileGroup {
            return selectedProfileGroup.profileIdentifiers.count
        }
        return 0
    }

    // -------------------------------------------------------------------------
    //  Drag/Drop Support
    // -------------------------------------------------------------------------
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        let pasteboard = info.draggingPasteboard
        guard let availableType = pasteboard.availableType(from: kMainWindowDragDropUTIs) else { return NSDragOperation() }
        if availableType == .backwardsCompatibleFileURL, pasteboard.canReadObject(forClasses: [NSURL.self], options: kMainWindowDragDropFilteringOptions) {
            tableView.setDropRow(-1, dropOperation: .on)
            return .copy
        }
        return NSDragOperation()
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        if let selectedGroup = self.selectedProfileGroup {
            return selectedGroup.outlineViewController.outlineView(selectedGroup.outlineViewController.outlineView, acceptDrop: info, item: selectedGroup, childIndex: 0)
        }
        return false
    }

    func tableView(_ tableView: NSTableView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo) {
        if let draggingData = draggingInfo.draggingPasteboard.data(forType: .profile) {
            do {
                let profileIdentifiers = try JSONDecoder().decode([UUID].self, from: draggingData)
                draggingInfo.numberOfValidItemsForDrop = profileIdentifiers.count
            } catch {
                Log.shared.error(message: "Failed to decode dragged item: \(draggingInfo)", category: String(describing: self))
            }
        }
    }

    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        guard let allProfileIdentifiers = self.selectedProfileGroup?.profileIdentifiers else { return false }
        do {
            let encodedData = try JSONEncoder().encode(allProfileIdentifiers.objectsAtIndexes(indexes: rowIndexes))
            pboard.clearContents()
            pboard.declareTypes([.profile], owner: nil)
            pboard.setData(encodedData, forType: .profile)
        } catch {
            Log.shared.error(message: "Failed to encode payloads with error: \(error)", category: String(describing: self))
        }

        return true
    }

    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if operation == .move {

            // -----------------------------------------------------------------
            //  Verify a group is selected and editable (as we are to remove items from this group)
            // -----------------------------------------------------------------
            guard let selectedProfileGroup = self.selectedProfileGroup, selectedProfileGroup.isEditable else {
                return
            }

            // -----------------------------------------------------------------
            //  Verify a valid profile identifier array is passed
            // -----------------------------------------------------------------
            guard let draggingData = session.draggingPasteboard.data(forType: .profile) else {
                return
            }

            do {
                let profileIdentifiers = try JSONDecoder().decode([UUID].self, from: draggingData)

                // -----------------------------------------------------------------
                //  Remove the passed profile identifiers from the current group
                // -----------------------------------------------------------------
                selectedProfileGroup.removeProfiles(withIdentifiers: profileIdentifiers)

                reloadTableView()
            } catch {
                Log.shared.error(message: "Failed to decode dragged items", category: String(describing: self))
            }
        }
    }
}

// FIXME: A "bug" where if you select 4 profiles in one group, then select another group where only 1 profile of the four is present,
// then if you click that profile when it's selected the selection doesnt change, as it is the only selection, even if the internal selection state is 4 and won't change.
// You need to click another profile or outside to get the selection to update. This should be fixed

extension MainWindowTableViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        36
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let selectedProfileGroup = self.selectedProfileGroup, row < selectedProfileGroup.profileIdentifiers.count else {
            return nil
        }

        let identifier = selectedProfileGroup.profileIdentifiers[row]
        guard let profile = ProfileController.sharedInstance.profile(withIdentifier: identifier) else { return nil }

        return self.cellView.cellView(title: profile.settings.title, identifier: identifier, payloadCount: profile.enabledPayloadsCount, errorCount: 0, versionFormatSupported: profile.versionFormatSupported)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if self.updateSelectedProfileIdentifiers {
            guard let profileIdentifiers = self.selectedProfileGroup?.profileIdentifiers as NSArray?,
                let selectedProfileIdentifiers = profileIdentifiers.objects(at: self.tableView.selectedRowIndexes) as? [UUID] else {
                    return
            }

            self.selectedProfileIdentitifers = selectedProfileIdentifiers

            // FIXME: Replace this with a delegate call maybe? If it's only there to update selection of the preview
            NotificationCenter.default.post(name: .didChangeProfileSelection, object: self, userInfo: [NotificationKey.identifiers: selectedProfileIdentifiers,
                                                                                                       NotificationKey.indexSet: self.tableView.selectedRowIndexes])
        } else {
            self.updateSelectedProfileIdentifiers = true
        }
    }
}

class MainWindowTableView: NSTableView {

    // MARK: -
    // MARK: Variables

    var clickedProfile: UUID?
    var clickedProfileRow: Int = -1
    var clickedProfileInSelection: Bool = false

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: NSRect.zero)
    }

    // -------------------------------------------------------------------------
    //  Override menu(for event:) to show a contextual menu
    // -------------------------------------------------------------------------
    override func menu(for event: NSEvent) -> NSMenu? {

        // ---------------------------------------------------------------------
        //  Get row that was clicked
        // ---------------------------------------------------------------------
        let point = self.convert(event.locationInWindow, from: nil)
        self.clickedProfileRow = self.row(at: point)
        if self.clickedProfileRow == -1 {
            return nil
        }

        // ---------------------------------------------------------------------
        //  Verify a MainWindowLibraryGroup was clicked, else don't return a menu
        // ---------------------------------------------------------------------
        guard
            let delegate = self.delegate as? MainWindowTableViewDelegate,
            let clickedProfileIdentifier = delegate.profileIdentifier(atRow: self.clickedProfileRow) else {
                return nil
        }

        self.clickedProfile = clickedProfileIdentifier
        let selectedRowIndexes = self.selectedRowIndexes

        /*
         TODO: Here I wanted to draw the blue focus ring around the views affected by the right click action.
         It should do that by defaut (?) but doesn't. I haven't found a good way to force that either.

         if let clickedView = self.rowView(atRow: self.clickedProfileRow, makeIfNecessary: false) {
         clickedView.focusRingType = .exterior
         }
         */

        // ---------------------------------------------------------------------
        //  Create menu
        // ---------------------------------------------------------------------
        let menu = NSMenu()

        // ---------------------------------------------------------------------
        //  Get the clicked profile's title
        // ---------------------------------------------------------------------
        let profileTitle = ProfileController.sharedInstance.titleOfProfile(withIdentifier: clickedProfileIdentifier) ?? clickedProfileIdentifier.uuidString

        // ---------------------------------------------------------------------
        //  Add item: "Edit <Profile>"
        // ---------------------------------------------------------------------
        let menuItemEdit = NSMenuItem()
        if 1 < selectedRowIndexes.count, selectedRowIndexes.contains(self.clickedProfileRow) {
            menuItemEdit.title = NSLocalizedString("Edit \(selectedRowIndexes.count) Profiles", comment: "")
        } else {
            menuItemEdit.title = NSLocalizedString("Edit \"\(profileTitle)\"", comment: "")
        }
        menuItemEdit.identifier = NSUserInterfaceItemIdentifier("edit")
        menuItemEdit.target = self
        menuItemEdit.action = #selector(self.editProfile(_:))
        menu.addItem(menuItemEdit)

        // ---------------------------------------------------------------------
        //  Add item: "Duplicate <Profile>"
        // ---------------------------------------------------------------------
        let menuItemDuplicate = NSMenuItem()
        if 1 < selectedRowIndexes.count, selectedRowIndexes.contains(self.clickedProfileRow) {
            menuItemDuplicate.title = NSLocalizedString("Duplicate", comment: "")
        } else {
            menuItemDuplicate.title = NSLocalizedString("Duplicate \"\(profileTitle)\"", comment: "")
        }
        menuItemDuplicate.identifier = .menuItemDuplicate
        menuItemDuplicate.target = self
        menuItemDuplicate.action = #selector(self.duplicateProfile(_:))
        menu.addItem(menuItemDuplicate)

        // ---------------------------------------------------------------------
        //  Add item: "Export <Profile>"
        // ---------------------------------------------------------------------
        let menuItemExport = NSMenuItem()
        // FIXME: Does not currently support exporting multiple profiles.
        if 1 < selectedRowIndexes.count, selectedRowIndexes.contains(self.clickedProfileRow) {
            menuItemExport.title = NSLocalizedString("Export", comment: "")
        } else {
            menuItemExport.title = NSLocalizedString("Export \"\(profileTitle)\"", comment: "")
        }
        menuItemExport.identifier = .menuItemExport // NSUserInterfaceItemIdentifier("export")
        menuItemExport.target = self
        menuItemExport.action = #selector(self.exportProfile(_:))
        menu.addItem(menuItemExport)

        // ---------------------------------------------------------------------
        //  Add item: "Show In Finder"
        // ---------------------------------------------------------------------
        let menuItemShowInFinder = NSMenuItem()
        if 1 < selectedRowIndexes.count, selectedRowIndexes.contains(self.clickedProfileRow) {
            menuItemShowInFinder.title = NSLocalizedString("Show \(selectedRowIndexes.count) Profiles In Finder", comment: "")
        } else {
            menuItemShowInFinder.title = NSLocalizedString("Show \"\(profileTitle)\" In Finder", comment: "")
        }

        menuItemShowInFinder.identifier = NSUserInterfaceItemIdentifier("showInFinder")
        menuItemShowInFinder.target = self
        menuItemShowInFinder.action = #selector(self.showInFinder(_:))
        menu.addItem(menuItemShowInFinder)

        // ---------------------------------------------------------------------
        //  Add item: "Delete"
        // ---------------------------------------------------------------------
        var deleteString: String
        if 1 < selectedRowIndexes.count, selectedRowIndexes.contains(self.clickedProfileRow) {
            deleteString = NSLocalizedString("Delete \(selectedRowIndexes.count) Profiles", comment: "")
        } else {
            deleteString = NSLocalizedString("Delete", comment: "")
        }

        let menuItemDelete = NSMenuItem()
        menuItemDelete.title = deleteString
        menuItemDelete.identifier = NSUserInterfaceItemIdentifier("delete")
        menuItemDelete.target = self
        menuItemDelete.action = #selector(self.removeSelectedProfiles(_:))
        menu.addItem(menuItemDelete)

        // ---------------------------------------------------------------------
        //  Return menu
        // ---------------------------------------------------------------------
        return menu
    }

    // -------------------------------------------------------------------------
    //  Override keyDown to catch backspace to delete item in table view
    // -------------------------------------------------------------------------
    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == String(Character(UnicodeScalar(NSEvent.SpecialKey.delete.rawValue)!)) {
            if let delegate = self.delegate as? MainWindowTableViewDelegate, !self.selectedRowIndexes.isEmpty {
                delegate.shouldRemoveItems(atIndexes: self.selectedRowIndexes)
            }
        }
        super.keyDown(with: event)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.identifier {
        case .menuItemDuplicate?,
             .menuItemExport?: // "export":
            return (self.selectedRowIndexes.contains(self.clickedProfileRow) && 1 < self.selectedRowIndexes.count) ? false : true
        default:
            return true
        }
    }

    @objc func editProfile(_ sender: NSTableView?) {
        if 1 < selectedRowIndexes.count, selectedRowIndexes.contains(self.clickedProfileRow) {
            guard let delegate = self.delegate as? MainWindowTableViewDelegate else { return }
            for row in self.selectedRowIndexes {
                if let profileIdentifier = delegate.profileIdentifier(atRow: row) {
                    ProfileController.sharedInstance.editProfile(withIdentifier: profileIdentifier)
                }
            }
        } else if let clickedIdentifier = self.clickedProfile {
            ProfileController.sharedInstance.editProfile(withIdentifier: clickedIdentifier)
        }
    }

    @objc func duplicateProfile(_ sender: NSTableView?) {
        if 1 < selectedRowIndexes.count, selectedRowIndexes.contains(self.clickedProfileRow) {
            guard let delegate = self.delegate as? MainWindowTableViewDelegate else { return }
            for row in self.selectedRowIndexes {
                if let profileIdentifier = delegate.profileIdentifier(atRow: row) {
                    ProfileController.sharedInstance.duplicateProfile(withIdentifier: profileIdentifier, promptWindow: nil)
                }
            }
        } else if let clickedIdentifier = self.clickedProfile {
            ProfileController.sharedInstance.duplicateProfile(withIdentifier: clickedIdentifier, promptWindow: nil)
        }
    }

    @objc func exportProfile(_ sender: NSTableView?) {
        if let clickedIdentifier = self.clickedProfile {
            ProfileController.sharedInstance.exportProfile(withIdentifier: clickedIdentifier, promptWindow: nil)
        }
    }

    @objc func showInFinder(_ sender: NSTableView?) {
        var profileURLs = [URL]()
        if 1 < selectedRowIndexes.count, selectedRowIndexes.contains(self.clickedProfileRow) {
            guard let delegate = self.delegate as? MainWindowTableViewDelegate else { return }
            for row in self.selectedRowIndexes {
                if
                    let profileIdentifier = delegate.profileIdentifier(atRow: row),
                    let profile = ProfileController.sharedInstance.profile(withIdentifier: profileIdentifier),
                    let profileURL = profile.fileURL {
                    profileURLs.append(profileURL)
                }
            }
        } else if
            let clickedIdentifier = self.clickedProfile,
            let profile = ProfileController.sharedInstance.profile(withIdentifier: clickedIdentifier),
            let profileURL = profile.fileURL {
            profileURLs.append(profileURL)
        }

        if !profileURLs.isEmpty {
            NSWorkspace.shared.activateFileViewerSelecting(profileURLs)
        }
    }

    @objc func removeSelectedProfiles(_ sender: Any?) {
        guard let delegate = self.delegate as? MainWindowTableViewDelegate else { return }
        if 1 < selectedRowIndexes.count, selectedRowIndexes.contains(self.clickedProfileRow) {
            delegate.shouldRemoveItems(atIndexes: self.selectedRowIndexes)
        } else {
            if self.clickedProfile != nil, self.clickedProfileRow != -1 {
                delegate.shouldRemoveItems(atIndexes: IndexSet(integer: self.clickedProfileRow))
            }
        }
    }
}

extension MainWindowTableView: NSMenuDelegate {

    func menuDidClose(_ menu: NSMenu) {

        // ---------------------------------------------------------------------
        //  Reset variables set when menu was created
        // ---------------------------------------------------------------------
        self.clickedProfile = nil
        self.clickedProfileRow = -1
    }
}
