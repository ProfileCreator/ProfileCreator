//
//  MainWindowAllProfiles.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowAllProfiles: NSObject, OutlineViewParentItem {

    // MARK: -
    // MARK: Variables

    let isEditable = false
    let identifier = UUID()
    let group: SidebarGroup = .allProfiles
    let title = SidebarGroupTitle.allProfiles
    var children = [OutlineViewChildItem]()
    var cellView: OutlineViewParentCellView?

    // MARK: -
    // MARK: Initialization

    init(outlineViewController: MainWindowOutlineViewController) {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup the cell view for this outline view item
        // ---------------------------------------------------------------------
        self.cellView = OutlineViewParentCellView(parent: self)

        // ---------------------------------------------------------------------
        //  Setup the single outline view child group for this parent
        // ---------------------------------------------------------------------
        let group = MainWindowAllProfilesGroup(title: self.title, identifier: nil, parent: self, outlineViewController: outlineViewController)

        // ---------------------------------------------------------------------
        //  Add the group to this parent
        // ---------------------------------------------------------------------
        self.children.append(group)
    }

    func loadSavedGroups() {}
}

class MainWindowAllProfilesGroup: NSObject, OutlineViewChildItem {

    // MARK: -
    // MARK: Variables

    let group: SidebarGroup = .allProfiles
    var isEditable = false
    var isEditing = false
    var icon: NSImage?
    var identifier: UUID
    var title: String
    var children = [OutlineViewChildItem]()
    var profileIdentifiers = [UUID]()
    var cellView: OutlineViewChildCellView?
    unowned var outlineViewController: MainWindowOutlineViewController

    // MARK: -
    // MARK: Initialization

    init(title: String, identifier: UUID?, parent: OutlineViewParentItem, outlineViewController: MainWindowOutlineViewController) {

        self.title = title
        self.identifier = identifier ?? UUID()
        self.outlineViewController = outlineViewController

        super.init()

        // ---------------------------------------------------------------------
        //  Setup the cell view for this outline view item
        // ---------------------------------------------------------------------
        self.cellView = OutlineViewChildCellView(child: self)

        // ---------------------------------------------------------------------
        //  Add all saved profiles to this group
        // ---------------------------------------------------------------------
        if let profileIdentifiers = ProfileController.sharedInstance.profileIdentifiers() {
            self.addProfiles(withIdentifiers: profileIdentifiers)
        }

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        NotificationCenter.default.addObserver(self, selector: #selector(didRemoveProfiles(_:)), name: .didRemoveProfiles, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .didRemoveProfiles, object: nil)
    }

    // MARK: -
    // MARK: Notification Functions

    @objc func didRemoveProfiles(_ notification: NSNotification?) {
        if let userInfo = notification?.userInfo,
            let identifiers = userInfo[NotificationKey.identifiers] as? [UUID] {

            // -----------------------------------------------------------------
            //  If no indexes or wrong indexes are passed, calculate them here.
            //  This is for when closing an editor of an unsaved profile. That action will call a remove of the profile, without an index.
            // -----------------------------------------------------------------
            var indexes = userInfo[NotificationKey.indexSet] as? IndexSet
            if indexes == nil || indexes!.count != identifiers.count {
                indexes = self.profileIdentifiers.indexes(ofItems: identifiers)
            }

            // -----------------------------------------------------------------
            //  Remove the passed identifiers
            // -----------------------------------------------------------------
            self.profileIdentifiers = Array(Set(self.profileIdentifiers).subtracting(identifiers))

            // -----------------------------------------------------------------
            //  Post notification that a grop removed profiles
            // -----------------------------------------------------------------
            let nonnullIndexes = indexes ?? IndexSet()
            NotificationCenter.default.post(name: .didRemoveProfilesFromGroup, object: self, userInfo: [NotificationKey.identifiers: identifiers, NotificationKey.indexSet: nonnullIndexes])

            // -----------------------------------------------------------------
            //  If profileIdentifiers are empyty, post notification that no profiles are configured
            // -----------------------------------------------------------------
            if self.profileIdentifiers.isEmpty {
                NotificationCenter.default.post(name: .noProfileConfigured, object: self)
            }
        }
    }

    // MARK: -
    // MARK: OutlineViewChildItem Functions

    func addProfiles(withIdentifiers identifiers: [UUID]) {
        self.profileIdentifiers = Array(Set(self.profileIdentifiers + identifiers))
    }

    func removeProfiles(withIdentifiers: [UUID]) {
        fatalError("All Profiles should never call removeProfiles(withIdentifiers:)")
    }

    func removeProfiles(atIndexes: IndexSet, withIdentifiers: [UUID]) {
        ProfileController.sharedInstance.removeProfiles(atIndexes: atIndexes, withIdentifiers: withIdentifiers)
    }

    func removeFromDisk() throws {
        fatalError("All Profiles should never call removeFromDisk()")
    }

    func writeToDisk(title: String) throws {
        fatalError("All Profiles should never call writeToDisk(title:)")
    }

    // MARK: -
    // MARK: MainWindowOutlineViewDelegate Functions
    // TODO: Implement
}
