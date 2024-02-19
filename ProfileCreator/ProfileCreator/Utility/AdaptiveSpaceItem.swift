//
//  AdaptiveSpaceItem.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

public class AdaptiveSpaceItem: NSToolbarItem {

    // MARK: -
    // MARK: NSToolbarItem Variables

    override public var label: String {
        get { "" }
        set { }
    }

    override public var paletteLabel: String {
        get { "Adaptive Space" }
        set { }
    }

    // MARK: -
    // MARK: Initialization

    convenience init() {
        self.init(itemIdentifier: .adaptiveSpace)
    }

    override init(itemIdentifier: NSToolbarItem.Identifier) {
        super.init(itemIdentifier: itemIdentifier)
        self.view = AdaptiveSpaceItemView(spaceItem: self)
    }
}

class AdaptiveSpaceItemView: NSView {

    // MARK: -
    // MARK: Variables

    let adaptiveSpaceItem: AdaptiveSpaceItem

    // MARK: -
    // MARK: Initialization

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(spaceItem: AdaptiveSpaceItem) {
        self.adaptiveSpaceItem = spaceItem
        super.init(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
    }

    // MARK: -
    // MARK: De-Initialization

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: -
    // MARK: NSView Methods

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize), name: NSWindow.didResizeNotification, object: self.window)
    }

    // MARK: -
    // MARK: Notification Observer Methods

    @objc func windowDidResize() {
        // Nothing to do
    }

}
