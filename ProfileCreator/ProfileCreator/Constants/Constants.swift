//
//  Constants.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

let kPreferencesWindowWidth: CGFloat = 550.0
let kPreferencesIndent: CGFloat = 40.0

let kEditorPreferencesWindowWidth: CGFloat = 300.0
let kEditorPreferencesIndent: CGFloat = 22.0

let kExportPreferencesViewWidth: CGFloat = 600.0
let kExportPreferencesIndent: CGFloat = 22.0

let kEditorTableViewColumnPaddingWidth: CGFloat = 24.0
let kEditorTableViewColumnPayloadWidth: CGFloat = 500.0

let kUTTypeMobileconfig: String = "com.apple.mobileconfig"
let kUTTypeProfileConfiguration: String = "com.willyu.ProfileCreator.profileconfiguration"

let kMainWindowDragDropUTIs: [NSPasteboard.PasteboardType] = [.profile, .backwardsCompatibleFileURL]
let kMainWindowDragDropFilteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: [kUTTypeMobileconfig, NSPasteboard.PasteboardType.profile]]

let kSaveFormatVersion: Int = 1
let kSaveFormatVersionMin: Int = 1

let kPayloadSubkeysIgnored = [PayloadKey.payloadEnabled]
