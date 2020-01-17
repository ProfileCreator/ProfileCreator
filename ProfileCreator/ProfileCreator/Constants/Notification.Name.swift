//
//  Notification.Name.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

extension Notification.Name {
    static let addGroup = Notification.Name("addGroup")
    static let newProfile = Notification.Name("newProfile")
    static let didAddGroup = Notification.Name("didAddGroup")
    static let didAddProfile = Notification.Name("didAddProfile")
    static let didChangeProfileSelection = Notification.Name("didChangeProfileSelection")
    static let didChangePayloadSelection = Notification.Name("didChangePayloadSelection")
    static let changePayloadSelected = Notification.Name("changePayloadSelected")
    static let didChangePayloadLibrary = Notification.Name("didChangePayloadLibrary")
    static let didChangePayloadLibraryGroup = Notification.Name("didChangePayloadLibraryGroup")
    static let didChangePayloadSelected = Notification.Name("didChangePayloadSelected")
    static let didRemoveProfiles = Notification.Name("didRemoveProfiles")
    static let didRemoveProfilesFromGroup = Notification.Name("didRemoveProfilesFromGroup")
    static let didSaveProfile = Notification.Name("didSaveProfile")
    static let emptyNotification = Notification.Name("emptyNotification")
    static let exportProfile = Notification.Name("exportProfile")
    static let exportPlist = Notification.Name("exportPlist")
    static let noProfileConfigured = Notification.Name("noProfileConfigured")
    static let payloadUpdatesAvailable = Notification.Name("payloadUpdatesAvailable")
    static let payloadUpdatesDownloaded = Notification.Name("payloadUpdatesDownloaded")
}
