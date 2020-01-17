//
//  Enums.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

// MARK: -
// MARK: EditorViewTag
// MARK: -

enum EditorViewTag: Int {
    case profileCreator
    case source
    case outlineView
}

// MARK: -
// MARK: ApplicationDirectory
// MARK: -

enum ApplicationDirectory {
    case applicationSupport
    case profiles
    case groups
    case groupLibrary
    case groupSmartGroups
    case jamf
}

// MARK: -
// MARK: SidebarGroup
// MARK: -

enum SidebarGroup {
    case allProfiles
    case library
    case jamf
}

// MARK: -
// MARK: TableViewTag
// MARK: -

enum TableViewTag: Int {
    case profilePayloads
    case libraryPayloads
}
