//
//  NSPasteboard.PasteboardType.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

extension NSPasteboard.PasteboardType {
    static let profile = NSPasteboard.PasteboardType(rawValue: "com.willyu.ProfileCreator.profile")
    static let payload = NSPasteboard.PasteboardType(rawValue: "com.willyu.ProfileCreator.payload")
}
