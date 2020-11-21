//
//  ProfileEditorEditKeyWindow.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2019 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorEditKeyWindow: NSWindow {

    override var canBecomeKey: Bool { true }

    init(contentView: ProfileEditorEditKeyView) {
        super.init(contentRect: NSRect.zero, styleMask: .docModalWindow, backing: .buffered, defer: false)
        self.contentView = contentView
    }
}
