//
//  ValueInfo.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import Foundation

struct ValueInfo {
    var title: String?

    var topLabel: String?
    var topContent: String?
    var topError: Bool = false

    var centerLabel: String?
    var centerContent: String?
    var centerError: Bool = false

    var bottomLabel: String?
    var bottomContent: String?
    var bottomError: Bool = false

    var message: String?

    var icon: NSImage?
    var iconPath: String?
}
