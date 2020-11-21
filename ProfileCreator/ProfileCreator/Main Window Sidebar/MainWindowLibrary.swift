//
//  MainWindowLibrary.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowLibrary: NSObject, OutlineViewParentItem, NSTextFieldDelegate {

    // MARK: -
    // MARK: Variables

    let isEditable = true
    let identifier = UUID()
    let title: String
    let group: SidebarGroup
    let groupFolderURL: URL

    var alert: Alert?
    var children = [OutlineViewChildItem]()
    var cellView: OutlineViewParentCellView?
    unowned var outlineViewController: MainWindowOutlineViewController

    // MARK: -
    // MARK: Initialization

    init(title: String, group: SidebarGroup, groupFolderURL: URL?, outlineViewController: MainWindowOutlineViewController) {

        self.title = title
        self.group = group
        if let groupURL = groupFolderURL {
            self.groupFolderURL = groupURL
        } else {
            self.groupFolderURL = URL(applicationDirectory: .groupLibrary) ?? URL(fileURLWithPath: "/")
        }
        self.outlineViewController = outlineViewController

        super.init()

        // ---------------------------------------------------------------------
        //  Setup the cell view for this outline view item
        // ---------------------------------------------------------------------
        self.cellView = OutlineViewParentCellView(parent: self)

        // ---------------------------------------------------------------------
        //  Load all saved groups from disk
        // ---------------------------------------------------------------------
        self.loadSavedGroups()

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        NotificationCenter.default.addObserver(self, selector: #selector(addGroup(_:)), name: .addGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRemoveProfiles(_:)), name: .didRemoveProfiles, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .addGroup, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didRemoveProfiles, object: nil)
    }

    // MARK: -
    // MARK: Instance Functions

    func loadSavedGroups() {

        var groupURLs = [URL]()

        // ---------------------------------------------------------------------
        //  Put all items from group folder into array
        // ---------------------------------------------------------------------
        do {
            groupURLs = try FileManager.default.contentsOfDirectory(at: self.groupFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch {
            if (error as NSError).code != NSFileReadNoSuchFileError {
                Log.shared.error(message: "Failed to read the contents of directory: \(self.groupFolderURL.path) with error: \(error)", category: String(describing: self))
            }
            return
        }

        // ---------------------------------------------------------------------
        //  Remove all items that doesn't have the FileExtension.group extension
        // ---------------------------------------------------------------------
        groupURLs = groupURLs.filter { $0.pathExtension == FileExtension.group }

        // ---------------------------------------------------------------------
        //  Loop through all group files and add them to the group
        // ---------------------------------------------------------------------
        for groupURL in groupURLs {
            do {
                let groupData = try Data(contentsOf: groupURL)
                guard let groupDict = try PropertyListSerialization.propertyList(from: groupData,
                                                                                 options: [],
                                                                                 format: nil) as? [String: Any] else {
                                                                                    continue
                }
                if !groupDict.isEmpty {

                    // Get Title
                    var title: String = ""
                    if let groupTitle = groupDict[SettingsKey.title] as? String { title = groupTitle }

                    // Get Identifier
                    let identifier: UUID
                    if let uuidString = groupDict[SettingsKey.identifier] as? String,
                        let theUUID = UUID(uuidString: uuidString) {
                        identifier = theUUID
                    } else { identifier = UUID() }

                    // Get Profile Identifiers
                    var profileIdentifiers = [UUID]()
                    if let uuidStrings = groupDict[SettingsKey.identifiers] as? [String] {
                        for uuidString in uuidStrings {
                            if let theUUID = UUID(uuidString: uuidString) {
                                profileIdentifiers.append(theUUID)
                            }
                        }
                    }

                    self.addGroup(title: title, identifier: identifier, profileIdentifiers: profileIdentifiers, dict: groupDict, writeToDisk: false)
                }
            } catch {
                Log.shared.error(message: "Failed to read the contents of group settings at: \(groupURL.path) with error: \(error)", category: String(describing: self))
            }
        }
    }

    func newGroup(title: String, identifier: UUID) -> MainWindowLibraryGroup {
        MainWindowLibraryGroup(title: title, identifier: identifier, parent: self, outlineViewController: self.outlineViewController)
    }

    func addGroup(title: String, identifier: UUID, profileIdentifiers: [UUID], dict: [String: Any], writeToDisk: Bool) {
        let group = self.newGroup(title: title, identifier: identifier)
        group.addProfiles(withIdentifiers: profileIdentifiers)

        if writeToDisk {
            self.save(group: group)
        } else {
            self.children.append(group)
        }
    }

    func save(group: MainWindowLibraryGroup) {
        do {
            try group.writeToDisk(title: self.title)
        } catch {
            Log.shared.error(message: "Failed to write group to disk with error: \(error)", category: String(describing: self))
        }

        self.children.append(group)
        NotificationCenter.default.post(name: .didAddGroup, object: self, userInfo: [NotificationKey.group: group])
    }

    func showAlertNewGroup(window: NSWindow) {

        // ---------------------------------------------------------------------
        //  Show add group alert with text field to user
        // ---------------------------------------------------------------------
        self.alert = Alert()
        self.alert!.showAlert(message: NSLocalizedString("New Library Group", comment: ""),
                              informativeText: NSLocalizedString("Enter a name for new library group to be created.", comment: ""),
                              window: window,
                              defaultString: nil,
                              placeholderString: nil,
                              firstButtonTitle: ButtonTitle.ok,
                              secondButtonTitle: ButtonTitle.cancel,
                              thirdButtonTitle: nil,
                              firstButtonState: true,
                              sender: self) { title, response in
                                if response == .alertFirstButtonReturn {
                                    self.addGroup(title: title, identifier: UUID(), profileIdentifiers: [], dict: [:], writeToDisk: true)
                                }
        }

        // ---------------------------------------------------------------------
        //  Select the text field in the alert sheet
        // ---------------------------------------------------------------------
        self.alert!.textFieldInput!.selectText(self)
    }

    // MARK: -
    // MARK: Notification Functions

    @objc func addGroup(_ notification: NSNotification?) {

        // ---------------------------------------------------------------------
        //  Verify that addGroup was called for this group
        // ---------------------------------------------------------------------
        guard let parentTitle = notification?.userInfo?[NotificationKey.parentTitle] as? String,
            parentTitle == self.title else {
                return
        }

        // ---------------------------------------------------------------------
        //  Verify there is a mainWindow present
        // ---------------------------------------------------------------------
        guard let mainWindow = NSApplication.shared.mainWindow  else {
            return
        }

        self.showAlertNewGroup(window: mainWindow)
    }

    @objc func didRemoveProfiles(_ notification: NSNotification?) {
        if let userInfo = notification?.userInfo,
            let identifiers = userInfo[NotificationKey.identifiers] as? [UUID],
            let indexSet = userInfo[NotificationKey.indexSet] as? IndexSet {
            for child in children {
                child.removeProfiles(atIndexes: indexSet, withIdentifiers: identifiers)
            }
        }
    }

    // MARK: -
    // MARK: NSTextFieldDelegate Functions

    // -------------------------------------------------------------------------
    //  Used when selecting a new group name to not allow duplicates
    // -------------------------------------------------------------------------
    func controlTextDidChange(_ notification: Notification) {

        // ---------------------------------------------------------------------
        //  Get current text in the text field
        // ---------------------------------------------------------------------
        guard let userInfo = notification.userInfo,
            let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
            let string = fieldEditor.textStorage?.string else {
                return
        }

        // ---------------------------------------------------------------------
        //  Get names of all current groups
        // ---------------------------------------------------------------------
        let currentTitles = self.children.map { $0.title }

        // ---------------------------------------------------------------------
        //  If current text in the text field is either:
        //   * Empty
        //   * Matches an existing group
        //  Disable the OK button.
        // ---------------------------------------------------------------------
        if let alert = self.alert {
            if alert.firstButton!.isEnabled && (string.isEmpty || currentTitles.contains(string)) {
                alert.firstButton!.isEnabled = false
            } else {
                alert.firstButton!.isEnabled = true
            }
        }
        // TODO: Implement
    }
}

class MainWindowLibraryGroup: NSObject, OutlineViewChildItem {

    // MARK: -
    // MARK: Variables

    var isEditable = true
    var isEditing = false
    var icon = NSImage(named: "SidebarFolder")
    var identifier: UUID
    var title: String
    let group: SidebarGroup
    var profileIdentifiers = [UUID]()
    var cellView: OutlineViewChildCellView?
    unowned var outlineViewController: MainWindowOutlineViewController

    // MARK: -
    // MARK: Initialization

    init(title: String, identifier: UUID?, parent: OutlineViewParentItem, outlineViewController: MainWindowOutlineViewController) {

        self.group = parent.group
        self.title = title
        self.identifier = (identifier != nil) ? identifier! : UUID()
        self.outlineViewController = outlineViewController

        super.init()

        // ---------------------------------------------------------------------
        //  Setup the cell view for this outline view item
        // ---------------------------------------------------------------------
        self.cellView = OutlineViewChildCellView(child: self)
    }

    // MARK: -
    // MARK: Instance Functions

    func groupDict() -> [String: Any] {

        // ---------------------------------------------------------------------
        //  Get all profile identifiers in group that have been saved to disk
        // ---------------------------------------------------------------------
        var profileIdentifierStrings = [String]()
        for identifier in self.profileIdentifiers {

            // ---------------------------------------------------------------------
            //  Get url to save at
            // ---------------------------------------------------------------------
            if let profile = ProfileController.sharedInstance.profile(withIdentifier: identifier) {

                // -------------------------------------------------------------
                //  Check if profile has been saved to disk at least once (If it has a URL assigned).
                //  If not, don't include it in the group on disk
                // -------------------------------------------------------------
                if profile.fileURL != nil {
                    profileIdentifierStrings.append(identifier.uuidString)
                }
            } else {
                Log.shared.error(message: "Found no profile with identifier: \(identifier)", category: String(describing: self))
            }
        }

        // ---------------------------------------------------------------------
        //  Create dict to save
        // ---------------------------------------------------------------------
        let groupDict: [String: Any] = [SettingsKey.title: self.title,
                                         SettingsKey.identifier: self.identifier.uuidString,
                                         SettingsKey.identifiers: profileIdentifierStrings]

        return groupDict
    }

    func writeToDisk(title: String) throws {

        // ---------------------------------------------------------------------
        //  Get url to save at
        // ---------------------------------------------------------------------
        // TODO: Proper Error
        guard let url = try self.url() else { throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil) }
        let groupDict = self.groupDict()

        // ---------------------------------------------------------------------
        //  Try to write the group dict to disk
        // ---------------------------------------------------------------------
        let groupData = try PropertyListSerialization.data(fromPropertyList: groupDict, format: .xml, options: 0)
        try groupData.write(to: url)
    }

    private func url() throws -> URL? {

        // ---------------------------------------------------------------------
        //  Get path to group save folder
        // ---------------------------------------------------------------------
        if let groupFolderURL = URL(applicationDirectory: .groupLibrary) {

            // -------------------------------------------------------------
            //  Try to create the folder if it doesn't exist
            // -------------------------------------------------------------
            try FileManager.default.createDirectory(at: groupFolderURL, withIntermediateDirectories: true, attributes: nil)
            return groupFolderURL.appendingPathComponent(self.identifier.uuidString).appendingPathExtension(FileExtension.group)
        }
        return nil
    }

    // MARK: -
    // MARK: OutlineViewChildItem Functions

    func addProfiles(withIdentifiers identifiers: [UUID]) {

        // ---------------------------------------------------------------------
        //  Add the passed identifiers
        // ---------------------------------------------------------------------
        self.profileIdentifiers = Array(Set(self.profileIdentifiers + identifiers))

        // ---------------------------------------------------------------------
        //  Save the new group contents to disk
        // ---------------------------------------------------------------------
        do {
            try self.writeToDisk(title: self.title)
        } catch {
            Log.shared.error(message: "Failed to write group to disk with error: \(error)", category: String(describing: self))
        }
    }

    func removeProfiles(withIdentifiers: [UUID]) {

        // ---------------------------------------------------------------------
        //  Check that the group contains atleast one of the passed identifiers
        // ---------------------------------------------------------------------
        if !Set(self.profileIdentifiers).isDisjoint(with: withIdentifiers) {

            // -----------------------------------------------------------------
            //  Get the indexes of the passed identifiers
            // -----------------------------------------------------------------
            // TODO: This COULD be passed if the drag/drop methods included the indexes. Minor thing, maybe not even better that this implementation.
            let profileIndexes = self.profileIdentifiers.indexes(ofItems: withIdentifiers) ?? IndexSet()

            // -----------------------------------------------------------------
            //  Remove the passed identifiers
            // -----------------------------------------------------------------
            self.profileIdentifiers = Array(Set(self.profileIdentifiers).subtracting(withIdentifiers))

            // -----------------------------------------------------------------
            //  Save the new group contents to disk
            // -----------------------------------------------------------------
            do {
                try self.writeToDisk(title: self.title)
            } catch {
                Log.shared.error(message: "Failed to write group to disk with error: \(error)", category: String(describing: self))
            }

            // -----------------------------------------------------------------
            //  Post notification that a grop removed profiles
            // -----------------------------------------------------------------
            NotificationCenter.default.post(name: .didRemoveProfilesFromGroup, object: self, userInfo: [NotificationKey.identifiers: withIdentifiers,
                                                                                                        NotificationKey.indexSet: profileIndexes])
        }
    }

    func removeProfiles(atIndexes: IndexSet, withIdentifiers: [UUID]) {

        // ---------------------------------------------------------------------
        //  Check that the group contains atleast one of the passed identifiers
        // ---------------------------------------------------------------------
        if !Set(self.profileIdentifiers).isDisjoint(with: withIdentifiers) {

            // -----------------------------------------------------------------
            //  If no indexes or wrong indexes are passed, calculate them here.
            //  This is for when closing an editor of an unsaved profile. That action will call a remove of the profile, without an index.
            // -----------------------------------------------------------------
            let indexes: IndexSet
            if atIndexes.count != withIdentifiers.count {
                indexes = self.profileIdentifiers.indexes(ofItems: withIdentifiers) ?? atIndexes
            } else {
                indexes = atIndexes
            }

            // -----------------------------------------------------------------
            //  Remove the passed identifiers
            // -----------------------------------------------------------------
            self.profileIdentifiers = Array(Set(self.profileIdentifiers).subtracting(withIdentifiers))

            // -----------------------------------------------------------------
            //  Save the new group contents to disk
            // -----------------------------------------------------------------
            do {
                try self.writeToDisk(title: self.title)
            } catch {
                Log.shared.error(message: "Failed to write group to disk with error: \(error)", category: String(describing: self))
            }

            // -----------------------------------------------------------------
            //  Post notification that a grop removed profiles
            // -----------------------------------------------------------------
            NotificationCenter.default.post(name: .didRemoveProfilesFromGroup, object: self, userInfo: [NotificationKey.identifiers: withIdentifiers, NotificationKey.indexSet: indexes])
        }
    }

    func removeFromDisk() throws {

        // ---------------------------------------------------------------------
        //  Get path to remove
        // ---------------------------------------------------------------------
        // TODO: Proper Error
        guard let url = try self.url() else { throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil) }

        // ---------------------------------------------------------------------
        //  Try to remove item at url
        // ---------------------------------------------------------------------
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: -
    // MARK: NSTextFieldDelegate Functions

    func controlTextDidBeginEditing(_ notification: Notification) {
        self.isEditing = true
    }

    func controlTextDidEndEditing(_ notification: Notification) {

        // ---------------------------------------------------------------------
        //  Get current text in the text field
        // ---------------------------------------------------------------------
        if
            let userInfo = notification.userInfo,
            let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
            let string = fieldEditor.textStorage?.string,
            !string.isEmpty {
            do {
                try self.writeToDisk(title: string)
                self.title = string
            } catch {
                Log.shared.error(message: "Failed to write group to disk with error: \(error)", category: String(describing: self))
            }
        }
        self.isEditing = false
    }
}
